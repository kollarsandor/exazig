/// Webset items subclient.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetItemsClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/websets",

    pub fn get(self: WebsetItemsClient, allocator: std.mem.Allocator, webset_id: []const u8, item_id: []const u8) !types.WebsetItem {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/items/{s}", .{ self.base_path, webset_id, item_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseWebsetItem(allocator, body);
    }

    pub fn list(
        self: WebsetItemsClient,
        allocator: std.mem.Allocator,
        webset_id: []const u8,
        cursor: ?[]const u8,
        limit: ?i64,
    ) !types.ListWebsetItemResponse {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/items", .{ self.base_path, webset_id });
        defer allocator.free(path);

        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (cursor) |c| try params.append(.{ .key = "cursor", .value = c });
        var limit_buf: [32]u8 = undefined;
        if (limit) |l| {
            const s = try std.fmt.bufPrint(&limit_buf, "{d}", .{l});
            try params.append(.{ .key = "limit", .value = s });
        }

        const body = try self.http.get(path, if (params.items.len > 0) params.items else null);
        defer allocator.free(body);
        return json.parseListWebsetItemResponse(allocator, body);
    }

    /// Paginates through all items for the given webset. Caller frees the returned slice.
    pub fn listAll(self: WebsetItemsClient, allocator: std.mem.Allocator, webset_id: []const u8, limit: ?i64) ![]types.WebsetItem {
        var all = std.ArrayList(types.WebsetItem).init(allocator);
        errdefer {
            for (all.items) |item| item.deinit(allocator);
            all.deinit();
        }
        var cursor: ?[]u8 = null;
        defer if (cursor) |c| allocator.free(c);

        while (true) {
            const page = try self.list(allocator, webset_id, cursor, limit);
            defer {
                // We take ownership of the items, so only free the slice itself and the cursor.
                allocator.free(page.data);
            }
            // Append items (transferring ownership)
            for (page.data) |item| try all.append(item);
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

    pub fn delete(self: WebsetItemsClient, allocator: std.mem.Allocator, webset_id: []const u8, item_id: []const u8) !types.WebsetItem {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/items/{s}", .{ self.base_path, webset_id, item_id });
        defer allocator.free(path);
        const body = try self.http.delete(path);
        defer allocator.free(body);
        return json.parseWebsetItem(allocator, body);
    }
};
