/// HTTP client wrapping std.http.Client for the Exa API.
const std = @import("std");

pub const QueryParam = struct {
    key: []const u8,
    value: []const u8,
};

/// An open streaming HTTP response. Call nextLine() to read SSE lines.
pub const StreamingResponse = struct {
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    request: std.http.Client.Request,
    server_header_buf: *[16 * 1024]u8,

    /// Reads the next line from the streaming response body.
    /// Returns null at EOF. The returned slice is owned by the caller; free it after use.
    pub fn nextLine(self: *StreamingResponse) !?[]u8 {
        var line_buf = std.ArrayList(u8).init(self.allocator);
        defer line_buf.deinit();

        while (true) {
            var byte: [1]u8 = undefined;
            const n = self.request.reader().read(&byte) catch |err| {
                if (err == error.EndOfStream) {
                    if (line_buf.items.len > 0) return try line_buf.toOwnedSlice();
                    return null;
                }
                return err;
            };
            if (n == 0) {
                if (line_buf.items.len > 0) return try line_buf.toOwnedSlice();
                return null;
            }
            if (byte[0] == '\n') {
                // Strip trailing '\r' if present
                if (line_buf.items.len > 0 and line_buf.items[line_buf.items.len - 1] == '\r') {
                    _ = line_buf.pop();
                }
                return try line_buf.toOwnedSlice();
            }
            try line_buf.append(byte[0]);
        }
    }

    /// Closes the streaming connection and frees internal resources.
    pub fn close(self: *StreamingResponse) void {
        self.request.deinit();
        self.allocator.destroy(self.client);
        self.allocator.destroy(self.server_header_buf);
    }
};

