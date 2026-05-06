/// JSON serialization and deserialization for the Search Monitors subsystem.
const std = @import("std");
const types = @import("types.zig");
const utils = @import("../utils.zig");

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

fn writeContentsOptions(writer: anytype, contents: types.SearchMonitorContents) !void {
    try writer.writeByte('{');
    var first = true;

    if (contents.text) |t| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"text\":");
        switch (t) {
            .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
            .options => |o| {
                try writer.writeByte('{');
                var of = true;
                if (o.max_characters) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.print("\"maxCharacters\":{d}", .{v});
                }
                if (o.include_html_tags) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.print("\"includeHtmlTags\":{s}", .{if (v) "true" else "false"});
                }
                if (o.verbosity) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.writeAll("\"verbosity\":");
                    try writeStr(writer, v);
                }
                if (o.include_sections) |ss| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.writeAll("\"includeSections\":[");
                    for (ss, 0..) |s, i| {
                        if (i > 0) try writer.writeByte(',');
                        try writeStr(writer, s);
                    }
                    try writer.writeByte(']');
                }
                if (o.exclude_sections) |ss| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.writeAll("\"excludeSections\":[");
                    for (ss, 0..) |s, i| {
                        if (i > 0) try writer.writeByte(',');
                        try writeStr(writer, s);
                    }
                    try writer.writeByte(']');
                }
                try writer.writeByte('}');
            },
        }
    }

    if (contents.highlights) |h| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"highlights\":");
        switch (h) {
            .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
            .options => |o| {
                try writer.writeByte('{');
                var of = true;
                if (o.query) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.writeAll("\"query\":");
                    try writeStr(writer, v);
                }
                if (o.max_characters) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.print("\"maxCharacters\":{d}", .{v});
                }
                if (o.num_sentences) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.print("\"numSentences\":{d}", .{v});
                }
                if (o.highlights_per_url) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.print("\"highlightsPerUrl\":{d}", .{v});
                }
                try writer.writeByte('}');
            },
        }
    }

    if (contents.summary) |s| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"summary\":");
        switch (s) {
            .enabled => |b| try writer.writeAll(if (b) "true" else "false"),
            .options => |o| {
                try writer.writeByte('{');
                var of = true;
                if (o.query) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.writeAll("\"query\":");
                    try writeStr(writer, v);
                }
                if (o.schema) |v| {
                    if (!of) try writer.writeByte(',');
                    of = false;
                    try writer.writeAll("\"$schema\":");
                    try writeJsonValue(writer, v);
                }
                try writer.writeByte('}');
            },
        }
    }

    if (contents.extras) |e| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"extras\":{");
        var ef = true;
        if (e.links) |v| {
            if (!ef) try writer.writeByte(',');
            ef = false;
            try writer.print("\"links\":{d}", .{v});
        }
        if (e.image_links) |v| {
            if (!ef) try writer.writeByte(',');
            ef = false;
            try writer.print("\"imageLinks\":{d}", .{v});
        }
        try writer.writeByte('}');
    }

    if (contents.livecrawl) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"livecrawl\":");
        try writeStr(writer, v);
    }
    if (contents.livecrawl_timeout) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.print("\"livecrawlTimeout\":{d}", .{v});
    }
    if (contents.max_age_hours) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.print("\"maxAgeHours\":{d}", .{v});
    }
    if (contents.filter_empty_results) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.print("\"filterEmptyResults\":{s}", .{if (v) "true" else "false"});
    }
    if (contents.subpages) |v| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.print("\"subpages\":{d}", .{v});
    }
    if (contents.subpage_target) |st| {
        if (!first) try writer.writeByte(',');
        first = false;
        try writer.writeAll("\"subpageTarget\":");
        switch (st) {
            .single => |s| try writeStr(writer, s),
            .multiple => |arr| {
                try writer.writeByte('[');
                for (arr, 0..) |s, i| {
                    if (i > 0) try writer.writeByte(',');
                    try writeStr(writer, s);
                }
                try writer.writeByte(']');
            },
        }
    }

    try writer.writeByte('}');
}

