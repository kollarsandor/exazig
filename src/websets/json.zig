/// JSON serialization and deserialization for the Websets subsystem.
const std = @import("std");
const types = @import("types.zig");
const utils = @import("../utils.zig");

// Re-export commonly used types
const Webset = types.Webset;
const WebsetItem = types.WebsetItem;
const WebsetSearch = types.WebsetSearch;
const WebsetEnrichment = types.WebsetEnrichment;
const Webhook = types.Webhook;
const WebhookAttempt = types.WebhookAttempt;
const Monitor = types.Monitor;
const MonitorRun = types.MonitorRun;
const Import = types.Import;
const CreateImportResponse = types.CreateImportResponse;
const WebsetEvent = types.WebsetEvent;

// ---------------------------------------------------------------------------
// Internal write helpers
// ---------------------------------------------------------------------------

fn writeStr(writer: anytype, s: []const u8) !void {
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
}

fn wStr(writer: anytype, key: []const u8, val: []const u8, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeStr(writer, key);
    try writer.writeByte(':');
    try writeStr(writer, val);
}

fn wBool(writer: anytype, key: []const u8, val: bool, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeStr(writer, key);
    try writer.print(":{s}", .{if (val) "true" else "false"});
}

fn wInt(writer: anytype, key: []const u8, val: i64, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeStr(writer, key);
    try writer.print(":{d}", .{val});
}

fn wFloat(writer: anytype, key: []const u8, val: f64, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeStr(writer, key);
    try writer.print(":{d}", .{val});
}

fn wJson(writer: anytype, key: []const u8, val: std.json.Value, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writeStr(writer, key);
    try writer.writeByte(':');
    try writeJsonValue(writer, val);
}

fn writeJsonValue(writer: anytype, val: std.json.Value) !void {
    switch (val) {
        .null => try writer.writeAll("null"),
        .bool => |b| try writer.writeAll(if (b) "true" else "false"),
        .integer => |n| try writer.print("{d}", .{n}),
        .float => |f| try writer.print("{d}", .{f}),
        .number_string => |s| try writer.writeAll(s),
        .string => |s| try writeStr(writer, s),
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
            var f = true;
            while (it.next()) |entry| {
                if (!f) try writer.writeByte(',');
                f = false;
                try writeStr(writer, entry.key_ptr.*);
                try writer.writeByte(':');
                try writeJsonValue(writer, entry.value_ptr.*);
            }
            try writer.writeByte('}');
        },
    }
}

fn writeEntity(writer: anytype, entity: types.WebsetEntity) !void {
    switch (entity) {
        .company => try writeStr(writer, "company"),
        .person => try writeStr(writer, "person"),
        .article => try writeStr(writer, "article"),
        .research_paper => try writeStr(writer, "research_paper"),
        .custom => |c| {
            try writer.writeAll("{\"type\":\"custom\",\"description\":");
            try writeStr(writer, c.description);
            try writer.writeByte('}');
        },
    }
}

