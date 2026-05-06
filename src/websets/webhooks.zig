/// Webset webhooks subclient.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetWebhooksClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/websets/webhooks",

    pub fn create(self: WebsetWebhooksClient, allocator: std.mem.Allocator, params: types.CreateWebhookParameters) !types.Webhook {
        const request_body = try json.serializeCreateWebhookParameters(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.post(self.base_path, request_body);
        defer allocator.free(response_body);
        return json.parseWebhook(allocator, response_body);
    }

    pub fn get(self: WebsetWebhooksClient, allocator: std.mem.Allocator, webhook_id: []const u8) !types.Webhook {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, webhook_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseWebhook(allocator, body);
    }

    pub fn list(self: WebsetWebhooksClient, allocator: std.mem.Allocator, cursor: ?[]const u8, limit: ?i64) !types.ListWebhooksResponse {
        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (cursor) |c| try params.append(.{ .key = "cursor", .value = c });
        var limit_buf: [32]u8 = undefined;
        if (limit) |l| {
            const s = try std.fmt.bufPrint(&limit_buf, "{d}", .{l});
            try params.append(.{ .key = "limit", .value = s });
        }
        const body = try self.http.get(self.base_path, if (params.items.len > 0) params.items else null);
        defer allocator.free(body);
        return json.parseListWebhooksResponse(allocator, body);
    }

    pub fn update(self: WebsetWebhooksClient, allocator: std.mem.Allocator, webhook_id: []const u8, params: types.UpdateWebhookParameters) !types.Webhook {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, webhook_id });
        defer allocator.free(path);
        const request_body = try json.serializeUpdateWebhookParameters(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.patch(path, request_body);
        defer allocator.free(response_body);
        return json.parseWebhook(allocator, response_body);
    }

    pub fn delete(self: WebsetWebhooksClient, allocator: std.mem.Allocator, webhook_id: []const u8) !types.Webhook {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, webhook_id });
        defer allocator.free(path);
        const body = try self.http.delete(path);
        defer allocator.free(body);
        return json.parseWebhook(allocator, body);
    }

    pub fn listAttempts(self: WebsetWebhooksClient, allocator: std.mem.Allocator, webhook_id: []const u8, cursor: ?[]const u8, limit: ?i64) !types.ListWebhookAttemptsResponse {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/attempts", .{ self.base_path, webhook_id });
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
        return json.parseListWebhookAttemptsResponse(allocator, body);
    }
};
