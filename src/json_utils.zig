/// JSON serialization and deserialization utilities for the Exa API.
const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");

const SearchParams = types.SearchParams;
const FindSimilarParams = types.FindSimilarParams;
const GetContentsParams = types.GetContentsParams;
const ContentsOptions = types.ContentsOptions;
const TextContentsOptions = types.TextContentsOptions;
const SummaryContentsOptions = types.SummaryContentsOptions;
const HighlightsContentsOptions = types.HighlightsContentsOptions;
const ContextContentsOptions = types.ContextContentsOptions;
const ExtrasOptions = types.ExtrasOptions;
const SearchResponse = types.SearchResponse;
const Result = types.Result;
const AnswerResponse = types.AnswerResponse;
const AnswerResult = types.AnswerResult;
const StreamChunk = types.StreamChunk;
const CostDollars = types.CostDollars;
const CostDollarsSearch = types.CostDollarsSearch;
const CostDollarsContents = types.CostDollarsContents;
const DeepSearchOutput = types.DeepSearchOutput;
const DeepSearchOutputGrounding = types.DeepSearchOutputGrounding;
const DeepSearchOutputGroundingCitation = types.DeepSearchOutputGroundingCitation;
const ContentStatus = types.ContentStatus;
const Entity = types.Entity;
const CompanyEntity = types.CompanyEntity;
const PersonEntity = types.PersonEntity;

// ---------------------------------------------------------------------------
// Internal writer helpers
// ---------------------------------------------------------------------------

fn writeStringField(writer: anytype, key: []const u8, value: []const u8, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writer.print("\"{s}\":", .{key});
    try writeJsonString(writer, value);
}

fn writeBoolField(writer: anytype, key: []const u8, value: bool, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writer.print("\"{s}\":{s}", .{ key, if (value) "true" else "false" });
}

fn writeIntField(writer: anytype, key: []const u8, value: i64, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writer.print("\"{s}\":{d}", .{ key, value });
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

fn writeStringArray(writer: anytype, key: []const u8, arr: []const []const u8, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writer.print("\"{s}\":[", .{key});
    for (arr, 0..) |item, i| {
        if (i > 0) try writer.writeByte(',');
        try writeJsonString(writer, item);
    }
    try writer.writeByte(']');
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

// ---------------------------------------------------------------------------
// Contents serialization helpers
// ---------------------------------------------------------------------------

fn writeTextContentsOptions(writer: anytype, opts: TextContentsOptions) !void {
    try writer.writeByte('{');
    var first = true;
    if (opts.max_characters) |v| {
        try writeIntField(writer, "maxCharacters", v, &first);
    }
    if (opts.include_html_tags) |v| {
        try writeBoolField(writer, "includeHtmlTags", v, &first);
    }
    if (opts.verbosity) |v| {
        try writeStringField(writer, "verbosity", v.toString(), &first);
    }
    if (opts.include_sections) |secs| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"includeSections\":[");
        for (secs, 0..) |sec, i| {
            if (i > 0) try writer.writeByte(',');
            try writeJsonString(writer, sec.toString());
        }
        try writer.writeByte(']');
    }
    if (opts.exclude_sections) |secs| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"excludeSections\":[");
        for (secs, 0..) |sec, i| {
            if (i > 0) try writer.writeByte(',');
            try writeJsonString(writer, sec.toString());
        }
        try writer.writeByte(']');
    }
    try writer.writeByte('}');
}

fn writeSummaryContentsOptions(writer: anytype, opts: SummaryContentsOptions) !void {
    try writer.writeByte('{');
    var first = true;
    if (opts.query) |v| try writeStringField(writer, "query", v, &first);
    if (opts.schema) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"$schema\":");
        try writeJsonValue(writer, v);
    }
    try writer.writeByte('}');
}

fn writeHighlightsContentsOptions(writer: anytype, opts: HighlightsContentsOptions) !void {
    try writer.writeByte('{');
    var first = true;
    if (opts.query) |v| try writeStringField(writer, "query", v, &first);
    if (opts.max_characters) |v| try writeIntField(writer, "maxCharacters", v, &first);
    if (opts.num_sentences) |v| try writeIntField(writer, "numSentences", v, &first);
    if (opts.highlights_per_url) |v| try writeIntField(writer, "highlightsPerUrl", v, &first);
    try writer.writeByte('}');
}

