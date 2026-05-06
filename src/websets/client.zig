/// WebsetsClient — top-level client for the Websets subsystem.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");
const items_mod = @import("items.zig");
const searches_mod = @import("searches.zig");
const enrichments_mod = @import("enrichments.zig");
const webhooks_mod = @import("webhooks.zig");
const monitors_mod = @import("monitors.zig");
const imports_mod = @import("imports.zig");
const events_mod = @import("events.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetsClient = struct {
    http: HttpClient,
    items: items_mod.WebsetItemsClient,
    searches: searches_mod.WebsetSearchesClient,
    enrichments: enrichments_mod.WebsetEnrichmentsClient,
    webhooks: webhooks_mod.WebsetWebhooksClient,
    monitors: monitors_mod.WebsetMonitorsClient,
    imports: imports_mod.WebsetImportsClient,
    events: events_mod.WebsetEventsClient,

    pub fn init(http: HttpClient) WebsetsClient {
        return WebsetsClient{
            .http = http,
            .items = .{ .http = http },
            .searches = .{ .http = http },
            .enrichments = .{ .http = http },
            .webhooks = .{ .http = http },
            .monitors = .{ .http = http },
            .imports = .{ .http = http },
            .events = .{ .http = http },
        };
    }

    pub fn create(
        self: WebsetsClient,
        allocator: std.mem.Allocator,
        params: types.CreateWebsetParameters,
        options: ?types.RequestOptions,
    ) !types.Webset {
        const request_body = try json.serializeCreateWebsetParameters(allocator, params);
        defer allocator.free(request_body);

        if (options) |opts| {
            if (opts.priority) |priority| {
                var http = self.http;
                const key = try allocator.dupe(u8, "x-exa-websets-priority");
                defer allocator.free(key);
                const val = try allocator.dupe(u8, priority.toString());
                defer allocator.free(val);
                try http.headers.put(key, val);
                const response_body = try http.post("/websets", request_body);
                defer allocator.free(response_body);
                _ = http.headers.remove(key);
                return json.parseWebset(allocator, response_body);
            }
        }

        const response_body = try self.http.post("/websets", request_body);
        defer allocator.free(response_body);
        return json.parseWebset(allocator, response_body);
    }

    pub fn preview(self: WebsetsClient, allocator: std.mem.Allocator, params: types.PreviewWebsetParameters) !types.PreviewWebsetResponse {
        const request_body = try json.serializePreviewWebsetParameters(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.post("/websets/preview", request_body);
        defer allocator.free(response_body);
        return json.parsePreviewWebsetResponse(allocator, response_body);
    }

    pub fn get(
        self: WebsetsClient,
        allocator: std.mem.Allocator,
        id: []const u8,
        expand: ?[]const []const u8,
    ) !types.GetWebsetResponse {
        const base_path = try std.fmt.allocPrint(allocator, "/websets/{s}", .{id});
        defer allocator.free(base_path);

        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        var expand_buf: ?[]u8 = null;
        defer if (expand_buf) |e| allocator.free(e);

        if (expand) |fields| {
            var buf = std.ArrayList(u8).init(allocator);
            defer buf.deinit();
            for (fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(",");
                try buf.appendSlice(f);
            }
            expand_buf = try buf.toOwnedSlice();
            try params.append(.{ .key = "expand", .value = expand_buf.? });
        }

        const body = try self.http.get(base_path, if (params.items.len > 0) params.items else null);
        defer allocator.free(body);
        return json.parseGetWebsetResponse(allocator, body);
    }

    pub fn list(self: WebsetsClient, allocator: std.mem.Allocator, cursor: ?[]const u8, limit: ?i64) !types.ListWebsetsResponse {
        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (cursor) |c| try params.append(.{ .key = "cursor", .value = c });
        var limit_buf: [32]u8 = undefined;
        if (limit) |l| {
            const s = try std.fmt.bufPrint(&limit_buf, "{d}", .{l});
            try params.append(.{ .key = "limit", .value = s });
        }
        const body = try self.http.get("/websets", if (params.items.len > 0) params.items else null);
        defer allocator.free(body);
        return json.parseListWebsetsResponse(allocator, body);
    }

    pub fn update(self: WebsetsClient, allocator: std.mem.Allocator, id: []const u8, params: types.UpdateWebsetRequest) !types.Webset {
        const path = try std.fmt.allocPrint(allocator, "/websets/{s}", .{id});
        defer allocator.free(path);

        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();
        const w = buf.writer();
        try w.writeByte('{');
        if (params.metadata) |m| {
            try w.writeAll("\"metadata\":");
            try writeJsonValue(w, m);
        }
        try w.writeByte('}');
        const request_body = try buf.toOwnedSlice();
        defer allocator.free(request_body);

        const response_body = try self.http.patch(path, request_body);
        defer allocator.free(response_body);
        return json.parseWebset(allocator, response_body);
    }

    pub fn delete(self: WebsetsClient, allocator: std.mem.Allocator, id: []const u8) !types.Webset {
        const path = try std.fmt.allocPrint(allocator, "/websets/{s}", .{id});
        defer allocator.free(path);
        const body = try self.http.delete(path);
        defer allocator.free(body);
        return json.parseWebset(allocator, body);
    }

    pub fn cancel(self: WebsetsClient, allocator: std.mem.Allocator, id: []const u8) !types.Webset {
        const path = try std.fmt.allocPrint(allocator, "/websets/{s}/cancel", .{id});
        defer allocator.free(path);
        const body = try self.http.post(path, "{}");
        defer allocator.free(body);
        return json.parseWebset(allocator, body);
    }

    /// Paginates through all websets. Caller frees the returned slice.
    pub fn listAll(self: WebsetsClient, allocator: std.mem.Allocator, limit: ?i64) ![]types.Webset {
        var all = std.ArrayList(types.Webset).init(allocator);
        errdefer {
            for (all.items) |ws| ws.deinit(allocator);
            all.deinit();
        }
        var cursor: ?[]u8 = null;
        defer if (cursor) |c| allocator.free(c);

        while (true) {
            const page = try self.list(allocator, cursor, limit);
            defer allocator.free(page.data);

            for (page.data) |ws| try all.append(ws);

            const old_cursor = cursor;
            if (page.next_cursor) |nc| {
                cursor = try allocator.dupe(u8, nc);
                allocator.free(nc);
            } else {
                cursor = null;
            }
            if (old_cursor) |oc| allocator.free(oc);
            if (!page.has_more) break;
            if (cursor == null) break;
        }
        return all.toOwnedSlice();
    }

    /// Polls until the webset status is idle, or returns error.Timeout.
    pub fn waitUntilIdle(
        self: WebsetsClient,
        allocator: std.mem.Allocator,
        id: []const u8,
        timeout_s: u64,
        poll_interval_s: u64,
        on_poll: ?*const fn (webset: types.Webset) void,
    ) !types.Webset {
        const start = std.time.timestamp();
        while (true) {
            const ws = try self.get(allocator, id, null);
            if (on_poll) |cb| cb(ws);
            if (ws.status == .idle) return ws;
            ws.deinit(allocator);

            const elapsed: u64 = @intCast(std.time.timestamp() - start);
            if (elapsed >= timeout_s) return error.Timeout;
            std.time.sleep(poll_interval_s * std.time.ns_per_s);
        }
    }
};

fn writeJsonValue(writer: anytype, val: std.json.Value) !void {
    switch (val) {
        .null => try writer.writeAll("null"),
        .bool => |b| try writer.writeAll(if (b) "true" else "false"),
        .integer => |n| try writer.print("{d}", .{n}),
        .float => |f| try writer.print("{d}", .{f}),
        .number_string => |s| try writer.writeAll(s),
        .string => |s| {
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
        },
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
                try writer.writeByte('"');
                try writer.writeAll(entry.key_ptr.*);
                try writer.writeAll("\":");
                try writeJsonValue(writer, entry.value_ptr.*);
            }
            try writer.writeByte('}');
        },
    }
}