fn writeSearchParams(writer: anytype, search: types.SearchMonitorSearch, first: *bool) !void {
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writer.writeAll("\"search\":{");
    var sf = true;
    if (!sf) try writer.writeByte(',');
    sf = false;
    try writer.writeAll("\"query\":");
    try writeStr(writer, search.query);
    if (search.num_results) |v| {
        if (!sf) try writer.writeByte(',');
        sf = false;
        try writer.print("\"numResults\":{d}", .{v});
    }
    if (search.include_domains) |ds_arr| {
        if (!sf) try writer.writeByte(',');
        sf = false;
        try writer.writeAll("\"includeDomains\":[");
        for (ds_arr, 0..) |d, i| {
            if (i > 0) try writer.writeByte(',');
            try writeStr(writer, d);
        }
        try writer.writeByte(']');
    }
    if (search.exclude_domains) |ds_arr| {
        if (!sf) try writer.writeByte(',');
        sf = false;
        try writer.writeAll("\"excludeDomains\":[");
        for (ds_arr, 0..) |d, i| {
            if (i > 0) try writer.writeByte(',');
            try writeStr(writer, d);
        }
        try writer.writeByte(']');
    }
    if (search.contents) |c| {
        if (!sf) try writer.writeByte(',');
        sf = false;
        try writer.writeAll("\"contents\":");
        try writeContentsOptions(writer, c);
    }
    try writer.writeByte('}');
}

fn serializeMonitorParamsCommon(
    writer: anytype,
    first: *bool,
    name: ?[]const u8,
    search: types.SearchMonitorSearch,
    trigger: ?types.SearchMonitorTrigger,
    output_schema: ?std.json.Value,
    metadata: ?std.json.Value,
    webhook: types.SearchMonitorWebhook,
) !void {
    if (name) |v| {
        if (!first.*) try writer.writeByte(',');
        first.* = false;
        try writer.writeAll("\"name\":");
        try writeStr(writer, v);
    }
    try writeSearchParams(writer, search, first);

    if (trigger) |t| {
        if (!first.*) try writer.writeByte(',');
        first.* = false;
        try writer.writeAll("\"trigger\":{\"type\":\"interval\",\"period\":");
        try writeStr(writer, t.period);
        try writer.writeByte('}');
    }
    if (output_schema) |schema| {
        if (!first.*) try writer.writeByte(',');
        first.* = false;
        try writer.writeAll("\"outputSchema\":");
        try writeJsonValue(writer, schema);
    }
    if (metadata) |m| {
        if (!first.*) try writer.writeByte(',');
        first.* = false;
        try writer.writeAll("\"metadata\":");
        try writeJsonValue(writer, m);
    }
    if (!first.*) try writer.writeByte(',');
    first.* = false;
    try writer.writeAll("\"webhook\":{\"url\":");
    try writeStr(writer, webhook.url);
    if (webhook.events) |evts| {
        try writer.writeAll(",\"events\":[");
        for (evts, 0..) |e, i| {
            if (i > 0) try writer.writeByte(',');
            try writeStr(writer, e.toString());
        }
        try writer.writeByte(']');
    }
    try writer.writeByte('}');
}

pub fn serializeCreateSearchMonitorParams(allocator: std.mem.Allocator, params: types.CreateSearchMonitorParams) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    try serializeMonitorParamsCommon(
        w, &first,
        params.name,
        params.search,
        params.trigger,
        params.output_schema,
        params.metadata,
        params.webhook,
    );
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

pub fn serializeUpdateSearchMonitorParams(allocator: std.mem.Allocator, params: types.UpdateSearchMonitorParams) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();
    try w.writeByte('{');
    var first = true;
    if (params.name) |v| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"name\":");
        try writeStr(w, v);
    }
    if (params.status) |s| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"status\":");
        try writeStr(w, s.toString());
    }
    if (params.search) |s| try writeSearchParams(w, s, &first);
    if (params.trigger) |t| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"trigger\":{\"type\":\"interval\",\"period\":");
        try writeStr(w, t.period);
        try w.writeByte('}');
    }
    if (params.output_schema) |schema| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"outputSchema\":");
        try writeJsonValue(w, schema);
    }
    if (params.metadata) |m| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"metadata\":");
        try writeJsonValue(w, m);
    }
    if (params.webhook) |webhook| {
        if (!first) try w.writeByte(',');
        first = false;
        try w.writeAll("\"webhook\":{\"url\":");
        try writeStr(w, webhook.url);
        if (webhook.events) |evts| {
            try w.writeAll(",\"events\":[");
            for (evts, 0..) |e, i| {
                if (i > 0) try w.writeByte(',');
                try writeStr(w, e.toString());
            }
            try w.writeByte(']');
        }
        try w.writeByte('}');
    }
    try w.writeByte('}');
    return buf.toOwnedSlice();
}