fn writeContextContentsOptions(writer: anytype, opts: ContextContentsOptions) !void {
    try writer.writeByte('{');
    var first = true;
    if (opts.max_characters) |v| try writeIntField(writer, "maxCharacters", v, &first);
    try writer.writeByte('}');
}

fn writeExtrasOptions(writer: anytype, opts: ExtrasOptions) !void {
    try writer.writeByte('{');
    var first = true;
    if (opts.links) |v| try writeIntField(writer, "links", v, &first);
    if (opts.image_links) |v| try writeIntField(writer, "imageLinks", v, &first);
    try writer.writeByte('}');
}

fn writeContentsOptions(writer: anytype, opts: ContentsOptions) !void {
    try writer.writeByte('{');
    var first = true;

    if (opts.text) |t| {
        if (!first) try writer.writeByte(',');
        first = false;
        switch (t) {
            .enabled => |b| {
                try writer.print("\"text\":{s}", .{if (b) "true" else "false"});
            },
            .options => |o| {
                try writer.writeAll("\"text\":");
                try writeTextContentsOptions(writer, o);
            },
        }
    }
    if (opts.highlights) |h| {
        if (!first) try writer.writeByte(',');
        first = false;
        switch (h) {
            .enabled => |b| {
                try writer.print("\"highlights\":{s}", .{if (b) "true" else "false"});
            },
            .options => |o| {
                try writer.writeAll("\"highlights\":");
                try writeHighlightsContentsOptions(writer, o);
            },
        }
    }
    if (opts.summary) |s| {
        if (!first) try writer.writeByte(',');
        first = false;
        switch (s) {
            .enabled => |b| {
                try writer.print("\"summary\":{s}", .{if (b) "true" else "false"});
            },
            .options => |o| {
                try writer.writeAll("\"summary\":");
                try writeSummaryContentsOptions(writer, o);
            },
        }
    }
    if (opts.context) |c| {
        if (!first) try writer.writeByte(',');
        first = false;
        switch (c) {
            .enabled => |b| {
                try writer.print("\"context\":{s}", .{if (b) "true" else "false"});
            },
            .options => |o| {
                try writer.writeAll("\"context\":");
                try writeContextContentsOptions(writer, o);
            },
        }
    }
    if (opts.livecrawl) |v| try writeStringField(writer, "livecrawl", v.toString(), &first);
    if (opts.livecrawl_timeout) |v| try writeIntField(writer, "livecrawlTimeout", v, &first);
    if (opts.max_age_hours) |v| try writeIntField(writer, "maxAgeHours", v, &first);
    if (opts.subpages) |v| try writeIntField(writer, "subpages", v, &first);
    if (opts.subpage_target) |st| {
        if (!first) try writer.writeByte(',');
        first = false;
        switch (st) {
            .single => |s| {
                try writer.writeAll("\"subpageTarget\":");
                try writeJsonString(writer, s);
            },
            .multiple => |arr| {
                try writer.writeAll("\"subpageTarget\":[");
                for (arr, 0..) |s, i| {
                    if (i > 0) try writer.writeByte(',');
                    try writeJsonString(writer, s);
                }
                try writer.writeByte(']');
            },
        }
    }
    if (opts.extras) |e| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"extras\":");
        try writeExtrasOptions(writer, e);
    }
    try writer.writeByte('}');
}

// ---------------------------------------------------------------------------
// Public Serializers
// ---------------------------------------------------------------------------

