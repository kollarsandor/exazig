/// Search Monitors client.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const SearchMonitorRunsClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/monitors",

    pub fn list(
        self: SearchMonitorRunsClient,
        allocator: std.mem.Allocator,
        monitor_id: []const u8,
        cursor: ?[]const u8,
        limit: ?i64,
    ) !types.ListSearchMonitorRunsResponse {
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
        return json.parseListSearchMonitorRunsResponse(allocator, body);
    }

    pub fn get(self: SearchMonitorRunsClient, allocator: std.mem.Allocator, monitor_id: []const u8, run_id: []const u8) !types.SearchMonitorRun {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/runs/{s}", .{ self.base_path, monitor_id, run_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseSearchMonitorRun(allocator, body);
    }

    /// Paginates through all runs for the given monitor. Caller frees the returned slice.
    pub fn listAll(
        self: SearchMonitorRunsClient,
        allocator: std.mem.Allocator,
        monitor_id: []const u8,
        limit: ?i64,
    ) ![]types.SearchMonitorRun {
        var all = std.ArrayList(types.SearchMonitorRun).init(allocator);
        errdefer {
            for (all.items) |r| r.deinit(allocator);
            all.deinit();
        }
        var cursor: ?[]u8 = null;
        defer if (cursor) |c| allocator.free(c);

        while (true) {
            const page = try self.list(allocator, monitor_id, cursor, limit);
            defer allocator.free(page.data);

            for (page.data) |r| try all.append(r);

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
};

pub const SearchMonitorsClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/monitors",
    runs: SearchMonitorRunsClient,

    pub fn init(http: HttpClient) SearchMonitorsClient {
        return SearchMonitorsClient{
            .http = http,
            .runs = SearchMonitorRunsClient{ .http = http },
        };
    }

    pub fn create(self: SearchMonitorsClient, allocator: std.mem.Allocator, params: types.CreateSearchMonitorParams) !types.CreateSearchMonitorResponse {
        const request_body = try json.serializeCreateSearchMonitorParams(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.post(self.base_path, request_body);
        defer allocator.free(response_body);
        return json.parseCreateSearchMonitorResponse(allocator, response_body);
    }

    pub fn get_monitor(self: SearchMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8) !types.SearchMonitor {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseSearchMonitor(allocator, body);
    }

    pub fn list(
        self: SearchMonitorsClient,
        allocator: std.mem.Allocator,
        status: ?types.SearchMonitorStatus,
        cursor: ?[]const u8,
        limit: ?i64,
    ) !types.ListSearchMonitorsResponse {
        var params = std.ArrayList(QueryParam).init(allocator);
        defer params.deinit();
        if (status) |s| try params.append(.{ .key = "status", .value = s.toString() });
        if (cursor) |c| try params.append(.{ .key = "cursor", .value = c });
        var limit_buf: [32]u8 = undefined;
        if (limit) |l| {
            const s = try std.fmt.bufPrint(&limit_buf, "{d}", .{l});
            try params.append(.{ .key = "limit", .value = s });
        }
        const body = try self.http.get(self.base_path, if (params.items.len > 0) params.items else null);
        defer allocator.free(body);
        return json.parseListSearchMonitorsResponse(allocator, body);
    }

    pub fn update(self: SearchMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8, params: types.UpdateSearchMonitorParams) !types.SearchMonitor {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const request_body = try json.serializeUpdateSearchMonitorParams(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.patch(path, request_body);
        defer allocator.free(response_body);
        return json.parseSearchMonitor(allocator, response_body);
    }

    pub fn delete(self: SearchMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8) !types.SearchMonitor {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const body = try self.http.delete(path);
        defer allocator.free(body);
        return json.parseSearchMonitor(allocator, body);
    }

    pub fn trigger(self: SearchMonitorsClient, allocator: std.mem.Allocator, monitor_id: []const u8) !types.TriggerSearchMonitorResponse {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}/trigger", .{ self.base_path, monitor_id });
        defer allocator.free(path);
        const body = try self.http.post(path, "{}");
        defer allocator.free(body);
        return json.parseTriggerSearchMonitorResponse(allocator, body);
    }

    /// Paginates through all monitors. Caller frees the returned slice.
    pub fn listAll(
        self: SearchMonitorsClient,
        allocator: std.mem.Allocator,
        status: ?types.SearchMonitorStatus,
        limit: ?i64,
    ) ![]types.SearchMonitor {
        var all = std.ArrayList(types.SearchMonitor).init(allocator);
        errdefer {
            for (all.items) |m| m.deinit(allocator);
            all.deinit();
        }
        var cursor: ?[]u8 = null;
        defer if (cursor) |c| allocator.free(c);

        while (true) {
            const page = try self.list(allocator, status, cursor, limit);
            defer allocator.free(page.data);

            for (page.data) |m| try all.append(m);

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
};
