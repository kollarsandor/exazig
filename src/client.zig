/// Main Exa API client.
const std = @import("std");
const types = @import("types.zig");
const json_utils = @import("json_utils.zig");
const http_mod = @import("http.zig");
const utils = @import("utils.zig");
const websets_mod = @import("websets/root.zig");
const research_mod = @import("research/root.zig");
const monitors_mod = @import("monitors/root.zig");

const HttpClient = http_mod.HttpClient;
const StreamingResponse = http_mod.StreamingResponse;
const SearchParams = types.SearchParams;
const FindSimilarParams = types.FindSimilarParams;
const GetContentsParams = types.GetContentsParams;
const ContentsOptions = types.ContentsOptions;
const TextContentsOptions = types.TextContentsOptions;
const SearchResponse = types.SearchResponse;
const Result = types.Result;
const AnswerResponse = types.AnswerResponse;
const StreamChunk = types.StreamChunk;

/// Iterator over SSE stream chunks for search/answer streaming.
pub const StreamIterator = struct {
    allocator: std.mem.Allocator,
    response: StreamingResponse,

    /// Returns the next non-empty StreamChunk, or null at EOF.
    pub fn next(self: *StreamIterator) !?StreamChunk {
        while (true) {
            const line = try self.response.nextLine() orelse return null;
            defer self.allocator.free(line);

            const chunk = try json_utils.parseSseChunk(self.allocator, line) orelse continue;
            if (chunk.hasData()) return chunk;
            chunk.deinit(self.allocator);
        }
    }

    /// Closes the underlying streaming connection.
    pub fn close(self: *StreamIterator) void {
        self.response.close();
    }
};

/// The top-level Exa API client.
pub const Exa = struct {
    allocator: std.mem.Allocator,
    http: HttpClient,
    websets: websets_mod.WebsetsClient,
    research: research_mod.ResearchClient,
    monitors: monitors_mod.SearchMonitorsClient,

    /// Initializes the Exa client.
    /// - api_key: if null, reads EXA_API_KEY from the environment.
    /// - base_url: defaults to "https://api.exa.ai".
    /// - user_agent: defaults to "exazig/<version>".
    pub fn init(
        allocator: std.mem.Allocator,
        api_key: ?[]const u8,
        base_url: ?[]const u8,
        user_agent: ?[]const u8,
    ) !Exa {
        const effective_base = base_url orelse "https://api.exa.ai";
        const version = comptime utils.getPackageVersion();
        const default_ua = "exazig/" ++ version;
        const effective_ua = user_agent orelse default_ua;

        const effective_key: []const u8 = if (api_key) |k|
            k
        else blk: {
            const env_key = std.process.getEnvVarOwned(allocator, "EXA_API_KEY") catch |err| {
                if (err == error.EnvironmentVariableNotFound) return error.MissingApiKey;
                return err;
            };
            break :blk env_key;
        };
        const key_owned = if (api_key != null) try allocator.dupe(u8, effective_key) else effective_key;
        defer allocator.free(key_owned);

        var http_client = try HttpClient.init(allocator, effective_base, key_owned, effective_ua);
        errdefer http_client.deinit();

        const ws_client = websets_mod.WebsetsClient.init(http_client);
        const res_client = research_mod.ResearchClient.init(http_client);
        const mon_client = monitors_mod.SearchMonitorsClient.init(http_client);

        return Exa{
            .allocator = allocator,
            .http = http_client,
            .websets = ws_client,
            .research = res_client,
            .monitors = mon_client,
        };
    }

    pub fn deinit(self: *Exa) void {
        self.http.deinit();
    }

    /// Searches Exa. Defaults to text contents with 10,000 max characters if contents not set.
    pub fn search(self: Exa, allocator: std.mem.Allocator, params: SearchParams) !SearchResponse(Result) {
        var effective_params = params;
        if (effective_params.contents == null) {
            effective_params.contents = .{ .options = ContentsOptions{
                .text = .{ .options = TextContentsOptions{ .max_characters = 10_000 } },
            } };
        }

        const body = try json_utils.serializeSearchParams(allocator, effective_params);
        defer allocator.free(body);

        const response_bytes = try self.http.post("/search", body);
        defer allocator.free(response_bytes);

        return json_utils.parseSearchResponse(allocator, response_bytes);
    }

    /// Streams search results via SSE. Returns a StreamIterator; caller must call close().
    pub fn streamSearch(self: Exa, allocator: std.mem.Allocator, params: SearchParams) !StreamIterator {
        var effective_params = params;
        if (effective_params.contents == null) {
            effective_params.contents = .{ .options = ContentsOptions{
                .text = .{ .options = TextContentsOptions{ .max_characters = 10_000 } },
            } };
        }

        const base_body = try json_utils.serializeSearchParams(allocator, effective_params);
        defer allocator.free(base_body);

        // Inject "stream": true into the JSON object
        const stream_body = try injectStreamTrue(allocator, base_body);
        defer allocator.free(stream_body);

        const response = try self.http.postStream("/search", stream_body);
        return StreamIterator{ .allocator = allocator, .response = response };
    }

    /// Retrieves contents for the given URLs. Defaults to text with 10,000 max characters.
    pub fn getContents(self: Exa, allocator: std.mem.Allocator, params: GetContentsParams) !SearchResponse(Result) {
        var effective_params = params;
        if (effective_params.text == null and
            effective_params.summary == null and
            effective_params.highlights == null and
            effective_params.context == null)
        {
            effective_params.text = .{ .options = TextContentsOptions{ .max_characters = 10_000 } };
        }

        const body = try json_utils.serializeGetContentsParams(allocator, effective_params);
        defer allocator.free(body);

        const response_bytes = try self.http.post("/contents", body);
        defer allocator.free(response_bytes);

        return json_utils.parseContentsResponse(allocator, response_bytes);
    }

    /// Finds similar pages to the given URL.
    pub fn findSimilar(self: Exa, allocator: std.mem.Allocator, params: FindSimilarParams) !SearchResponse(Result) {
        var effective_params = params;
        if (effective_params.contents == null) {
            effective_params.contents = .{ .options = ContentsOptions{
                .text = .{ .options = TextContentsOptions{ .max_characters = 10_000 } },
            } };
        }

        const body = try json_utils.serializeFindSimilarParams(allocator, effective_params);
        defer allocator.free(body);

        const response_bytes = try self.http.post("/findSimilar", body);
        defer allocator.free(response_bytes);

        return json_utils.parseSearchResponse(allocator, response_bytes);
    }

    /// Gets an AI-generated answer to the query.
    pub fn answer(
        self: Exa,
        allocator: std.mem.Allocator,
        query: []const u8,
        text: ?bool,
        output_schema: ?std.json.Value,
    ) !types.AnswerResponse {
        const body = try buildAnswerBody(allocator, query, text, output_schema, false);
        defer allocator.free(body);

        const response_bytes = try self.http.post("/answer", body);
        defer allocator.free(response_bytes);

        return json_utils.parseAnswerResponse(allocator, response_bytes);
    }

    /// Streams an AI-generated answer via SSE. Caller must call close() on the iterator.
    pub fn streamAnswer(
        self: Exa,
        allocator: std.mem.Allocator,
        query: []const u8,
        text: ?bool,
        output_schema: ?std.json.Value,
    ) !StreamIterator {
        const body = try buildAnswerBody(allocator, query, text, output_schema, true);
        defer allocator.free(body);

        const response = try self.http.postStream("/answer", body);
        return StreamIterator{ .allocator = allocator, .response = response };
    }
};

