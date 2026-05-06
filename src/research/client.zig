/// Research subsystem client.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const StreamingResponse = http_mod.StreamingResponse;
const QueryParam = http_mod.QueryParam;

/// Iterator over SSE research events.
pub const ResearchStreamIterator = struct {
    allocator: std.mem.Allocator,
    response: StreamingResponse,

    pub fn next(self: *ResearchStreamIterator) !?types.ResearchEvent {
        while (true) {
            const line = try self.response.nextLine() orelse return null;
            defer self.allocator.free(line);
            if (line.len == 0) continue;
            const event = try json.parseSseResearchEvent(self.allocator, line) orelse continue;
            return event;
        }
    }

    pub fn close(self: *ResearchStreamIterator) void {
        self.response.close();
    }
};

pub const ResearchClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/research/v1",

    pub fn init(http: HttpClient) ResearchClient {
        return ResearchClient{ .http = http };
    }

    /// Creates a new research task.
    pub fn create(self: ResearchClient, allocator: std.mem.Allocator, req: types.ResearchCreateRequestDto) !types.ResearchDto {
        const request_body = try json.serializeCreateRequest(allocator, req);
        defer allocator.free(request_body);
        const response_body = try self.http.post(self.base_path, request_body);
        defer allocator.free(response_body);
        return json.parseResearchDto(allocator, response_body);
    }

    const GetResult = union(enum) {
        dto: types.ResearchDto,
        stream: ResearchStreamIterator,
    };

    /// Gets a research task by ID. If stream is true, returns a streaming iterator.
    pub fn get(
        self: ResearchClient,
        allocator: std.mem.Allocator,
        research_id: []const u8,
        stream: bool,
        include_events: bool,
    ) !GetResult {
        if (stream) {
            const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, research_id });
            defer allocator.free(path);
            const body = "{}";
            var params = std.ArrayList(QueryParam).init(allocator);
            defer params.deinit();
            try params.append(.{ .key = "stream", .value = "true" });
            const base = try std.mem.concat(allocator, u8, &.{ path, "?stream=true" });
            defer allocator.free(base);
            const response = try self.http.postStream(base, body);
            return GetResult{ .stream = ResearchStreamIterator{ .allocator = allocator, .response = response } };
        }

        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, research_id });
        defer allocator.free(path);

        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (include_events) try params.append(.{ .key = "events", .value = "true" });

        const response_body = try self.http.get(path, if (params.items.len > 0) params.items else null);
        defer allocator.free(response_body);
        const dto = try json.parseResearchDto(allocator, response_body);
        return GetResult{ .dto = dto };
    }

    /// Lists research tasks with optional pagination.
    pub fn list(self: ResearchClient, allocator: std.mem.Allocator, cursor: ?[]const u8, limit: ?i64) !types.ListResearchResponseDto {
        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (cursor) |c| try params.append(.{ .key = "cursor", .value = c });
        var limit_buf: [32]u8 = undefined;
        if (limit) |l| {
            const s = try std.fmt.bufPrint(&limit_buf, "{d}", .{l});
            try params.append(.{ .key = "limit", .value = s });
        }
        const response_body = try self.http.get(self.base_path, if (params.items.len > 0) params.items else null);
        defer allocator.free(response_body);
        return json.parseListResearchResponseDto(allocator, response_body);
    }

    /// Polls until the research task is finished. Returns error.Timeout or error.TooManyFailures as appropriate.
    pub fn pollUntilFinished(
        self: ResearchClient,
        allocator: std.mem.Allocator,
        research_id: []const u8,
        poll_interval_ms: u64,
        timeout_ms: u64,
        include_events: bool,
    ) !types.ResearchDto {
        const start = std.time.milliTimestamp();
        var consecutive_errors: u32 = 0;

        while (true) {
            const result = self.get(allocator, research_id, false, include_events) catch {
                consecutive_errors += 1;
                if (consecutive_errors >= 5) return error.TooManyFailures;
                std.time.sleep(poll_interval_ms * std.time.ns_per_ms);
                const elapsed_err: u64 = @intCast(std.time.milliTimestamp() - start);
                if (elapsed_err >= timeout_ms) return error.Timeout;
                continue;
            };
            consecutive_errors = 0;

            switch (result) {
                .dto => |dto| {
                    switch (dto) {
                        .completed, .failed, .canceled => return dto,
                        else => {
                            // free the dto and continue polling
                        },
                    }
                },
                .stream => unreachable,
            }

            const elapsed: u64 = @intCast(std.time.milliTimestamp() - start);
            if (elapsed >= timeout_ms) return error.Timeout;
            std.time.sleep(poll_interval_ms * std.time.ns_per_ms);
        }
    }
};