fn writeExcludeItems(writer: anytype, items: []const types.ExcludeItem) !void {
    try writer.writeByte('[');
    for (items, 0..) |item, i| {
        if (i > 0) try writer.writeByte(',');
        try writer.writeAll("{\"source\":");
        try writeStr(writer, item.source.toString());
        try writer.writeAll(",\"id\":");
        try writeStr(writer, item.id);
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

fn writeScopeItems(writer: anytype, items: []const types.ScopeItem) !void {
    try writer.writeByte('[');
    for (items, 0..) |item, i| {
        if (i > 0) try writer.writeByte(',');
        try writer.writeAll("{\"source\":");
        try writeStr(writer, item.source.toString());
        try writer.writeAll(",\"id\":");
        try writeStr(writer, item.id);
        if (item.relationship) |rel| {
            try writer.writeAll(",\"relationship\":{\"definition\":");
            try writeStr(writer, rel.definition);
            if (rel.limit) |lim| {
                try writer.print(",\"limit\":{d}", .{lim});
            }
            try writer.writeByte('}');
        }
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

fn writeCriteria(writer: anytype, criteria: []const types.CreateCriterionParameters) !void {
    try writer.writeByte('[');
    for (criteria, 0..) |c, i| {
        if (i > 0) try writer.writeByte(',');
        try writer.writeAll("{\"description\":");
        try writeStr(writer, c.description);
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

fn writeSearchCriteria(writer: anytype, criteria: []const types.SearchCriterion) !void {
    try writer.writeByte('[');
    for (criteria, 0..) |c, i| {
        if (i > 0) try writer.writeByte(',');
        try writer.writeAll("{\"description\":");
        try writeStr(writer, c.description);
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

fn writeOptions(writer: anytype, options: []const types.Option) !void {
    try writer.writeByte('[');
    for (options, 0..) |o, i| {
        if (i > 0) try writer.writeByte(',');
        try writer.writeAll("{\"label\":");
        try writeStr(writer, o.label);
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

// ---------------------------------------------------------------------------
// Public Serializers
// ---------------------------------------------------------------------------

pub fn serializeCreateWebsetParameters(allocator: std.mem.Allocator, params: types.CreateWebsetParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;

    if (params.search) |s| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"search\":{");
        var sf = true;
        try wStr(w, "query", s.query, &sf);
        if (s.count) |c| try wInt(w, "count", c, &sf);
        if (s.entity) |e| {
            if (!sf) try w.writeByte(',');
            sf = false;
            try w.writeAll("\"entity\":");
            try writeEntity(w, e);
        }
        if (s.criteria) |c| {
            if (!sf) try w.writeByte(',');
            sf = false;
            try w.writeAll("\"criteria\":");
            try writeCriteria(w, c);
        }
        if (s.exclude) |ex| {
            if (!sf) try w.writeByte(',');
            sf = false;
            try w.writeAll("\"exclude\":");
            try writeExcludeItems(w, ex);
        }
        if (s.scope) |sc| {
            if (!sf) try w.writeByte(',');
            sf = false;
            try w.writeAll("\"scope\":");
            try writeScopeItems(w, sc);
        }
        try w.writeByte('}');
    }
    if (params.imports) |imports| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"import\":[");
        for (imports, 0..) |item, i| {
            if (i > 0) try w.writeByte(',');
            try w.writeAll("{\"source\":");
            try writeStr(w, item.source.toString());
            try w.writeAll(",\"id\":");
            try writeStr(w, item.id);
            try w.writeByte('}');
        }
        try w.writeByte(']');
    }
    if (params.enrichments) |enrichments| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"enrichments\":[");
        for (enrichments, 0..) |e, i| {
            if (i > 0) try w.writeByte(',');
            try w.writeAll("{\"description\":");
            try writeStr(w, e.description);
            if (e.format) |f| {
                try w.writeAll(",\"format\":");
                try writeStr(w, f.toString());
            }
            if (e.options) |opts| {
                try w.writeAll(",\"options\":");
                try writeOptions(w, opts);
            }
            if (e.metadata) |m| { var mf = false; try wJson(w, "metadata", m, &mf); }
            try w.writeByte('}');
        }
        try w.writeByte(']');
    }
    if (params.external_id) |v| try wStr(w, "externalId", v, &first);
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);

    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeCreateWebsetSearchParameters(allocator: std.mem.Allocator, params: types.CreateWebsetSearchParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;

    try wStr(w, "query", params.query, &first);
    try wInt(w, "count", params.count, &first);
    if (params.entity) |e| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"entity\":");
        try writeEntity(w, e);
    }
    if (params.criteria) |c| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"criteria\":");
        try writeCriteria(w, c);
    }
    if (params.exclude) |ex| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"exclude\":");
        try writeExcludeItems(w, ex);
    }
    if (params.scope) |sc| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"scope\":");
        try writeScopeItems(w, sc);
    }
    try wStr(w, "behavior", params.behavior.toString(), &first);
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);

    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeCreateEnrichmentParameters(allocator: std.mem.Allocator, params: types.CreateEnrichmentParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    try wStr(w, "description", params.description, &first);
    if (params.format) |f| try wStr(w, "format", f.toString(), &first);
    if (params.options) |opts| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"options\":");
        try writeOptions(w, opts);
    }
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeUpdateEnrichmentParameters(allocator: std.mem.Allocator, params: types.UpdateEnrichmentParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    if (params.description) |v| try wStr(w, "description", v, &first);
    if (params.format) |f| try wStr(w, "format", f.toString(), &first);
    if (params.options) |opts| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"options\":");
        try writeOptions(w, opts);
    }
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeCreateWebhookParameters(allocator: std.mem.Allocator, params: types.CreateWebhookParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    try wStr(w, "url", params.url, &first);
    if (!first) try w.writeByte(',');
    first = false;
    try w.writeAll("\"events\":[");
    for (params.events, 0..) |e, i| {
        if (i > 0) try w.writeByte(',');
        try writeStr(w, e.toString());
    }
    try w.writeByte(']');
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeUpdateWebhookParameters(allocator: std.mem.Allocator, params: types.UpdateWebhookParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    if (params.url) |v| try wStr(w, "url", v, &first);
    if (params.events) |evts| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"events\":[");
        for (evts, 0..) |e, i| {
            if (i > 0) try w.writeByte(',');
            try writeStr(w, e.toString());
        }
        try w.writeByte(']');
    }
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

fn writeMonitorBehavior(w: anytype, behavior: types.MonitorBehavior) !void {
    switch (behavior) {
        .search => |s| {
            try w.writeAll("{\"type\":\"search\",\"config\":{");
            var f = true;
            if (s.config.query) |q| try wStr(w, "query", q, &f);
            try wInt(w, "count", s.config.count, &f);
            if (s.config.entity) |e| {
                if (!f) try w.writeByte(',');
                f = false;
                try w.writeAll("\"entity\":");
                try writeEntity(w, e);
            }
            if (s.config.criteria) |c| {
                if (!f) try w.writeByte(',');
                f = false;
                try w.writeAll("\"criteria\":");
                try writeSearchCriteria(w, c);
            }
            try wStr(w, "behavior", s.config.behavior.toString(), &f);
            try w.writeAll("}}");
        },
        .refresh => |r| {
            try w.writeAll("{\"type\":\"refresh\",\"config\":");
            switch (r.config) {
                .enrichments => |e| {
                    try w.writeAll("{\"type\":\"enrichments\"");
                    if (e.ids) |ids| {
                        try w.writeAll(",\"ids\":[");
                        for (ids, 0..) |id, i| {
                            if (i > 0) try w.writeByte(',');
                            try writeStr(w, id);
                        }
                        try w.writeByte(']');
                    }
                    try w.writeByte('}');
                },
                .contents => {
                    try w.writeAll("{\"type\":\"contents\"}");
                },
            }
            try w.writeByte('}');
        },
    }
}

pub fn serializeCreateMonitorParameters(allocator: std.mem.Allocator, params: types.CreateMonitorParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    try wStr(w, "websetId", params.webset_id, &first);
    if (!first) try w.writeByte(',');
    first = false;
    try w.writeAll("\"cadence\":{\"cron\":");
    try writeStr(w, params.cadence.cron);
    if (params.cadence.timezone) |tz| {
        try w.writeAll(",\"timezone\":");
        try writeStr(w, tz);
    }
    try w.writeByte('}');
    if (!first) try w.writeByte(',');
    try w.writeAll("\"behavior\":");
    try writeMonitorBehavior(w, params.behavior);
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeUpdateMonitor(allocator: std.mem.Allocator, params: types.UpdateMonitor) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    if (params.status) |s| try wStr(w, "status", s.toString(), &first);
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeCreateImportParameters(allocator: std.mem.Allocator, params: types.CreateImportParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    try wStr(w, "format", params.format.toString(), &first);
    if (!first) try w.writeByte(',');
    first = false;
    try w.writeAll("\"entity\":");
    try writeEntity(w, params.entity);
    if (params.size) |v| try wFloat(w, "size", v, &first);
    if (params.count) |v| try wFloat(w, "count", v, &first);
    if (params.title) |v| try wStr(w, "title", v, &first);
    if (params.csv) |csv| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"csv\":{");
        var cf = true;
        if (csv.identifier) |id| try wInt(w, "identifier", id, &cf);
        try w.writeByte('}');
    }
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeUpdateImport(allocator: std.mem.Allocator, params: types.UpdateImport) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    if (params.title) |v| try wStr(w, "title", v, &first);
    if (params.metadata) |v| try wJson(w, "metadata", v, &first);
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializePreviewWebsetParameters(allocator: std.mem.Allocator, params: types.PreviewWebsetParameters) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    try wStr(w, "query", params.query, &first);
    if (params.entity) |e| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"entity\":");
        try writeEntity(w, e);
    }
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