/// Serializes SearchParams to JSON bytes. Returns owned slice.
pub fn serializeSearchParams(allocator: std.mem.Allocator, params: SearchParams) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const writer = buf.writer();

    try writer.writeByte('{');
    var first = true;

    try writeStringField(writer, "query", params.query, &first);

    if (params.contents) |c| {
        switch (c) {
            .disabled => {}, // omit contents key entirely
            .options => |opts| {
                if (!first) try writer.writeByte(',');
                first = false;
                try writer.writeAll("\"contents\":");
                try writeContentsOptions(writer, opts);
            },
        }
    }

    if (params.num_results) |v| try writeIntField(writer, "numResults", v, &first);
    if (params.include_domains) |v| try writeStringArray(writer, "includeDomains", v, &first);
    if (params.exclude_domains) |v| try writeStringArray(writer, "excludeDomains", v, &first);
    if (params.start_crawl_date) |v| try writeStringField(writer, "startCrawlDate", v, &first);
    if (params.end_crawl_date) |v| try writeStringField(writer, "endCrawlDate", v, &first);
    if (params.start_published_date) |v| try writeStringField(writer, "startPublishedDate", v, &first);
    if (params.end_published_date) |v| try writeStringField(writer, "endPublishedDate", v, &first);
    if (params.include_text) |v| try writeStringArray(writer, "includeText", v, &first);
    if (params.exclude_text) |v| try writeStringArray(writer, "excludeText", v, &first);
    if (params.search_type) |v| try writeStringField(writer, "type", v.toString(), &first);
    if (params.category) |v| try writeStringField(writer, "category", v.toString(), &first);
    if (params.flags) |v| try writeStringArray(writer, "flags", v, &first);
    if (params.moderation) |v| try writeBoolField(writer, "moderation", v, &first);
    if (params.user_location) |v| try writeStringField(writer, "userLocation", v, &first);
    if (params.additional_queries) |v| try writeStringArray(writer, "additionalQueries", v, &first);
    if (params.system_prompt) |v| try writeStringField(writer, "systemPrompt", v, &first);
    if (params.output_schema) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"outputSchema\":");
        try writeJsonValue(writer, v);
    }

    try writer.writeByte('}');
    return buf.toOwnedSlice();
}

/// Serializes FindSimilarParams to JSON bytes. Returns owned slice.
pub fn serializeFindSimilarParams(allocator: std.mem.Allocator, params: FindSimilarParams) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const writer = buf.writer();

    try writer.writeByte('{');
    var first = true;

    try writeStringField(writer, "url", params.url, &first);

    if (params.contents) |c| {
        switch (c) {
            .disabled => {},
            .options => |opts| {
                if (!first) try writer.writeByte(',');
                first = false;
                try writer.writeAll("\"contents\":");
                try writeContentsOptions(writer, opts);
            },
        }
    }

    if (params.num_results) |v| try writeIntField(writer, "numResults", v, &first);
    if (params.include_domains) |v| try writeStringArray(writer, "includeDomains", v, &first);
    if (params.exclude_domains) |v| try writeStringArray(writer, "excludeDomains", v, &first);
    if (params.start_crawl_date) |v| try writeStringField(writer, "startCrawlDate", v, &first);
    if (params.end_crawl_date) |v| try writeStringField(writer, "endCrawlDate", v, &first);
    if (params.start_published_date) |v| try writeStringField(writer, "startPublishedDate", v, &first);
    if (params.end_published_date) |v| try writeStringField(writer, "endPublishedDate", v, &first);
    if (params.include_text) |v| try writeStringArray(writer, "includeText", v, &first);
    if (params.exclude_text) |v| try writeStringArray(writer, "excludeText", v, &first);
    if (params.exclude_source_domain) |v| try writeBoolField(writer, "excludeSourceDomain", v, &first);
    if (params.category) |v| try writeStringField(writer, "category", v.toString(), &first);
    if (params.flags) |v| try writeStringArray(writer, "flags", v, &first);

    try writer.writeByte('}');
    return buf.toOwnedSlice();
}

fn writeTextUnion(writer: anytype, key: []const u8, t: anytype, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeJsonString(writer, key);
    try writer.writeByte(':');
    switch (t) {
        .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
        .options => |o| try writeTextContentsOptions(writer, o),
    }
}

fn writeSummaryUnion(writer: anytype, key: []const u8, s: anytype, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeJsonString(writer, key);
    try writer.writeByte(':');
    switch (s) {
        .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
        .options => |o| try writeSummaryContentsOptions(writer, o),
    }
}

fn writeHighlightsUnion(writer: anytype, key: []const u8, h: anytype, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeJsonString(writer, key);
    try writer.writeByte(':');
    switch (h) {
        .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
        .options => |o| try writeHighlightsContentsOptions(writer, o),
    }
}

fn writeContextUnion(writer: anytype, key: []const u8, c: anytype, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeJsonString(writer, key);
    try writer.writeByte(':');
    switch (c) {
        .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
        .options => |o| try writeContextContentsOptions(writer, o),
    }
}

