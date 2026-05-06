/// Webset events subclient.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetEventsClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/websets/events",

    pub fn list(
        self: WebsetEventsClient,
        allocator: std.mem.Allocator,
        cursor: ?[]const u8,
        limit: ?i64,
        event_types: ?[]const types.EventType,
    ) !types.ListEventsResponse {
        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (cursor) |c| try params.append(.{ .key = "cursor", .value = c });
        var limit_buf: [32]u8 = undefined;
        if (limit) |l| {
            const s = try std.fmt.bufPrint(&limit_buf, "{d}", .{l});
            try params.append(.{ .key = "limit", .value = s });
        }
        var types_buf: ?[]u8 = null;
        defer if (types_buf) |t| allocator.free(t);
        if (event_types) |et| {
            var buf = std.ArrayList(u8).init(allocator);
            defer buf.deinit();
            for (et, 0..) |t, i| {
                if (i > 0) try buf.appendSlice(",");
                try buf.appendSlice(t.toString());
            }
            types_buf = try buf.toOwnedSlice();
            try params.append(.{ .key = "types", .value = types_buf.? });
        }

        const body = try self.http.get(self.base_path, if (params.items.len > 0) params.items else null);
        defer allocator.free(body);
        return json.parseListEventsResponse(allocator, body);
    }
};
