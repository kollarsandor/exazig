/// Webset imports subclient.
const std = @import("std");
const http_mod = @import("../http.zig");
const types = @import("types.zig");
const json = @import("json.zig");

const HttpClient = http_mod.HttpClient;
const QueryParam = http_mod.QueryParam;

pub const WebsetImportsClient = struct {
    http: HttpClient,
    base_path: []const u8 = "/websets/imports",

    pub fn create(self: WebsetImportsClient, allocator: std.mem.Allocator, params: types.CreateImportParameters) !types.CreateImportResponse {
        const request_body = try json.serializeCreateImportParameters(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.post(self.base_path, request_body);
        defer allocator.free(response_body);
        return json.parseCreateImportResponse(allocator, response_body);
    }

    pub fn get(self: WebsetImportsClient, allocator: std.mem.Allocator, import_id: []const u8) !types.Import {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, import_id });
        defer allocator.free(path);
        const body = try self.http.get(path, null);
        defer allocator.free(body);
        return json.parseImport(allocator, body);
    }

    pub fn list(self: WebsetImportsClient, allocator: std.mem.Allocator, cursor: ?[]const u8, limit: ?i64) !types.ListImportsResponse {
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
        return json.parseListImportsResponse(allocator, body);
    }

    pub fn update(self: WebsetImportsClient, allocator: std.mem.Allocator, import_id: []const u8, params: types.UpdateImport) !types.Import {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, import_id });
        defer allocator.free(path);
        const request_body = try json.serializeUpdateImport(allocator, params);
        defer allocator.free(request_body);
        const response_body = try self.http.patch(path, request_body);
        defer allocator.free(response_body);
        return json.parseImport(allocator, response_body);
    }

    pub fn delete(self: WebsetImportsClient, allocator: std.mem.Allocator, import_id: []const u8) !types.Import {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ self.base_path, import_id });
        defer allocator.free(path);
        const body = try self.http.delete(path);
        defer allocator.free(body);
        return json.parseImport(allocator, body);
    }

    /// Uploads raw bytes to the given upload URL via HTTP PUT.
    pub fn upload(
        self: WebsetImportsClient,
        allocator: std.mem.Allocator,
        import_id: []const u8,
        upload_url: []const u8,
        data: []const u8,
    ) !void {
        _ = import_id;
        _ = allocator;
        try self.http.put(upload_url, data);
    }
};