// ---------------------------------------------------------------------------
// Parse helpers
// ---------------------------------------------------------------------------

fn getStr(obj: std.json.ObjectMap, key: []const u8) ?[]const u8 {
    const v = obj.get(key) orelse return null;
    return switch (v) { .string => |s| s, else => null };
}

fn getInt(obj: std.json.ObjectMap, key: []const u8) ?i64 {
    const v = obj.get(key) orelse return null;
    return switch (v) { .integer => |n| n, .float => |f| @intFromFloat(f), else => null };
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

fn parseSearchMonitorInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.SearchMonitor {
    const id = try dsReq(allocator, obj, "id");
    const name = try ds(allocator, obj, "name");
    const status_str = getStr(obj, "status") orelse "active";
    const status = types.SearchMonitorStatus.fromString(status_str) orelse .active;
    const next_run_at = try ds(allocator, obj, "nextRunAt");
    const created_at = try dsReq(allocator, obj, "createdAt");
    const updated_at = try dsReq(allocator, obj, "updatedAt");

    var search = types.SearchMonitorSearch{ .query = "" };
    if (obj.get("search")) |sv| {
        if (sv == .object) {
            const so = sv.object;
            const query = try dsReq(allocator, so, "query");
            var include_domains: ?[][]const u8 = null;
            var exclude_domains: ?[][]const u8 = null;
            if (so.get("includeDomains")) |dv| {
                if (dv == .array) {
                    var list = std.ArrayList([]u8).init(allocator);
                    for (dv.array.items) |item| {
                        if (item == .string) try list.append(try allocator.dupe(u8, item.string));
                    }
                    include_domains = @ptrCast(try list.toOwnedSlice());
                }
            }
            if (so.get("excludeDomains")) |dv| {
                if (dv == .array) {
                    var list = std.ArrayList([]u8).init(allocator);
                    for (dv.array.items) |item| {
                        if (item == .string) try list.append(try allocator.dupe(u8, item.string));
                    }
                    exclude_domains = @ptrCast(try list.toOwnedSlice());
                }
            }
            search = types.SearchMonitorSearch{
                .query = query,
                .num_results = getInt(so, "numResults"),
                .include_domains = include_domains,
                .exclude_domains = exclude_domains,
                .contents = null,
            };
        }
    }

    var trigger: ?types.SearchMonitorTrigger = null;
    if (obj.get("trigger")) |tv| {
        if (tv == .object) {
            const trigger_type = try dsReq(allocator, tv.object, "type");
            const period = try dsReq(allocator, tv.object, "period");
            trigger = .{ .type = trigger_type, .period = period };
        }
    }

    var output_schema: ?std.json.Value = null;
    if (obj.get("outputSchema")) |sv| {
        if (sv != .null) output_schema = try utils.cloneValue(allocator, sv);
    }

    var metadata: ?std.json.Value = null;
    if (obj.get("metadata")) |mv| {
        if (mv != .null) metadata = try utils.cloneValue(allocator, mv);
    }

    const webhook_url = if (obj.get("webhook")) |wv|
        if (wv == .object) try dsReq(allocator, wv.object, "url") else try allocator.dupe(u8, "")
    else
        try allocator.dupe(u8, "");

    var webhook_events: ?[]types.SearchMonitorWebhookEvent = null;
    if (obj.get("webhook")) |wv| {
        if (wv == .object) {
            if (wv.object.get("events")) |ev| {
                if (ev == .array) {
                    var list = std.ArrayList(types.SearchMonitorWebhookEvent).init(allocator);
                    for (ev.array.items) |item| {
                        if (item == .string) {
                            if (types.SearchMonitorWebhookEvent.fromString(item.string)) |e| try list.append(e);
                        }
                    }
                    webhook_events = try list.toOwnedSlice();
                }
            }
        }
    }

    return types.SearchMonitor{
        .id = id,
        .name = name,
        .status = status,
        .search = search,
        .trigger = trigger,
        .output_schema = output_schema,
        .metadata = metadata,
        .webhook = .{ .url = webhook_url, .events = webhook_events },
        .next_run_at = next_run_at,
        .created_at = created_at,
        .updated_at = updated_at,
    };
}

pub fn parseSearchMonitor(allocator: std.mem.Allocator, json_bytes: []const u8) !types.SearchMonitor {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseSearchMonitorInternal(allocator, obj);
}

pub fn parseCreateSearchMonitorResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.CreateSearchMonitorResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };

    var monitor_obj = obj;
    if (obj.get("monitor")) |mv| {
        if (mv == .object) monitor_obj = mv.object;
    }

    const monitor = try parseSearchMonitorInternal(allocator, monitor_obj);
    const webhook_secret = try dsReq(allocator, obj, "webhookSecret");
    return types.CreateSearchMonitorResponse{ .monitor = monitor, .webhook_secret = webhook_secret };
}