/// Serializes GetContentsParams to JSON bytes. Returns owned slice.
pub fn serializeGetContentsParams(allocator: std.mem.Allocator, params: GetContentsParams) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const writer = buf.writer();

    try writer.writeByte('{');
    var first = true;

    // Write URLs array
    if (!first) try writer.writeByte(',');
    first = false;
    try writer.writeAll("\"urls\":[");
    for (params.urls, 0..) |u, i| {
        if (i > 0) try writer.writeByte(',');
        try writeJsonString(writer, u);
    }
    try writer.writeByte(']');

    if (params.text) |t| try writeTextUnion(writer, "text", t, &first);
    if (params.summary) |s| try writeSummaryUnion(writer, "summary", s, &first);
    if (params.highlights) |h| try writeHighlightsUnion(writer, "highlights", h, &first);
    if (params.context) |c| try writeContextUnion(writer, "context", c, &first);
    if (params.livecrawl) |v| try writeStringField(writer, "livecrawl", v.toString(), &first);
    if (params.livecrawl_timeout) |v| try writeIntField(writer, "livecrawlTimeout", v, &first);
    if (params.max_age_hours) |v| try writeIntField(writer, "maxAgeHours", v, &first);
    if (params.filter_empty_results) |v| try writeBoolField(writer, "filterEmptyResults", v, &first);
    if (params.subpages) |v| try writeIntField(writer, "subpages", v, &first);
    if (params.subpage_target) |st| {
        if (!first) try writer.writeByte(',');
        first = false;
        switch (st) {
            .single => |s| {
                try writer.writeAll("\"subpageTarget\":");
                try writeJsonString(writer, s);
            },
            .multiple => |arr| {
                try writer.writeAll("\"subpageTarget\":[");
                for (arr, 0..) |s, i| {
                    if (i > 0) try writer.writeByte(',');
                    try writeJsonString(writer, s);
                }
                try writer.writeByte(']');
            },
        }
    }
    if (params.extras) |e| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"extras\":");
        try writeExtrasOptions(writer, e);
    }
    if (params.flags) |v| try writeStringArray(writer, "flags", v, &first);

    try writer.writeByte('}');
    return buf.toOwnedSlice();
}

// ---------------------------------------------------------------------------
// Internal parse helpers
// ---------------------------------------------------------------------------

fn getString(obj: std.json.ObjectMap, key: []const u8) ?[]const u8 {
    const val = obj.get(key) orelse return null;
    return switch (val) {
        .string => |s| s,
        else => null,
    };
}

fn getInt(obj: std.json.ObjectMap, key: []const u8) ?i64 {
    const val = obj.get(key) orelse return null;
    return switch (val) {
        .integer => |n| n,
        .float => |f| @intFromFloat(f),
        else => null,
    };
}

fn getFloat(obj: std.json.ObjectMap, key: []const u8) ?f64 {
    const val = obj.get(key) orelse return null;
    return switch (val) {
        .float => |f| f,
        .integer => |n| @floatFromInt(n),
        .number_string => |s| std.fmt.parseFloat(f64, s) catch null,
        else => null,
    };
}

fn getBool(obj: std.json.ObjectMap, key: []const u8) ?bool {
    const val = obj.get(key) orelse return null;
    return switch (val) {
        .bool => |b| b,
        else => null,
    };
}

fn dupeStringOpt(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) !?[]u8 {
    const s = getString(obj, key) orelse return null;
    return try allocator.dupe(u8, s);
}

fn dupeStringReq(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) ![]u8 {
    const s = getString(obj, key) orelse return error.MissingField;
    return try allocator.dupe(u8, s);
}

fn parseCostDollars(obj: std.json.ObjectMap) ?CostDollars {
    const cd_val = obj.get("costDollars") orelse return null;
    const cd_obj = switch (cd_val) {
        .object => |o| o,
        else => return null,
    };
    const total = getFloat(cd_obj, "total") orelse 0.0;

    var search_cost: ?CostDollarsSearch = null;
    if (cd_obj.get("search")) |sv| {
        if (sv == .object) {
            search_cost = CostDollarsSearch{
                .neural = getFloat(sv.object, "neural"),
                .keyword = getFloat(sv.object, "keyword"),
            };
        }
    }

    var contents_cost: ?CostDollarsContents = null;
    if (cd_obj.get("contents")) |cv| {
        if (cv == .object) {
            contents_cost = CostDollarsContents{
                .text = getFloat(cv.object, "text"),
                .summary = getFloat(cv.object, "summary"),
            };
        }
    }

    return CostDollars{
        .total = total,
        .search = search_cost,
        .contents = contents_cost,
    };
}