// ---------------------------------------------------------------------------
// Internal parse helpers
// ---------------------------------------------------------------------------

fn getStr(obj: std.json.ObjectMap, key: []const u8) ?[]const u8 {
    const v = obj.get(key) orelse return null;
    return switch (v) { .string => |s| s, else => null };
}

fn getInt(obj: std.json.ObjectMap, key: []const u8) ?i64 {
    const v = obj.get(key) orelse return null;
    return switch (v) {
        .integer => |n| n,
        .float => |f| @intFromFloat(f),
        else => null,
    };
}

fn getFloat(obj: std.json.ObjectMap, key: []const u8) ?f64 {
    const v = obj.get(key) orelse return null;
    return switch (v) {
        .float => |f| f,
        .integer => |n| @floatFromInt(n),
        .number_string => |s| std.fmt.parseFloat(f64, s) catch null,
        else => null,
    };
}

fn getBool(obj: std.json.ObjectMap, key: []const u8) ?bool {
    const v = obj.get(key) orelse return null;
    return switch (v) { .bool => |b| b, else => null };
}

fn ds(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) !?[]u8 {
    const s = getStr(obj, key) orelse return null;
    return try allocator.dupe(u8, s);
}

fn dsReq(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) ![]u8 {
    const s = getStr(obj, key) orelse return error.MissingField;
    return try allocator.dupe(u8, s);
}

fn parseProgress(obj: std.json.ObjectMap) types.Progress {
    return .{
        .found = getFloat(obj, "found") orelse 0.0,
        .completion = getFloat(obj, "completion") orelse 0.0,
    };
}