fn parseSearchMonitorRunInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.SearchMonitorRun {
    const id = try dsReq(allocator, obj, "id");
    const monitor_id = try dsReq(allocator, obj, "monitorId");
    const status_str = getStr(obj, "status") orelse "pending";
    const status = types.SearchMonitorRunStatus.fromString(status_str) orelse .pending;
    const fail_reason_str = getStr(obj, "failReason");
    const fail_reason = if (fail_reason_str) |s| types.SearchMonitorRunFailReason.fromString(s) else null;

    var output: ?types.SearchMonitorRunOutput = null;
    if (obj.get("output")) |ov| {
        if (ov == .object) {
            var run_output = types.SearchMonitorRunOutput{};
            const oo = ov.object;
            if (oo.get("results")) |rv| {
                run_output.results = try utils.cloneValue(allocator, rv);
            }
            run_output.content = try ds(allocator, oo, "content");
            if (oo.get("grounding")) |gv| {
                if (gv == .array) {
                    var glist = std.ArrayList(types.GroundingEntry).init(allocator);
                    for (gv.array.items) |gitem| {
                        if (gitem != .object) continue;
                        const go = gitem.object;
                        const field = try dsReq(allocator, go, "field");
                        const confidence = try dsReq(allocator, go, "confidence");
                        var cit_list = std.ArrayList(types.GroundingCitation).init(allocator);
                        if (go.get("citations")) |cv| {
                            if (cv == .array) {
                                for (cv.array.items) |cit| {
                                    if (cit != .object) continue;
                                    const co = cit.object;
                                    const curl = try dsReq(allocator, co, "url");
                                    const ctitle = try dsReq(allocator, co, "title");
                                    try cit_list.append(.{ .url = curl, .title = ctitle });
                                }
                            }
                        }
                        try glist.append(.{ .field = field, .citations = try cit_list.toOwnedSlice(), .confidence = confidence });
                    }
                    run_output.grounding = try glist.toOwnedSlice();
                }
            }
            output = run_output;
        }
    }

    return types.SearchMonitorRun{
        .id = id,
        .monitor_id = monitor_id,
        .status = status,
        .output = output,
        .fail_reason = fail_reason,
        .started_at = try ds(allocator, obj, "startedAt"),
        .completed_at = try ds(allocator, obj, "completedAt"),
        .failed_at = try ds(allocator, obj, "failedAt"),
        .cancelled_at = try ds(allocator, obj, "cancelledAt"),
        .duration_ms = getInt(obj, "durationMs"),
        .created_at = try dsReq(allocator, obj, "createdAt"),
        .updated_at = try dsReq(allocator, obj, "updatedAt"),
    };
}

pub fn parseSearchMonitorRun(allocator: std.mem.Allocator, json_bytes: []const u8) !types.SearchMonitorRun {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    return parseSearchMonitorRunInternal(allocator, obj);
}

pub fn parseListSearchMonitorsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListSearchMonitorsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.SearchMonitor).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseSearchMonitorInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListSearchMonitorsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseListSearchMonitorRunsResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListSearchMonitorRunsResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };
    var list = std.ArrayList(types.SearchMonitorRun).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                if (item != .object) continue;
                try list.append(try parseSearchMonitorRunInternal(allocator, item.object));
            }
        }
    }
    const has_more = getBool(obj, "hasMore") orelse false;
    const next_cursor = try ds(allocator, obj, "nextCursor");
    return types.ListSearchMonitorRunsResponse{ .data = try list.toOwnedSlice(), .has_more = has_more, .next_cursor = next_cursor };
}

pub fn parseTriggerSearchMonitorResponse(allocator: std.mem.Allocator, json_bytes: []const u8) !types.TriggerSearchMonitorResponse {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return types.TriggerSearchMonitorResponse{ .triggered = false } };
    const triggered = getBool(obj, "triggered") orelse false;
    return types.TriggerSearchMonitorResponse{ .triggered = triggered };
}