fn parseDeepSearchOutput(allocator: std.mem.Allocator, val: std.json.Value) !?DeepSearchOutput {
    const obj = switch (val) {
        .object => |o| o,
        else => return null,
    };

    const content_val = obj.get("content") orelse return null;
    const content: @FieldType(DeepSearchOutput, "content") = switch (content_val) {
        .string => |s| .{ .text = try allocator.dupe(u8, s) },
        .object, .array => .{ .object = try utils.cloneValue(allocator, content_val) },
        else => return null,
    };
    errdefer switch (content) {
        .text => |t| allocator.free(t),
        .object => |v| utils.freeValue(allocator, v),
    };

    var grounding_list = std.ArrayList(DeepSearchOutputGrounding).init(allocator);
    errdefer {
        for (grounding_list.items) |g| {
            allocator.free(g.field);
            for (g.citations) |c| {
                allocator.free(c.url);
                allocator.free(c.title);
            }
            allocator.free(g.citations);
        }
        grounding_list.deinit();
    }

    if (obj.get("grounding")) |gv| {
        if (gv == .array) {
            for (gv.array.items) |gitem| {
                if (gitem != .object) continue;
                const go = gitem.object;
                const field = try allocator.dupe(u8, getString(go, "field") orelse "");
                errdefer allocator.free(field);

                const confidence_str = getString(go, "confidence") orelse "low";
                const confidence = types.GroundingConfidence.fromString(confidence_str) orelse .low;

                var cit_list = std.ArrayList(DeepSearchOutputGroundingCitation).init(allocator);
                errdefer {
                    for (cit_list.items) |c| {
                        allocator.free(c.url);
                        allocator.free(c.title);
                    }
                    cit_list.deinit();
                }

                if (go.get("citations")) |cv| {
                    if (cv == .array) {
                        for (cv.array.items) |cit| {
                            if (cit != .object) continue;
                            const co = cit.object;
                            const curl = try allocator.dupe(u8, getString(co, "url") orelse "");
                            errdefer allocator.free(curl);
                            const ctitle = try allocator.dupe(u8, getString(co, "title") orelse "");
                            errdefer allocator.free(ctitle);
                            try cit_list.append(.{ .url = curl, .title = ctitle });
                        }
                    }
                }

                try grounding_list.append(.{
                    .field = field,
                    .citations = try cit_list.toOwnedSlice(),
                    .confidence = confidence,
                });
            }
        }
    }

    return DeepSearchOutput{
        .content = content,
        .grounding = try grounding_list.toOwnedSlice(),
    };
}

fn parseResult(allocator: std.mem.Allocator, val: std.json.Value) !Result {
    const obj = switch (val) {
        .object => |o| o,
        else => return error.InvalidResultFormat,
    };

    const url = try dupeStringReq(allocator, obj, "url");
    errdefer allocator.free(url);
    const id = try dupeStringReq(allocator, obj, "id");
    errdefer allocator.free(id);

    const title = try dupeStringOpt(allocator, obj, "title");
    errdefer if (title) |v| allocator.free(v);
    const published_date = try dupeStringOpt(allocator, obj, "publishedDate");
    errdefer if (published_date) |v| allocator.free(v);
    const author = try dupeStringOpt(allocator, obj, "author");
    errdefer if (author) |v| allocator.free(v);
    const image = try dupeStringOpt(allocator, obj, "image");
    errdefer if (image) |v| allocator.free(v);
    const favicon = try dupeStringOpt(allocator, obj, "favicon");
    errdefer if (favicon) |v| allocator.free(v);
    const text = try dupeStringOpt(allocator, obj, "text");
    errdefer if (text) |v| allocator.free(v);
    const summary = try dupeStringOpt(allocator, obj, "summary");
    errdefer if (summary) |v| allocator.free(v);

    const score = getFloat(obj, "score");

    var subpages: ?[]Result = null;
    if (obj.get("subpages")) |spv| {
        if (spv == .array) {
            var sp_list = std.ArrayList(Result).init(allocator);
            errdefer {
                for (sp_list.items) |r| r.deinit(allocator);
                sp_list.deinit();
            }
            for (spv.array.items) |sp| {
                try sp_list.append(try parseResult(allocator, sp));
            }
            subpages = try sp_list.toOwnedSlice();
        }
    }

    var extras: ?std.json.Value = null;
    if (obj.get("extras")) |ev| {
        if (ev != .null) {
            extras = try utils.cloneValue(allocator, ev);
        }
    }

    var highlights: ?[][]u8 = null;
    if (obj.get("highlights")) |hlv| {
        if (hlv == .array) {
            var hl_list = std.ArrayList([]u8).init(allocator);
            errdefer {
                for (hl_list.items) |h| allocator.free(h);
                hl_list.deinit();
            }
            for (hlv.array.items) |hl| {
                if (hl == .string) {
                    try hl_list.append(try allocator.dupe(u8, hl.string));
                }
            }
            highlights = try hl_list.toOwnedSlice();
        }
    }

    var highlight_scores: ?[]f64 = null;
    if (obj.get("highlightScores")) |hsv| {
        if (hsv == .array) {
            var hs_list = std.ArrayList(f64).init(allocator);
            errdefer hs_list.deinit();
            for (hsv.array.items) |hs| {
                const f = switch (hs) {
                    .float => |f| f,
                    .integer => |n| @as(f64, @floatFromInt(n)),
                    else => continue,
                };
                try hs_list.append(f);
            }
            highlight_scores = try hs_list.toOwnedSlice();
        }
    }

    var entities: ?[]Entity = null;
    if (obj.get("entities")) |ev| {
        entities = try parseEntities(allocator, ev);
    }

    return Result{
        .url = url,
        .id = id,
        .title = title,
        .score = score,
        .published_date = published_date,
        .author = author,
        .image = image,
        .favicon = favicon,
        .subpages = subpages,
        .extras = extras,
        .entities = entities,
        .text = text,
        .summary = summary,
        .highlights = if (highlights) |h| @ptrCast(h) else null,
        .highlight_scores = highlight_scores,
    };
}