/// HTTP client for the Exa API.
pub const HttpClient = struct {
    allocator: std.mem.Allocator,
    base_url: []const u8,
    headers: std.StringHashMap([]const u8),

    pub fn init(
        allocator: std.mem.Allocator,
        base_url: []const u8,
        api_key: []const u8,
        user_agent: []const u8,
    ) !HttpClient {
        var headers = std.StringHashMap([]const u8).init(allocator);
        errdefer headers.deinit();

        const key_copy = try allocator.dupe(u8, api_key);
        errdefer allocator.free(key_copy);
        const ua_copy = try allocator.dupe(u8, user_agent);
        errdefer allocator.free(ua_copy);
        const ct_copy = try allocator.dupe(u8, "application/json");
        errdefer allocator.free(ct_copy);
        const base_copy = try allocator.dupe(u8, base_url);
        errdefer allocator.free(base_copy);

        try headers.put("x-api-key", key_copy);
        try headers.put("User-Agent", ua_copy);
        try headers.put("Content-Type", ct_copy);

        return HttpClient{
            .allocator = allocator,
            .base_url = base_copy,
            .headers = headers,
        };
    }

    pub fn deinit(self: *HttpClient) void {
        var it = self.headers.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.headers.deinit();
        self.allocator.free(self.base_url);
    }

    /// Fills buf with std.http.Header entries from self.headers.
    /// Returns the populated slice (up to buf.len entries).
    fn extraHeaders(self: HttpClient, buf: []std.http.Header) []std.http.Header {
        var it = self.headers.iterator();
        var i: usize = 0;
        while (it.next()) |entry| {
            if (i >= buf.len) break;
            buf[i] = .{ .name = entry.key_ptr.*, .value = entry.value_ptr.* };
            i += 1;
        }
        return buf[0..i];
    }

    fn buildUri(self: HttpClient, url: []const u8, query_params: ?[]const QueryParam) ![]u8 {
        var buf = std.ArrayList(u8).init(self.allocator);
        defer buf.deinit();
        try buf.appendSlice(url);
        if (query_params) |qps| {
            if (qps.len > 0) {
                try buf.append('?');
                for (qps, 0..) |qp, i| {
                    if (i > 0) try buf.append('&');
                    try buf.appendSlice(qp.key);
                    try buf.append('=');
                    for (qp.value) |c| {
                        if (std.ascii.isAlphanumeric(c) or c == '-' or c == '_' or c == '.' or c == '~') {
                            try buf.append(c);
                        } else {
                            try buf.writer().print("%{X:0>2}", .{c});
                        }
                    }
                }
            }
        }
        return buf.toOwnedSlice();
    }

    fn readResponseBody(self: HttpClient, req: *std.http.Client.Request) ![]u8 {
        var body_buf = std.ArrayList(u8).init(self.allocator);
        defer body_buf.deinit();
        var read_buf: [4096]u8 = undefined;
        while (true) {
            const n = req.reader().read(&read_buf) catch |err| {
                if (err == error.EndOfStream) break;
                return err;
            };
            if (n == 0) break;
            try body_buf.appendSlice(read_buf[0..n]);
        }
        return body_buf.toOwnedSlice();
    }

    fn checkStatus(req: *std.http.Client.Request, body: []const u8) !void {
        const status = req.response.status;
        const code = @intFromEnum(status);
        if (code >= 400) {
            std.log.err("Exa API error {d}: {s}", .{ code, body });
            return error.HttpError;
        }
    }

    pub fn post(self: HttpClient, endpoint: []const u8, body: []const u8) ![]u8 {
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const full_url = try std.mem.concat(self.allocator, u8, &.{ self.base_url, endpoint });
        defer self.allocator.free(full_url);

        const uri = try std.Uri.parse(full_url);

        var server_header_buf: [16 * 1024]u8 = undefined;
        var hbuf: [8]std.http.Header = undefined;
        var req = try client.open(.POST, uri, .{
            .server_header_buffer = &server_header_buf,
            .extra_headers = self.extraHeaders(&hbuf),
        });
        defer req.deinit();

        req.transfer_encoding = .{ .content_length = body.len };
        try req.send();
        try req.writer().writeAll(body);
        try req.finish();
        try req.wait();

        const response_body = try self.readResponseBody(&req);
        errdefer self.allocator.free(response_body);
        try checkStatus(&req, response_body);
        return response_body;
    }

    pub fn get(self: HttpClient, endpoint: []const u8, query_params: ?[]const QueryParam) ![]u8 {
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const base = try std.mem.concat(self.allocator, u8, &.{ self.base_url, endpoint });
        defer self.allocator.free(base);

        const full_url = try self.buildUri(base, query_params);
        defer self.allocator.free(full_url);

        const uri = try std.Uri.parse(full_url);

        var server_header_buf: [16 * 1024]u8 = undefined;
        var hbuf: [8]std.http.Header = undefined;
        var req = try client.open(.GET, uri, .{
            .server_header_buffer = &server_header_buf,
            .extra_headers = self.extraHeaders(&hbuf),
        });
        defer req.deinit();

        try req.send();
        try req.finish();
        try req.wait();

        const response_body = try self.readResponseBody(&req);
        errdefer self.allocator.free(response_body);
        try checkStatus(&req, response_body);
        return response_body;
    }

    pub fn patch(self: HttpClient, endpoint: []const u8, body: []const u8) ![]u8 {
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const full_url = try std.mem.concat(self.allocator, u8, &.{ self.base_url, endpoint });
        defer self.allocator.free(full_url);

        const uri = try std.Uri.parse(full_url);

        var server_header_buf: [16 * 1024]u8 = undefined;
        var hbuf: [8]std.http.Header = undefined;
        var req = try client.open(.PATCH, uri, .{
            .server_header_buffer = &server_header_buf,
            .extra_headers = self.extraHeaders(&hbuf),
        });
        defer req.deinit();

        req.transfer_encoding = .{ .content_length = body.len };
        try req.send();
        try req.writer().writeAll(body);
        try req.finish();
        try req.wait();

        const response_body = try self.readResponseBody(&req);
        errdefer self.allocator.free(response_body);
        try checkStatus(&req, response_body);
        return response_body;
    }

    pub fn delete(self: HttpClient, endpoint: []const u8) ![]u8 {
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const full_url = try std.mem.concat(self.allocator, u8, &.{ self.base_url, endpoint });
        defer self.allocator.free(full_url);

        const uri = try std.Uri.parse(full_url);

        var server_header_buf: [16 * 1024]u8 = undefined;
        var hbuf: [8]std.http.Header = undefined;
        var req = try client.open(.DELETE, uri, .{
            .server_header_buffer = &server_header_buf,
            .extra_headers = self.extraHeaders(&hbuf),
        });
        defer req.deinit();

        try req.send();
        try req.finish();
        try req.wait();

        const response_body = try self.readResponseBody(&req);
        errdefer self.allocator.free(response_body);
        try checkStatus(&req, response_body);
        return response_body;
    }

    /// PUT to an absolute URL (no base_url prepended). Used for file uploads.
    pub fn put(self: HttpClient, url: []const u8, body: []const u8) !void {
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const uri = try std.Uri.parse(url);

        var server_header_buf: [16 * 1024]u8 = undefined;
        var req = try client.open(.PUT, uri, .{
            .server_header_buffer = &server_header_buf,
        });
        defer req.deinit();

        req.transfer_encoding = .{ .content_length = body.len };
        try req.send();
        try req.writer().writeAll(body);
        try req.finish();
        try req.wait();

        const response_body = try self.readResponseBody(&req);
        defer self.allocator.free(response_body);
        try checkStatus(&req, response_body);
    }

    /// POST with streaming — returns an open StreamingResponse.
    /// The StreamingResponse owns its server_header_buf (heap-allocated) and
    /// must be closed with StreamingResponse.close().
    pub fn postStream(self: HttpClient, endpoint: []const u8, body: []const u8) !StreamingResponse {
        const client_ptr = try self.allocator.create(std.http.Client);
        errdefer self.allocator.destroy(client_ptr);
        client_ptr.* = std.http.Client{ .allocator = self.allocator };

        const shb = try self.allocator.create([16 * 1024]u8);
        errdefer self.allocator.destroy(shb);

        const full_url = try std.mem.concat(self.allocator, u8, &.{ self.base_url, endpoint });
        defer self.allocator.free(full_url);

        const uri = try std.Uri.parse(full_url);

        var hbuf: [8]std.http.Header = undefined;
        var req = try client_ptr.open(.POST, uri, .{
            .server_header_buffer = shb,
            .extra_headers = self.extraHeaders(&hbuf),
        });

        req.transfer_encoding = .{ .content_length = body.len };
        try req.send();
        try req.writer().writeAll(body);
        try req.finish();
        try req.wait();

        const status = @intFromEnum(req.response.status);
        if (status >= 400) {
            req.deinit();
            client_ptr.deinit();
            self.allocator.destroy(client_ptr);
            self.allocator.destroy(shb);
            return error.HttpError;
        }

        return StreamingResponse{
            .allocator = self.allocator,
            .client = client_ptr,
            .request = req,
            .server_header_buf = shb,
        };
    }
};