fn buildAnswerBody(
    allocator: std.mem.Allocator,
    query: []const u8,
    text: ?bool,
    output_schema: ?std.json.Value,
    stream: bool,
) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const writer = buf.writer();

    try writer.writeByte('{');
    try writer.writeAll("\"query\":");
    try writeJsonString(writer, query);

    if (text) |t| {
        try writer.print(",\"text\":{s}", .{if (t) "true" else "false"});
    }
    if (output_schema) |schema| {
        try writer.writeAll(",\"outputSchema\":");
        try writeJsonValue(writer, schema);
    }
    if (stream) {
        try writer.writeAll(",\"stream\":true");
    }
    try writer.writeByte('}');
    return buf.toOwnedSlice();
}

fn injectStreamTrue(allocator: std.mem.Allocator, json_body: []const u8) ![]u8 {
    // The body is always a JSON object ending with '}'.
    // We inject ,"stream":true before the final '}'.
    if (json_body.len == 0 or json_body[json_body.len - 1] != '}') {
        return allocator.dupe(u8, json_body);
    }
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    try buf.appendSlice(json_body[0 .. json_body.len - 1]);
    if (json_body.len > 2) {
        try buf.appendSlice(",\"stream\":true}");
    } else {
        try buf.appendSlice("\"stream\":true}");
    }
    return buf.toOwnedSlice();
}

fn writeJsonString(writer: anytype, s: []const u8) !void {
    try writer.writeByte('"');
    for (s) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
    try writer.writeByte('"');
}

fn writeJsonValue(writer: anytype, val: std.json.Value) !void {
    switch (val) {
        .null => try writer.writeAll("null"),
        .bool => |b| try writer.writeAll(if (b) "true" else "false"),
        .integer => |n| try writer.print("{d}", .{n}),
        .float => |f| try writer.print("{d}", .{f}),
        .number_string => |s| try writer.writeAll(s),
        .string => |s| try writeJsonString(writer, s),
        .array => |arr| {
            try writer.writeByte('[');
            for (arr.items, 0..) |item, i| {
                if (i > 0) try writer.writeByte(',');
                try writeJsonValue(writer, item);
            }
            try writer.writeByte(']');
        },
        .object => |obj| {
            try writer.writeByte('{');
            var it = obj.iterator();
            var first = true;
            while (it.next()) |entry| {
                if (!first) try writer.writeByte(',');
                first = false;
                try writeJsonString(writer, entry.key_ptr.*);
                try writer.writeByte(':');
                try writeJsonValue(writer, entry.value_ptr.*);
            }
            try writer.writeByte('}');
        },
    }
}