fn parseContentStatuses(allocator: std.mem.Allocator, val: std.json.Value) !?[]ContentStatus {
    if (val != .array) return null;
    var list = std.ArrayList(ContentStatus).init(allocator);
    errdefer {
        for (list.items) |s| {
            allocator.free(s.id);
            allocator.free(s.status);
            allocator.free(s.source);
        }
        list.deinit();
    }
    for (val.array.items) |item| {
        if (item != .object) continue;
        const o = item.object;
        const sid = try allocator.dupe(u8, getString(o, "id") orelse "");
        errdefer allocator.free(sid);
        const sstatus = try allocator.dupe(u8, getString(o, "status") orelse "");
        errdefer allocator.free(sstatus);
        const ssource = try allocator.dupe(u8, getString(o, "source") orelse "");
        errdefer allocator.free(ssource);
        try list.append(.{ .id = sid, .status = sstatus, .source = ssource });
    }
    return try list.toOwnedSlice();
}

fn parseSearchResponseInternal(allocator: std.mem.Allocator, root: std.json.ObjectMap) !SearchResponse(Result) {
    var results_list = std.ArrayList(Result).init(allocator);
    errdefer {
        for (results_list.items) |r| r.deinit(allocator);
        results_list.deinit();
    }

    if (root.get("results")) |rv| {
        if (rv == .array) {
            for (rv.array.items) |item| {
                try results_list.append(try parseResult(allocator, item));
            }
        }
    }

    const resolved_search_type = try dupeStringOpt(allocator, root, "resolvedSearchType");
    errdefer if (resolved_search_type) |v| allocator.free(v);
    const auto_date = try dupeStringOpt(allocator, root, "autoDate");
    errdefer if (auto_date) |v| allocator.free(v);
    const context = try dupeStringOpt(allocator, root, "context");
    errdefer if (context) |v| allocator.free(v);

    var output: ?DeepSearchOutput = null;
    if (root.get("output")) |ov| {
        output = try parseDeepSearchOutput(allocator, ov);
    }

    var statuses: ?[]ContentStatus = null;
    if (root.get("statuses")) |sv| {
        statuses = try parseContentStatuses(allocator, sv);
    }

    const cost_dollars = parseCostDollars(root);
    const search_time = getFloat(root, "searchTime");

    return SearchResponse(Result){
        .results = try results_list.toOwnedSlice(),
        .resolved_search_type = resolved_search_type,
        .auto_date = auto_date,
        .context = context,
        .output = output,
        .statuses = statuses,
        .cost_dollars = cost_dollars,
        .search_time = search_time,
        .allocator = allocator,
    };
}

/// Parses /search and /findSimilar responses.
pub fn parseSearchResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !SearchResponse(Result) {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();

    const root = switch (parsed.value) {
        .object => |o| o,
        else => return error.InvalidResponseFormat,
    };

    return parseSearchResponseInternal(allocator, root);
}

/// Parses /contents responses (same structure as search response).
pub fn parseContentsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !SearchResponse(Result) {
    return parseSearchResponse(allocator, json_bytes);
}