fn parseMonitorCadence(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.MonitorCadence {
    const cron = try dsReq(allocator, obj, "cron");
    const tz = try ds(allocator, obj, "timezone");
    return types.MonitorCadence{ .cron = cron, .timezone = tz };
}

fn parseMonitorBehavior(allocator: std.mem.Allocator, val: std.json.Value) !types.MonitorBehavior {
    const obj = switch (val) { .object => |o| o, else => return error.InvalidFormat };
    const type_str = getStr(obj, "type") orelse "search";
    if (std.mem.eql(u8, type_str, "search")) {
        var config = types.MonitorBehaviorSearchConfig{ .count = 10 };
        if (obj.get("config")) |cv| {
            if (cv == .object) {
                const co = cv.object;
                config.query = try ds(allocator, co, "query");
                config.count = getInt(co, "count") orelse 10;
                if (co.get("entity")) |ev| config.entity = try parseEntityValue(allocator, ev);
                if (co.get("criteria")) |cv2| {
                    if (cv2 == .array) {
                        var list = std.ArrayList(types.SearchCriterion).init(allocator);
                        for (cv2.array.items) |item| {
                            if (item != .object) continue;
                            const desc = try dsReq(allocator, item.object, "description");
                            try list.append(.{ .description = desc });
                        }
                        config.criteria = try list.toOwnedSlice();
                    }
                }
                if (getStr(co, "behavior")) |b| config.behavior = types.WebsetSearchBehavior.fromString(b) orelse .append;
            }
        }
        return .{ .search = .{ .config = config } };
    } else {
        var target: types.MonitorBehaviorRefreshTarget = .{ .contents = {} };
        if (obj.get("config")) |cv| {
            if (cv == .object) {
                const co = cv.object;
                const t = getStr(co, "type") orelse "contents";
                if (std.mem.eql(u8, t, "enrichments")) {
                    var ids: ?[][]const u8 = null;
                    if (co.get("ids")) |iv| {
                        if (iv == .array) {
                            var id_list = std.ArrayList([]const u8).init(allocator);
                            for (iv.array.items) |id| {
                                if (id == .string) try id_list.append(try allocator.dupe(u8, id.string));
                            }
                            ids = try id_list.toOwnedSlice();
                        }
                    }
                    target = .{ .enrichments = .{ .ids = ids } };
                } else {
                    target = .{ .contents = {} };
                }
            }
        }
        return .{ .refresh = .{ .config = target } };
    }
}

fn parseEntityValue(allocator: std.mem.Allocator, val: std.json.Value) !types.WebsetEntity {
    switch (val) {
        .string => |s| {
            if (std.mem.eql(u8, s, "company")) return .company;
            if (std.mem.eql(u8, s, "person")) return .person;
            if (std.mem.eql(u8, s, "article")) return .article;
            if (std.mem.eql(u8, s, "research_paper")) return .research_paper;
            return .{ .custom = .{ .description = try allocator.dupe(u8, s) } };
        },
        .object => |o| {
            const t = getStr(o, "type") orelse "";
            if (std.mem.eql(u8, t, "company")) return .company;
            if (std.mem.eql(u8, t, "person")) return .person;
            if (std.mem.eql(u8, t, "article")) return .article;
            if (std.mem.eql(u8, t, "research_paper")) return .research_paper;
            const desc = getStr(o, "description") orelse "";
            const owned_desc = try allocator.dupe(u8, desc);
            return .{ .custom = .{ .description = owned_desc } };
        },
        else => return .{ .custom = .{ .description = try allocator.dupe(u8, "") } },
    }
}

fn parseWebsetSearchInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.WebsetSearch {
    const id = try dsReq(allocator, obj, "id");
    errdefer allocator.free(id);
    const object_str = try dsReq(allocator, obj, "object");
    errdefer allocator.free(object_str);
    const webset_id = try dsReq(allocator, obj, "websetId");
    errdefer allocator.free(webset_id);
    const status_str = getStr(obj, "status") orelse "created";
    const status = types.WebsetSearchStatus.fromString(status_str) orelse .created;
    const query = try dsReq(allocator, obj, "query");
    errdefer allocator.free(query);
    const count = getInt(obj, "count") orelse 10;

    var entity: ?types.WebsetEntity = null;
    if (obj.get("entity")) |ev| {
        if (ev != .null) entity = try parseEntityValue(allocator, ev);
    }

    var criteria = std.ArrayList(types.WebsetSearchCriterion).init(allocator);
    errdefer {
        for (criteria.items) |c| allocator.free(c.description);
        criteria.deinit();
    }
    if (obj.get("criteria")) |cv| {
        if (cv == .array) {
            for (cv.array.items) |item| {
                if (item != .object) continue;
                const desc = try dsReq(allocator, item.object, "description");
                const sr = getFloat(item.object, "successRate") orelse 0.0;
                try criteria.append(.{ .description = desc, .success_rate = sr });
            }
        }
    }

    const behavior_str = getStr(obj, "behavior");
    const behavior = if (behavior_str) |b| types.WebsetSearchBehavior.fromString(b) else null;

    var exclude: ?[]types.ExcludeItem = null;
    if (obj.get("exclude")) |ev| {
        if (ev == .array) {
            var list = std.ArrayList(types.ExcludeItem).init(allocator);
            for (ev.array.items) |item| {
                if (item != .object) continue;
                const src_str = getStr(item.object, "source") orelse "import";
                const src = types.ImportSource.fromString(src_str) orelse .import_;
                const eid = try dsReq(allocator, item.object, "id");
                try list.append(.{ .source = src, .id = eid });
            }
            exclude = try list.toOwnedSlice();
        }
    }

    var scope: ?[]types.ScopeItem = null;
    if (obj.get("scope")) |sv| {
        if (sv == .array) {
            var list = std.ArrayList(types.ScopeItem).init(allocator);
            for (sv.array.items) |item| {
                if (item != .object) continue;
                const src_str = getStr(item.object, "source") orelse "webset";
                const src = types.ScopeSourceType.fromString(src_str) orelse .webset;
                const sid = try dsReq(allocator, item.object, "id");
                var rel: ?types.ScopeRelationship = null;
                if (item.object.get("relationship")) |rv| {
                    if (rv == .object) {
                        const def = try dsReq(allocator, rv.object, "definition");
                        rel = .{ .definition = def, .limit = if (getInt(rv.object, "limit")) |l| @intCast(l) else null };
                    }
                }
                try list.append(.{ .source = src, .id = sid, .relationship = rel });
            }
            scope = try list.toOwnedSlice();
        }
    }

    var progress = types.Progress{ .found = 0, .completion = 0 };
    if (obj.get("progress")) |pv| {
        if (pv == .object) progress = parseProgress(pv.object);
    }

    var recall: ?types.WebsetSearchRecall = null;
    if (obj.get("recall")) |rv| {
        if (rv == .object) {
            const ro = rv.object;
            var expected = types.WebsetSearchRecallExpected{ .total = 0, .confidence = "" };
            if (ro.get("expected")) |ev| {
                if (ev == .object) {
                    expected.total = getInt(ev.object, "total") orelse 0;
                    expected.confidence = try dsReq(allocator, ev.object, "confidence");
                }
            }
            const reasoning = try dsReq(allocator, ro, "reasoning");
            recall = .{ .expected = expected, .reasoning = reasoning };
        }
    }

    var metadata: ?std.json.Value = null;
    if (obj.get("metadata")) |mv| {
        if (mv != .null) metadata = try utils.cloneValue(allocator, mv);
    }

    return types.WebsetSearch{
        .id = id,
        .object = object_str,
        .webset_id = webset_id,
        .status = status,
        .query = query,
        .entity = entity,
        .criteria = try criteria.toOwnedSlice(),
        .count = count,
        .behavior = behavior,
        .exclude = exclude,
        .scope = scope,
        .progress = progress,
        .recall = recall,
        .metadata = metadata,
        .canceled_at = try ds(allocator, obj, "canceledAt"),
        .canceled_reason = try ds(allocator, obj, "canceledReason"),
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseEnrichmentResultInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.EnrichmentResult {
    const object_str = try dsReq(allocator, obj, "object");
    const fmt_str = getStr(obj, "format") orelse "text";
    const fmt = types.EnrichmentFormat.fromString(fmt_str) orelse .text;
    const enrichment_id = try dsReq(allocator, obj, "enrichmentId");
    const reasoning = try ds(allocator, obj, "reasoning");

    var result: ?[][]const u8 = null;
    if (obj.get("result")) |rv| {
        if (rv == .array) {
            var list = std.ArrayList([]u8).init(allocator);
            for (rv.array.items) |item| {
                if (item == .string) try list.append(try allocator.dupe(u8, item.string));
            }
            result = @ptrCast(try list.toOwnedSlice());
        }
    }

    var refs = std.ArrayList(types.Reference).init(allocator);
    if (obj.get("references")) |rv| {
        if (rv == .array) {
            for (rv.array.items) |item| {
                if (item != .object) continue;
                const ro = item.object;
                const url = try dsReq(allocator, ro, "url");
                const title = try ds(allocator, ro, "title");
                const snippet = try ds(allocator, ro, "snippet");
                try refs.append(.{ .url = url, .title = title, .snippet = snippet });
            }
        }
    }

    return types.EnrichmentResult{
        .object = object_str,
        .format = fmt,
        .result = result,
        .reasoning = reasoning,
        .references = try refs.toOwnedSlice(),
        .enrichment_id = enrichment_id,
    };
}

fn parseWebsetEnrichmentInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.WebsetEnrichment {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const status_str = getStr(obj, "status") orelse "pending";
    const status = types.WebsetEnrichmentStatus.fromString(status_str) orelse .pending;
    const webset_id = try dsReq(allocator, obj, "websetId");
    const title = try ds(allocator, obj, "title");
    const description = try dsReq(allocator, obj, "description");
    const fmt_str = getStr(obj, "format");
    const format = if (fmt_str) |f| types.EnrichmentFormat.fromString(f) else null;
    const instructions = try ds(allocator, obj, "instructions");

    var options: ?[]types.WebsetEnrichmentOption = null;
    if (obj.get("options")) |ov| {
        if (ov == .array) {
            var list = std.ArrayList(types.WebsetEnrichmentOption).init(allocator);
            for (ov.array.items) |item| {
                if (item != .object) continue;
                const label = try dsReq(allocator, item.object, "label");
                try list.append(.{ .label = label });
            }
            options = try list.toOwnedSlice();
        }
    }

    var metadata: ?std.json.Value = null;
    if (obj.get("metadata")) |mv| {
        if (mv != .null) metadata = try utils.cloneValue(allocator, mv);
    }

    return types.WebsetEnrichment{
        .id = id,
        .object = object_str,
        .status = status,
        .webset_id = webset_id,
        .title = title,
        .description = description,
        .format = format,
        .options = options,
        .instructions = instructions,
        .metadata = metadata,
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseMonitorRunInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.MonitorRun {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const status_str = getStr(obj, "status") orelse "created";
    const status = types.MonitorRunStatus.fromString(status_str) orelse .created;
    const monitor_id = try dsReq(allocator, obj, "monitorId");
    const type_str = getStr(obj, "type") orelse "search";
    const run_type = types.MonitorRunType.fromString(type_str) orelse .search;
    return types.MonitorRun{
        .id = id,
        .object = object_str,
        .status = status,
        .monitor_id = monitor_id,
        .type = run_type,
        .completed_at = try ds(allocator, obj, "completedAt"),
        .failed_at = try ds(allocator, obj, "failedAt"),
        .canceled_at = try ds(allocator, obj, "canceledAt"),
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseMonitorInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.Monitor {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const status_str = getStr(obj, "status") orelse "enabled";
    const status = types.MonitorStatus.fromString(status_str) orelse .enabled;
    const webset_id = try dsReq(allocator, obj, "websetId");

    var cadence = types.MonitorCadence{ .cron = "", .timezone = null };
    if (obj.get("cadence")) |cv| {
        if (cv == .object) cadence = try parseMonitorCadence(allocator, cv.object);
    }

    var behavior = types.MonitorBehavior{ .search = .{ .config = .{ .count = 10 } } };
    if (obj.get("behavior")) |bv| {
        behavior = try parseMonitorBehavior(allocator, bv);
    }

    var last_run: ?types.MonitorRun = null;
    if (obj.get("lastRun")) |lrv| {
        if (lrv == .object) last_run = try parseMonitorRunInternal(allocator, lrv.object);
    }

    var metadata: std.json.Value = .null;
    if (obj.get("metadata")) |mv| {
        metadata = try utils.cloneValue(allocator, mv);
    }

    return types.Monitor{
        .id = id,
        .object = object_str,
        .status = status,
        .webset_id = webset_id,
        .cadence = cadence,
        .behavior = behavior,
        .last_run = last_run,
        .next_run_at = try ds(allocator, obj, "nextRunAt"),
        .metadata = metadata,
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseWebsetItemPropertiesInternal(allocator: std.mem.Allocator, entity_type: []const u8, obj: std.json.ObjectMap) !types.WebsetItemProperties {
    const url = try dsReq(allocator, obj, "url");
    const description = try dsReq(allocator, obj, "description");
    const content = try ds(allocator, obj, "content");

    if (std.mem.eql(u8, entity_type, "person")) {
        return .{ .person = .{
            .url = url,
            .description = description,
            .content = content,
            .name = try ds(allocator, obj, "name"),
            .location = try ds(allocator, obj, "location"),
        } };
    } else if (std.mem.eql(u8, entity_type, "company")) {
        return .{ .company = .{
            .url = url,
            .description = description,
            .content = content,
            .name = try ds(allocator, obj, "name"),
            .industry = try ds(allocator, obj, "industry"),
        } };
    } else if (std.mem.eql(u8, entity_type, "article")) {
        return .{ .article = .{
            .url = url,
            .description = description,
            .content = content,
            .title = try ds(allocator, obj, "title"),
            .published_date = try ds(allocator, obj, "publishedDate"),
        } };
    } else if (std.mem.eql(u8, entity_type, "research_paper")) {
        var authors: ?[][]const u8 = null;
        if (obj.get("authors")) |av| {
            if (av == .array) {
                var list = std.ArrayList([]u8).init(allocator);
                for (av.array.items) |a| {
                    if (a == .string) try list.append(try allocator.dupe(u8, a.string));
                }
                authors = @ptrCast(try list.toOwnedSlice());
            }
        }
        return .{ .research_paper = .{
            .url = url,
            .description = description,
            .content = content,
            .title = try ds(allocator, obj, "title"),
            .authors = authors,
        } };
    } else {
        return .{ .custom = .{ .url = url, .description = description, .content = content } };
    }
}

fn parseWebsetItemInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.WebsetItem {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const source_str = getStr(obj, "source") orelse "search";
    const source = types.Source.fromString(source_str) orelse .search;
    const source_id = try dsReq(allocator, obj, "sourceId");
    const webset_id = try dsReq(allocator, obj, "websetId");
    const entity_type = getStr(obj, "entityType") orelse "custom";

    var properties = types.WebsetItemProperties{ .custom = .{ .url = "", .description = "", .content = null } };
    if (obj.get("properties")) |pv| {
        if (pv == .object) {
            properties = try parseWebsetItemPropertiesInternal(allocator, entity_type, pv.object);
        }
    }

    var evaluations = std.ArrayList(types.WebsetItemEvaluation).init(allocator);
    if (obj.get("evaluations")) |ev| {
        if (ev == .array) {
            for (ev.array.items) |item| {
                if (item != .object) continue;
                const eo = item.object;
                const criterion = try dsReq(allocator, eo, "criterion");
                const reasoning = try dsReq(allocator, eo, "reasoning");
                const sat_str = getStr(eo, "satisfied") orelse "unclear";
                const satisfied = types.Satisfied.fromString(sat_str) orelse .unclear;
                var refs: ?[]types.Reference = null;
                if (eo.get("references")) |rv| {
                    if (rv == .array) {
                        var rlist = std.ArrayList(types.Reference).init(allocator);
                        for (rv.array.items) |ri| {
                            if (ri != .object) continue;
                            const ro = ri.object;
                            const rurl = try dsReq(allocator, ro, "url");
                            const rtitle = try ds(allocator, ro, "title");
                            const rsnippet = try ds(allocator, ro, "snippet");
                            try rlist.append(.{ .url = rurl, .title = rtitle, .snippet = rsnippet });
                        }
                        refs = try rlist.toOwnedSlice();
                    }
                }
                try evaluations.append(.{ .criterion = criterion, .reasoning = reasoning, .satisfied = satisfied, .references = refs });
            }
        }
    }

    var enrichments = std.ArrayList(types.EnrichmentResult).init(allocator);
    if (obj.get("enrichments")) |ev| {
        if (ev == .array) {
            for (ev.array.items) |item| {
                if (item != .object) continue;
                try enrichments.append(try parseEnrichmentResultInternal(allocator, item.object));
            }
        }
    }

    return types.WebsetItem{
        .id = id,
        .object = object_str,
        .source = source,
        .source_id = source_id,
        .webset_id = webset_id,
        .properties = properties,
        .evaluations = try evaluations.toOwnedSlice(),
        .enrichments = try enrichments.toOwnedSlice(),
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseWebsetInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.Webset {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const status_str = getStr(obj, "status") orelse "idle";
    const status = types.WebsetStatus.fromString(status_str) orelse .idle;
    const dashboard_url = try dsReq(allocator, obj, "dashboardUrl");
    const title = try ds(allocator, obj, "title");
    const external_id = try ds(allocator, obj, "externalId");

    var searches = std.ArrayList(types.WebsetSearch).init(allocator);
    if (obj.get("searches")) |sv| {
        if (sv == .array) {
            for (sv.array.items) |item| {
                if (item != .object) continue;
                try searches.append(try parseWebsetSearchInternal(allocator, item.object));
            }
        }
    }

    var enrichments = std.ArrayList(types.WebsetEnrichment).init(allocator);
    if (obj.get("enrichments")) |ev| {
        if (ev == .array) {
            for (ev.array.items) |item| {
                if (item != .object) continue;
                try enrichments.append(try parseWebsetEnrichmentInternal(allocator, item.object));
            }
        }
    }

    var monitors = std.ArrayList(types.Monitor).init(allocator);
    if (obj.get("monitors")) |mv| {
        if (mv == .array) {
            for (mv.array.items) |item| {
                if (item != .object) continue;
                try monitors.append(try parseMonitorInternal(allocator, item.object));
            }
        }
    }

    var metadata: ?std.json.Value = null;
    if (obj.get("metadata")) |mv| {
        if (mv != .null) metadata = try utils.cloneValue(allocator, mv);
    }

    return types.Webset{
        .id = id,
        .object = object_str,
        .status = status,
        .dashboard_url = dashboard_url,
        .title = title,
        .external_id = external_id,
        .searches = try searches.toOwnedSlice(),
        .enrichments = try enrichments.toOwnedSlice(),
        .monitors = try monitors.toOwnedSlice(),
        .metadata = metadata,
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseImportInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.Import {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const status_str = getStr(obj, "status") orelse "pending";
    const status = types.ImportStatus.fromString(status_str) orelse .pending;
    const fmt_str = getStr(obj, "format") orelse "csv";
    const format = types.ImportFormat.fromString(fmt_str) orelse .csv;

    var entity: ?types.WebsetEntity = null;
    if (obj.get("entity")) |ev| {
        if (ev != .null) entity = try parseEntityValue(allocator, ev);
    }

    const title = try dsReq(allocator, obj, "title");
    const count = getFloat(obj, "count") orelse 0.0;

    var metadata: std.json.Value = .null;
    if (obj.get("metadata")) |mv| {
        metadata = try utils.cloneValue(allocator, mv);
    }

    const failed_reason_str = getStr(obj, "failedReason");
    const failed_reason = if (failed_reason_str) |s| types.ImportFailedReason.fromString(s) else null;

    return types.Import{
        .id = id,
        .object = object_str,
        .status = status,
        .format = format,
        .entity = entity,
        .title = title,
        .count = count,
        .metadata = metadata,
        .failed_reason = failed_reason,
        .failed_at = try ds(allocator, obj, "failedAt"),
        .failed_message = try ds(allocator, obj, "failedMessage"),
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

fn parseWebhookInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.Webhook {
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const status_str = getStr(obj, "status") orelse "active";
    const status = types.WebhookStatus.fromString(status_str) orelse .active;
    const url = try dsReq(allocator, obj, "url");
    const secret = try ds(allocator, obj, "secret");

    var events = std.ArrayList(types.EventType).init(allocator);
    if (obj.get("events")) |ev| {
        if (ev == .array) {
            for (ev.array.items) |item| {
                if (item == .string) {
                    if (types.EventType.fromString(item.string)) |et| try events.append(et);
                }
            }
        }
    }

    var metadata: ?std.json.Value = null;
    if (obj.get("metadata")) |mv| {
        if (mv != .null) metadata = try utils.cloneValue(allocator, mv);
    }

    return types.Webhook{
        .id = id,
        .object = object_str,
        .status = status,
        .events = try events.toOwnedSlice(),
        .url = url,
        .secret = secret,
        .metadata = metadata,
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

// ---------------------------------------------------------------------------
// Public Parsers
// ---------------------------------------------------------------------------

pub fn parseWebset(allocator: std.mem.Allocator, json_bytes: []const u8) !types.Webset {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseWebsetInternal(allocator, obj);
}

pub fn parseGetWebsetResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.GetWebsetResponse {
    return parseWebset(allocator, json_bytes);
}

pub fn parseListWebsetsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListWebsetsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.Webset).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseWebsetInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListWebsetsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseWebsetItem(allocator: std.mem.Allocator, json_bytes: []const u8) !types.WebsetItem {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseWebsetItemInternal(allocator, obj);
}

pub fn parseListWebsetItemResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListWebsetItemResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.WebsetItem).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseWebsetItemInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListWebsetItemResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseWebsetSearch(allocator: std.mem.Allocator, json_bytes: []const u8) !types.WebsetSearch {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseWebsetSearchInternal(allocator, obj);
}

pub fn parseListWebsetSearchesResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListWebsetSearchesResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.WebsetSearch).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseWebsetSearchInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListWebsetSearchesResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseWebsetEnrichment(allocator: std.mem.Allocator, json_bytes: []const u8) !types.WebsetEnrichment {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseWebsetEnrichmentInternal(allocator, obj);
}

pub fn parseListWebsetEnrichmentsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListWebsetEnrichmentsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.WebsetEnrichment).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseWebsetEnrichmentInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListWebsetEnrichmentsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseWebhook(allocator: std.mem.Allocator, json_bytes: []const u8) !types.Webhook {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseWebhookInternal(allocator, obj);
}

pub fn parseListWebhooksResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListWebhooksResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.Webhook).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseWebhookInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListWebhooksResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseWebhookAttempt(allocator: std.mem.Allocator, json_bytes: []const u8) !types.WebhookAttempt {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const event_id = try dsReq(allocator, obj, "eventId");
    const event_type_str = getStr(obj, "eventType") orelse "webset.created";
    const event_type = types.EventType.fromString(event_type_str) orelse .webset_created;
    const webhook_id = try dsReq(allocator, obj, "webhookId");
    const url = try dsReq(allocator, obj, "url");
    const successful = getBool(obj, "successful") orelse false;
    var response_headers: std.json.Value = .null;
    if (obj.get("responseHeaders")) |rv| {
        response_headers = try utils.cloneValue(allocator, rv);
    }
    const response_body = try ds(allocator, obj, "responseBody");
    const response_status_code = getFloat(obj, "responseStatusCode") orelse 0.0;
    const attempt = getFloat(obj, "attempt") orelse 0.0;
    const attempted_at = try dsReq(allocator, obj, "attemptedAt");
    return types.WebhookAttempt{
        .id = id, .object = object_str, .event_id = event_id, .event_type = event_type,
        .webhook_id = webhook_id, .url = url, .successful = successful,
        .response_headers = response_headers, .response_body = response_body,
        .response_status_code = response_status_code, .attempt = attempt, .attempted_at = attempted_at,
    };
}

pub fn parseListWebhookAttemptsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListWebhookAttemptsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.WebhookAttempt).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |it| {
                const item_bytes = try std.json.stringifyAlloc(allocator, it, .{});
                defer allocator.free(item_bytes);
                try list.append(try parseWebhookAttempt(allocator, item_bytes));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListWebhookAttemptsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseMonitor(allocator: std.mem.Allocator, json_bytes: []const u8) !types.Monitor {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseMonitorInternal(allocator, obj);
}

pub fn parseListMonitorsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListMonitorsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.Monitor).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseMonitorInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListMonitorsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseMonitorRun(allocator: std.mem.Allocator, json_bytes: []const u8) !types.MonitorRun {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseMonitorRunInternal(allocator, obj);
}

pub fn parseListMonitorRunsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListMonitorRunsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.MonitorRun).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseMonitorRunInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListMonitorRunsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseImport(allocator: std.mem.Allocator, json_bytes: []const u8) !types.Import {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseImportInternal(allocator, obj);
}

pub fn parseCreateImportResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.CreateImportResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    const base = try parseImportInternal(allocator, obj);
    const upload_url = try dsReq(allocator, obj, "uploadUrl");
    const upload_valid_until = try dsReq(allocator, obj, "uploadValidUntil");
    return types.CreateImportResponse{
        .id = base.id, .object = base.object, .status = base.status, .format = base.format,
        .entity = base.entity, .title = base.title, .count = base.count, .metadata = base.metadata,
        .failed_reason = base.failed_reason, .failed_at = base.failed_at, .failed_message = base.failed_message,
        .upload_url = upload_url, .upload_valid_until = upload_valid_until,
        .created_at = base.created_at, .updated_at = base.updated_at,
    };
}

pub fn parseListImportsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListImportsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.Import).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseImportInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListImportsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parsePreviewWebsetResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.PreviewWebsetResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };

    var search_entity: types.WebsetEntity = .company;
    var search_criteria = std.ArrayList(types.PreviewWebsetResponseSearchCriterion).init(allocator);
    if (obj.get("search")) |sv| {
        if (sv == .object) {
            const so = sv.object;
            if (so.get("entity")) |ev| search_entity = try parseEntityValue(allocator, ev);
            if (so.get("criteria")) |cv| {
                if (cv == .array) {
                    for (cv.array.items) |item| {
                        if (item != .object) continue;
                        const desc = try dsReq(allocator, item.object, "description");
                        try search_criteria.append(.{ .description = desc });
                    }
                }
            }
        }
    }

    var enrichments = std.ArrayList(types.PreviewWebsetResponseEnrichment).init(allocator);
    if (obj.get("enrichments")) |ev| {
        if (ev == .array) {
            for (ev.array.items) |item| {
                if (item != .object) continue;
                const eo = item.object;
                const desc = try dsReq(allocator, eo, "description");
                const fmt_str = getStr(eo, "format") orelse "text";
                const fmt = types.EnrichmentFormat.fromString(fmt_str) orelse .text;
                var opts: ?[]types.Option = null;
                if (eo.get("options")) |ov| {
                    if (ov == .array) {
                        var olist = std.ArrayList(types.Option).init(allocator);
                        for (ov.array.items) |opt| {
                            if (opt != .object) continue;
                            const label = try dsReq(allocator, opt.object, "label");
                            try olist.append(.{ .label = label });
                        }
                        opts = try olist.toOwnedSlice();
                    }
                }
                try enrichments.append(.{ .description = desc, .format = fmt, .options = opts });
            }
        }
    }

    return types.PreviewWebsetResponse{
        .search = .{ .entity = search_entity, .criteria = try search_criteria.toOwnedSlice() },
        .enrichments = try enrichments.toOwnedSlice(),
    };
}

pub fn parseWebsetEvent(allocator: std.mem.Allocator, json_bytes: []const u8) !types.WebsetEvent {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    const type_str = getStr(obj, "type") orelse return error.MissingEventType;
    const id = try dsReq(allocator, obj, "id");
    const object_str = try dsReq(allocator, obj, "object");
    const created_at = try dsReq(allocator, obj, "createdAt");
    const type_owned = try allocator.dupe(u8, type_str);

    if (std.mem.eql(u8, type_str, "webset.created") or
        std.mem.eql(u8, type_str, "webset.deleted") or
        std.mem.eql(u8, type_str, "webset.idle") or
        std.mem.eql(u8, type_str, "webset.paused"))
    {
        var data_webset: types.Webset = undefined;
        if (obj.get("data")) |dv| {
            if (dv == .object) data_webset = try parseWebsetInternal(allocator, dv.object);
        }
        const ev = types.WebsetCreatedEvent{ .id = id, .object = object_str, .type = type_owned, .created_at = created_at, .data = data_webset };
        if (std.mem.eql(u8, type_str, "webset.created")) return .{ .webset_created = ev };
        if (std.mem.eql(u8, type_str, "webset.deleted")) return .{ .webset_deleted = ev };
        if (std.mem.eql(u8, type_str, "webset.idle")) return .{ .webset_idle = ev };
        return .{ .webset_paused = ev };
    }

    if (std.mem.eql(u8, type_str, "webset.item.created") or std.mem.eql(u8, type_str, "webset.item.enriched")) {
        var data_item: types.WebsetItem = undefined;
        if (obj.get("data")) |dv| {
            if (dv == .object) data_item = try parseWebsetItemInternal(allocator, dv.object);
        }
        const ev = types.WebsetItemCreatedEvent{ .id = id, .object = object_str, .type = type_owned, .created_at = created_at, .data = data_item };
        if (std.mem.eql(u8, type_str, "webset.item.created")) return .{ .webset_item_created = ev };
        return .{ .webset_item_enriched = ev };
    }

    if (std.mem.startsWith(u8, type_str, "webset.search.")) {
        var data_search: types.WebsetSearch = undefined;
        if (obj.get("data")) |dv| {
            if (dv == .object) data_search = try parseWebsetSearchInternal(allocator, dv.object);
        }
        const ev = types.WebsetSearchCreatedEvent{ .id = id, .object = object_str, .type = type_owned, .created_at = created_at, .data = data_search };
        if (std.mem.eql(u8, type_str, "webset.search.created")) return .{ .webset_search_created = ev };
        if (std.mem.eql(u8, type_str, "webset.search.updated")) return .{ .webset_search_updated = ev };
        if (std.mem.eql(u8, type_str, "webset.search.canceled")) return .{ .webset_search_canceled = ev };
        return .{ .webset_search_completed = ev };
    }

    if (std.mem.startsWith(u8, type_str, "import.")) {
        var data_import: types.Import = undefined;
        if (obj.get("data")) |dv| {
            if (dv == .object) data_import = try parseImportInternal(allocator, dv.object);
        }
        const ev = types.ImportCreatedEvent{ .id = id, .object = object_str, .type = type_owned, .created_at = created_at, .data = data_import };
        if (std.mem.eql(u8, type_str, "import.created")) return .{ .import_created = ev };
        return .{ .import_completed = ev };
    }

    if (std.mem.startsWith(u8, type_str, "monitor.run.")) {
        var data_run: types.MonitorRun = undefined;
        if (obj.get("data")) |dv| {
            if (dv == .object) data_run = try parseMonitorRunInternal(allocator, dv.object);
        }
        const ev = types.MonitorRunCreatedEvent{ .id = id, .object = object_str, .type = type_owned, .created_at = created_at, .data = data_run };
        if (std.mem.eql(u8, type_str, "monitor.run.created")) return .{ .monitor_run_created = ev };
        return .{ .monitor_run_completed = ev };
    }

    // monitor.created / monitor.updated / monitor.deleted
    var data_monitor: types.Monitor = undefined;
    if (obj.get("data")) |dv| {
        if (dv == .object) data_monitor = try parseMonitorInternal(allocator, dv.object);
    }
    const ev = types.MonitorCreatedEvent{ .id = id, .object = object_str, .type = type_owned, .created_at = created_at, .data = data_monitor };
    if (std.mem.eql(u8, type_str, "monitor.created")) return .{ .monitor_created = ev };
    if (std.mem.eql(u8, type_str, "monitor.updated")) return .{ .monitor_updated = ev };
    return .{ .monitor_deleted = ev };
}

pub fn parseListEventsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListEventsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.WebsetEvent).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                const item_bytes = try std.json.stringifyAlloc(allocator, item, .{});
                defer allocator.free(item_bytes);
                try list.append(try parseWebsetEvent(allocator, item_bytes));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListEventsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}
