/// Webset searches subclient.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetSearchesClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/websets",

    pub fn create(
        self: WebsetSearchesClient,
        allocator: std.mem.Allocator,
        webset_id: []const u8,
        params: types.CreateWebsetSearchParameters,
        options: ?types.RequestOptions,
    ) !types.WebsetSearch {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/searches", .{ self.base_path, webset_id });
        defer allocator.free(path);

        const request_body = try json.serializeCreateWebsetSearchParameters(allocator, params);
        defer allocator.free(request_body);

        // If priority is set, we need a custom HTTP call with an extra header.
        // Since HttpClient does not support per-request headers, we add the header temporarily.
        if (options) |opts| {
            if (opts.priority) |priority| {
                // Store existing headers, add priority header, POST, then remove it.
                var http = self.http;
                const priority_key = try allocator.dupe(u8, "x-exa-websets-priority");
                defer allocator.free(priority_key);
                const priority_val = try allocator.dupe(u8, priority.toString());
                defer allocator.free(priority_val);
                try http.headers.put(priority_key, priority_val);
                const response_body = try http.post(path, request_body);
                defer allocator.free(response_body);
                _ = http.headers.remove(priority_key);
                return json.parseWebsetSearch(allocator, response_body);
            }
        }

        const response_body = try self.http.post(path, request_body);
        defer allocator.free(response_body);
        return json.parseWebsetSearch(allocator, response_body);
    }

    pub fn get(self: WebsetSearchesClient, allocator: std.mem.Allocator, webset_id: []const u8, search_id: []const u8) !types.WebsetSearch {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/searches/{s}", .{ self.base_path, webset_id, search_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseWebsetSearch(allocator, body);
    }

    pub fn list(
        self: WebsetSearchesClient,
        allocator: std.mem.Allocator,
        webset_id: []const u8,
        cursor: ?[]const u8,
        limit: ?i64,
    ) !types.ListWebsetSearchesResponse {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/searches", .{ self.base_path, webset_id });
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
        return json.parseListWebsetSearchesResponse(allocator, body);
    }

    pub fn cancel(self: WebsetSearchesClient, allocator: std.mem.Allocator, webset_id: []const u8, search_id: []const u8) !types.WebsetSearch {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/searches/{s}/cancel", .{ self.base_path, webset_id, search_id });
        defer allocator.free(path);
        const body = try self.http.post(path, "{}");
        defer allocator.free(body);
        return json.parseWebsetSearch(allocator, body);
    }
};