/// Parses /answer response.
pub fn parseAnswerResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !AnswerResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();

    const root = switch (parsed.value) {
        .object => |o| o,
        else => return error.InvalidResponseFormat,
    };

    const answer_val = root.get("answer") orelse return error.MissingField;
    const answer: @FieldType(AnswerResponse, "answer") = switch (answer_val) {
        .string => |s| .{ .text = try allocator.dupe(u8, s) },
        else => .{ .object = try utils.cloneValue(allocator, answer_val) },
    };
    errdefer switch (answer) {
        .text => |t| allocator.free(t),
        .object => |v| utils.freeValue(allocator, v),
    };

    var citations_list = std.ArrayList(AnswerResult).init(allocator);
    errdefer {
        for (citations_list.items) |c| c.deinit(allocator);
        citations_list.deinit();
    }
    if (root.get("citations")) |cv| {
        if (cv == .array) {
            for (cv.array.items) |cit| {
                if (cit != .object) continue;
                const co = cit.object;
                const ar = try parseAnswerResult(allocator, co);
                try citations_list.append(ar);
            }
        }
    }

    const cost_dollars = parseCostDollars(root);

    return AnswerResponse{
        .answer = answer,
        .citations = try citations_list.toOwnedSlice(),
        .cost_dollars = cost_dollars,
    };
}

