/// Webset monitors subclient.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetMonitorsClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/websets/monitors",

    pub fn create(
        self: WebsetMonitorsClient,
        allocator: std.mem.Allocator,
        params: types.CreateMonitorParameters,
        options: ?types.RequestOptions,
    ) !types.Monitor {
        const request_body = try json.serializeCreateMonitorParameters(allocator, params);
        defer allocator.free(request_body);

        if (options) |opts| {
            if (opts.priority) |priority| {
                var http = self.http;
                const key = try allocator.dupe(u8, "x-exa-websets-priority");
                defer allocator.free(key);
                const val = try allocator.dupe(u8, priority.toString());
                defer allocator.free(val);
                try http.headers.put(key, val);
                const response_body = try http.post(self.base_path, request_body);
                defer allocator.free(response_body);
                _ = http.headers.remove(key);
                return json.parseMonitor(allocator, response_body);
            }
        }

        const response_body = try self.http.post(self.base_path, request_body);
        defer allocator.free(response_body);
        return json.parseMonitor(allocator, response_body);
    }

    pub fn get(self: WebsetMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8) !types.Monitor {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseMonitor(allocator, body);
    }

    pub fn list(self: WebsetMonitorsClient, allocator: std.mem.Allocator, cursor: ?[]const u8, limit: ?i64) !types.ListMonitorsResponse {
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
        return json.parseListMonitorsResponse(allocator, body);
    }

    pub fn update(self: WebsetMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8, params: types.UpdateMonitor) !types.Monitor {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const request_body = try json.serializeUpdateMonitor(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.patch(path, request_body);
        defer allocator.free(response_body);
        return json.parseMonitor(allocator, response_body);
    }

    pub fn delete(self: WebsetMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8) !types.Monitor {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const body = try self.http.delete(path);
        defer allocator.free(body);
        return json.parseMonitor(allocator, body);
    }

    pub fn listRuns(self: WebsetMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8, cursor: ?[]const u8, limit: ?i64) !types.ListMonitorRunsResponse {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/runs", .{ self.base_path, monitor_id });
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
        return json.parseListMonitorRunsResponse(allocator, body);
    }
};