fn parseAnswerResult(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !AnswerResult {
    const id = try dupeStringReq(allocator, obj, "id");
    errdefer allocator.free(id);
    const url = try dupeStringReq(allocator, obj, "url");
    errdefer allocator.free(url);
    const title = try dupeStringOpt(allocator, obj, "title");
    errdefer if (title) |v| allocator.free(v);
    const published_date = try dupeStringOpt(allocator, obj, "publishedDate");
    errdefer if (published_date) |v| allocator.free(v);
    const author = try dupeStringOpt(allocator, obj, "author");
    errdefer if (author) |v| allocator.free(v);
    const text = try dupeStringOpt(allocator, obj, "text");
    errdefer if (text) |v| allocator.free(v);

    return AnswerResult{
        .id = id,
        .url = url,
        .title = title,
        .published_date = published_date,
        .author = author,
        .text = text,
    };
}

/// Parses entity array from a JSON value.
pub fn parseEntities(allocator: std.mem.Allocator, entities_json: std.json.Value) !?[]Entity {
    const arr = switch (entities_json) {
        .array => |a| a,
        else => return null,
    };
    if (arr.items.len == 0) return null;

    var list = std.ArrayList(Entity).init(allocator);
    errdefer list.deinit();

    for (arr.items) |item| {
        if (item != .object) continue;
        const obj = item.object;
        const type_str = getString(obj, "type") orelse continue;
        const id = try dupeStringReq(allocator, obj, "id");
        errdefer allocator.free(id);
        const version = getInt(obj, "version") orelse 0;

        if (std.mem.eql(u8, type_str, "company")) {
            var props = types.EntityCompanyProperties{};
            if (obj.get("properties")) |pv| {
                if (pv == .object) {
                    const po = pv.object;
                    props.name = try dupeStringOpt(allocator, po, "name");
                    props.description = try dupeStringOpt(allocator, po, "description");
                    props.founded_year = getInt(po, "foundedYear");

                    if (po.get("workforce")) |wv| {
                        if (wv == .object) {
                            props.workforce = .{ .total = getInt(wv.object, "total") };
                        }
                    }
                    if (po.get("headquarters")) |hv| {
                        if (hv == .object) {
                            const ho = hv.object;
                            props.headquarters = .{
                                .address = try dupeStringOpt(allocator, ho, "address"),
                                .city = try dupeStringOpt(allocator, ho, "city"),
                                .postal_code = try dupeStringOpt(allocator, ho, "postalCode"),
                                .country = try dupeStringOpt(allocator, ho, "country"),
                            };
                        }
                    }
                    if (po.get("financials")) |fv| {
                        if (fv == .object) {
                            const fo = fv.object;
                            var fin = types.EntityCompanyPropertiesFinancials{
                                .revenue_annual = getInt(fo, "revenueAnnual"),
                                .funding_total = getInt(fo, "fundingTotal"),
                            };
                            if (fo.get("fundingLatestRound")) |frv| {
                                if (frv == .object) {
                                    const fro = frv.object;
                                    fin.funding_latest_round = .{
                                        .name = try dupeStringOpt(allocator, fro, "name"),
                                        .date = try dupeStringOpt(allocator, fro, "date"),
                                        .amount = getInt(fro, "amount"),
                                    };
                                }
                            }
                            props.financials = fin;
                        }
                    }
                    if (po.get("webTraffic")) |wtv| {
                        if (wtv == .object) {
                            props.web_traffic = .{ .visits_monthly = getInt(wtv.object, "visitsMonthly") };
                        }
                    }
                }
            }
            try list.append(.{ .company = .{ .id = id, .version = version, .properties = props } });
        } else if (std.mem.eql(u8, type_str, "person")) {
            var props = types.EntityPersonProperties{};
            if (obj.get("properties")) |pv| {
                if (pv == .object) {
                    const po = pv.object;
                    props.name = try dupeStringOpt(allocator, po, "name");
                    props.location = try dupeStringOpt(allocator, po, "location");

                    if (po.get("workHistory")) |whv| {
                        if (whv == .array) {
                            var wh_list = std.ArrayList(types.EntityPersonPropertiesWorkHistoryEntry).init(allocator);
                            errdefer wh_list.deinit();
                            for (whv.array.items) |whe| {
                                if (whe != .object) continue;
                                const who = whe.object;
                                var entry = types.EntityPersonPropertiesWorkHistoryEntry{
                                    .title = try dupeStringOpt(allocator, who, "title"),
                                    .location = try dupeStringOpt(allocator, who, "location"),
                                };
                                if (who.get("dates")) |dv| {
                                    if (dv == .object) {
                                        entry.dates = .{
                                            .from_date = try dupeStringOpt(allocator, dv.object, "from"),
                                            .to_date = try dupeStringOpt(allocator, dv.object, "to"),
                                        };
                                    }
                                }
                                if (who.get("company")) |cv| {
                                    if (cv == .object) {
                                        entry.company = .{
                                            .id = try dupeStringOpt(allocator, cv.object, "id"),
                                            .name = try dupeStringOpt(allocator, cv.object, "name"),
                                        };
                                    }
                                }
                                try wh_list.append(entry);
                            }
                            props.work_history = try wh_list.toOwnedSlice();
                        }
                    }
                }
            }
            try list.append(.{ .person = .{ .id = id, .version = version, .properties = props } });
        } else {
            allocator.free(id);
        }
    }

    return try list.toOwnedSlice();
}

/// Parses an SSE line into a StreamChunk. Returns null if no data.
pub fn parseSseChunk(allocator: std.mem.Allocator, line: []const u8) !?StreamChunk {
    const prefix = "data: ";
    if (!std.mem.startsWith(u8, line, prefix)) return null;
    const data = line[prefix.len..];
    if (data.len == 0) return null;
    if (std.mem.eql(u8, data, "[DONE]")) return null;

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, data, .{}) catch return null;
    defer parsed.deinit();

    const root = switch (parsed.value) {
        .object => |o| o,
        else => return null,
    };

    var content: ?[]u8 = null;
    errdefer if (content) |v| allocator.free(v);

    if (root.get("choices")) |choices_val| {
        if (choices_val == .array and choices_val.array.items.len > 0) {
            const choice = choices_val.array.items[0];
            if (choice == .object) {
                if (choice.object.get("delta")) |delta| {
                    if (delta == .object) {
                        if (delta.object.get("content")) |cv| {
                            if (cv == .string and cv.string.len > 0) {
                                content = try allocator.dupe(u8, cv.string);
                            }
                        }
                    }
                }
            }
        }
    }

    var citations: ?[]AnswerResult = null;
    if (root.get("citations")) |cv| {
        if (cv == .array and cv.array.items.len > 0) {
            var cit_list = std.ArrayList(AnswerResult).init(allocator);
            errdefer {
                for (cit_list.items) |c| c.deinit(allocator);
                cit_list.deinit();
            }
            for (cv.array.items) |cit| {
                if (cit != .object) continue;
                try cit_list.append(try parseAnswerResult(allocator, cit.object));
            }
            citations = try cit_list.toOwnedSlice();
        }
    }

    const chunk = StreamChunk{ .content = content, .citations = citations };
    if (!chunk.hasData()) {
        if (content) |v| allocator.free(v);
        if (citations) |cs| {
            for (cs) |c| c.deinit(allocator);
            allocator.free(cs);
        }
        return null;
    }
    return chunk;
}
