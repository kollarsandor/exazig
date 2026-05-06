/// JSON serialization and deserialization for the Research subsystem.
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
            var first = true;
            while (it.next()) |entry| {
                if (!first) try writer.writeByte(',');
                first = false;
                try writeStr(writer, entry.key_ptr.*);
                try writer.writeByte(':');
                try writeJsonValue(writer, entry.value_ptr.*);
            }
            try writer.writeByte('}');
        },
    }
}

/// Serializes a ResearchCreateRequestDto to JSON.
/// Returns error.InstructionsTooLong if instructions exceed 4096 bytes.
pub fn serializeCreateRequest(allocator: std.mem.Allocator, req: types.ResearchCreateRequestDto) ![]u8 {
    if (req.instructions.len > 4096) return error.InstructionsTooLong;

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const w = buf.writer();

    try w.writeByte('{');
    try w.writeAll("\"model\":");
    try writeStr(w, req.model.toString());
    try w.writeAll(",\"instructions\":");
    try writeStr(w, req.instructions);
    if (req.output_schema) |schema| {
        try w.writeAll(",\"outputSchema\":");
        try writeJsonValue(w, schema);
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

fn ds(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) !?[]u8 {
    const s = getStr(obj, key) orelse return null;
    return try allocator.dupe(u8, s);
}

fn dsReq(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) ![]u8 {
    const s = getStr(obj, key) orelse return error.MissingField;
    return try allocator.dupe(u8, s);
}

fn parseResearchOperation(allocator: std.mem.Allocator, op_type: []const u8, data_val: std.json.Value) !types.ResearchOperation {
    if (std.mem.eql(u8, op_type, "think")) {
        const obj = switch (data_val) { .object => |o| o, else => return error.InvalidFormat };
        const content = try dsReq(allocator, obj, "content");
        return .{ .think = .{ .content = content } };
    } else if (std.mem.eql(u8, op_type, "search")) {
        const obj = switch (data_val) { .object => |o| o, else => return error.InvalidFormat };
        const search_type_str = getStr(obj, "searchType") orelse "auto";
        const search_type = types.ResearchSearchType.fromString(search_type_str) orelse .auto;
        const query = try dsReq(allocator, obj, "query");
        const page_tokens = getFloat(obj, "pageTokens") orelse 0.0;
        const goal = try ds(allocator, obj, "goal");
        var results = std.ArrayList(types.ResearchResult).init(allocator);
        if (obj.get("results")) |rv| {
            if (rv == .array) {
                for (rv.array.items) |item| {
                    if (item != .object) continue;
                    const url = try dsReq(allocator, item.object, "url");
                    try results.append(.{ .url = url });
                }
            }
        }
        return .{ .search = .{
            .search_type = search_type,
            .query = query,
            .results = try results.toOwnedSlice(),
            .page_tokens = page_tokens,
            .goal = goal,
        } };
    } else {
        // crawl
        const obj = switch (data_val) { .object => |o| o, else => return error.InvalidFormat };
        const url = try dsReq(allocator, obj, "url");
        const page_tokens = getFloat(obj, "pageTokens") orelse 0.0;
        const goal = try ds(allocator, obj, "goal");
        return .{ .crawl = .{
            .result = .{ .url = url },
            .page_tokens = page_tokens,
            .goal = goal,
        } };
    }
}

fn parseResearchEventInternal(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.ResearchEvent {
    const event_type = getStr(obj, "eventType") orelse return error.MissingEventType;
    const research_id = try dsReq(allocator, obj, "researchId");
    errdefer allocator.free(research_id);
    const created_at = getFloat(obj, "createdAt") orelse 0.0;

    if (std.mem.eql(u8, event_type, "research.definition")) {
        const instructions = try dsReq(allocator, obj, "instructions");
        var output_schema: ?std.json.Value = null;
        if (obj.get("outputSchema")) |sv| {
            if (sv != .null) output_schema = try utils.cloneValue(allocator, sv);
        }
        return .{ .research_definition = .{
            .research_id = research_id,
            .created_at = created_at,
            .instructions = instructions,
            .output_schema = output_schema,
        } };
    }

    if (std.mem.eql(u8, event_type, "research.output")) {
        const status = getStr(obj, "status") orelse "completed";
        if (std.mem.eql(u8, status, "failed")) {
            const error_msg = try dsReq(allocator, obj, "errorMsg");
            return .{ .research_output = .{
                .research_id = research_id,
                .created_at = created_at,
                .output = .{ .failed = .{ .error_msg = error_msg } },
            } };
        }
        const content = try dsReq(allocator, obj, "content");
        const cost = parseCostDollars(obj);
        var parsed_val: ?std.json.Value = null;
        if (obj.get("parsed")) |pv| {
            if (pv != .null) parsed_val = try utils.cloneValue(allocator, pv);
        }
        return .{ .research_output = .{
            .research_id = research_id,
            .created_at = created_at,
            .output = .{ .completed = .{ .content = content, .cost_dollars = cost, .parsed = parsed_val } },
        } };
    }

    if (std.mem.eql(u8, event_type, "plan.definition")) {
        const plan_id = try dsReq(allocator, obj, "planId");
        return .{ .plan_definition = .{ .research_id = research_id, .plan_id = plan_id, .created_at = created_at } };
    }

    if (std.mem.eql(u8, event_type, "plan.operation")) {
        const plan_id = try dsReq(allocator, obj, "planId");
        const operation_id = try dsReq(allocator, obj, "operationId");
        const op_type = getStr(obj, "operationType") orelse "think";
        const data_val = obj.get("data") orelse .null;
        const data = try parseResearchOperation(allocator, op_type, data_val);
        return .{ .plan_operation = .{
            .research_id = research_id,
            .plan_id = plan_id,
            .operation_id = operation_id,
            .created_at = created_at,
            .data = data,
        } };
    }

    if (std.mem.eql(u8, event_type, "plan.output")) {
        const plan_id = try dsReq(allocator, obj, "planId");
        const output_type = getStr(obj, "outputType") orelse "stop";
        if (std.mem.eql(u8, output_type, "tasks")) {
            const reasoning = try dsReq(allocator, obj, "reasoning");
            var tasks = std.ArrayList([]const u8).init(allocator);
            if (obj.get("tasksInstructions")) |tv| {
                if (tv == .array) {
                    for (tv.array.items) |item| {
                        if (item == .string) try tasks.append(try allocator.dupe(u8, item.string));
                    }
                }
            }
            return .{ .plan_output = .{
                .research_id = research_id,
                .plan_id = plan_id,
                .created_at = created_at,
                .output = .{ .tasks = .{ .reasoning = reasoning, .tasks_instructions = try tasks.toOwnedSlice() } },
            } };
        }
        const reasoning = try dsReq(allocator, obj, "reasoning");
        return .{ .plan_output = .{
            .research_id = research_id,
            .plan_id = plan_id,
            .created_at = created_at,
            .output = .{ .stop = .{ .reasoning = reasoning } },
        } };
    }

    if (std.mem.eql(u8, event_type, "task.definition")) {
        const plan_id = try dsReq(allocator, obj, "planId");
        const task_id = try dsReq(allocator, obj, "taskId");
        const instructions = try dsReq(allocator, obj, "instructions");
        return .{ .task_definition = .{
            .research_id = research_id, .plan_id = plan_id, .task_id = task_id,
            .created_at = created_at, .instructions = instructions,
        } };
    }

    if (std.mem.eql(u8, event_type, "task.operation")) {
        const plan_id = try dsReq(allocator, obj, "planId");
        const task_id = try dsReq(allocator, obj, "taskId");
        const operation_id = try dsReq(allocator, obj, "operationId");
        const op_type = getStr(obj, "operationType") orelse "think";
        const data_val = obj.get("data") orelse .null;
        const data = try parseResearchOperation(allocator, op_type, data_val);
        return .{ .task_operation = .{
            .research_id = research_id, .plan_id = plan_id, .task_id = task_id,
            .operation_id = operation_id, .created_at = created_at, .data = data,
        } };
    }

    // task.output
    const plan_id = try dsReq(allocator, obj, "planId");
    const task_id = try dsReq(allocator, obj, "taskId");
    const content = try dsReq(allocator, obj, "content");
    return .{ .task_output = .{
        .research_id = research_id, .plan_id = plan_id, .task_id = task_id,
        .created_at = created_at, .output = .{ .content = content },
    } };
}

fn parseCostDollars(obj: std.json.ObjectMap) types.ResearchCostDollars {
    var cd_obj = obj;
    if (obj.get("costDollars")) |cv| {
        if (cv == .object) cd_obj = cv.object;
    }
    return .{
        .total = getFloat(cd_obj, "total") orelse 0.0,
        .num_pages = getFloat(cd_obj, "numPages") orelse 0.0,
        .num_searches = getFloat(cd_obj, "numSearches") orelse 0.0,
        .reasoning_tokens = getFloat(cd_obj, "reasoningTokens") orelse 0.0,
    };
}

fn parseBaseDto(allocator: std.mem.Allocator, obj: std.json.ObjectMap) !types.ResearchBaseDto {
    const research_id = try dsReq(allocator, obj, "researchId");
    const created_at = getFloat(obj, "createdAt") orelse 0.0;
    const model_str = getStr(obj, "model") orelse "exa-research";
    const model = types.ResearchModel.fromString(model_str) orelse .exa_research;
    const instructions = try dsReq(allocator, obj, "instructions");
    var output_schema: ?std.json.Value = null;
    if (obj.get("outputSchema")) |sv| {
        if (sv != .null) output_schema = try utils.cloneValue(allocator, sv);
    }
    return types.ResearchBaseDto{
        .research_id = research_id,
        .created_at = created_at,
        .model = model,
        .instructions = instructions,
        .output_schema = output_schema,
    };
}

fn parseEventsArray(allocator: std.mem.Allocator, val: std.json.Value) !?[]types.ResearchEvent {
    const arr = switch (val) { .array => |a| a, else => return null };
    var list = std.ArrayList(types.ResearchEvent).init(allocator);
    for (arr.items) |item| {
        if (item != .object) continue;
        const ev = try parseResearchEventInternal(allocator, item.object);
        try list.append(ev);
    }
    return try list.toOwnedSlice();
}

/// Parses a ResearchDto from JSON bytes.
pub fn parseResearchDto(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ResearchDto {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };

    const status_str = getStr(obj, "status") orelse "pending";
    const base = try parseBaseDto(allocator, obj);

    if (std.mem.eql(u8, status_str, "pending")) {
        return .{ .pending = .{ .base = base } };
    }

    var events: ?[]types.ResearchEvent = null;
    if (obj.get("events")) |ev| {
        events = try parseEventsArray(allocator, ev);
    }

    if (std.mem.eql(u8, status_str, "running")) {
        return .{ .running = .{ .base = base, .events = events } };
    }

    const finished_at = getFloat(obj, "finishedAt") orelse 0.0;

    if (std.mem.eql(u8, status_str, "canceled")) {
        return .{ .canceled = .{ .base = base, .finished_at = finished_at, .events = events } };
    }

    if (std.mem.eql(u8, status_str, "failed")) {
        const error_msg = try dsReq(allocator, obj, "errorMsg");
        return .{ .failed = .{ .base = base, .finished_at = finished_at, .events = events, .error_msg = error_msg } };
    }

    // completed
    const content = try dsReq(allocator, obj, "content");
    var parsed_val: ?std.json.Value = null;
    if (obj.get("parsed")) |pv| {
        if (pv != .null) parsed_val = try utils.cloneValue(allocator, pv);
    }
    const cost = parseCostDollars(obj);
    return .{ .completed = .{
        .base = base,
        .finished_at = finished_at,
        .events = events,
        .output = .{ .content = content, .parsed = parsed_val },
        .cost_dollars = cost,
    } };
}

/// Parses a paginated list of ResearchDto from JSON bytes.
pub fn parseListResearchResponseDto(allocator: std.mem.Allocator, json_bytes: []const u8) !types.ListResearchResponseDto {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();
    const obj = switch (parsed.value) { .object => |o| o, else => return error.InvalidFormat };

    var list = std.ArrayList(types.ResearchDto).init(allocator);
    if (obj.get("data")) |dv| {
        if (dv == .array) {
            for (dv.array.items) |item| {
                const item_bytes = try std.json.stringifyAlloc(allocator, item, .{});
                defer allocator.free(item_bytes);
                try list.append(try parseResearchDto(allocator, item_bytes));
            }
        }
    }

    const has_more = if (obj.get("hasMore")) |v| switch (v) { .bool => |b| b, else => false } else false;
    const next_cursor = try ds(allocator, obj, "nextCursor");

    return types.ListResearchResponseDto{
        .data = try list.toOwnedSlice(),
        .has_more = has_more,
        .next_cursor = next_cursor,
    };
}

/// Parses a single SSE line into a ResearchEvent. Returns null if line has no data.
pub fn parseSseResearchEvent(allocator: std.mem.Allocator, line: []const u8) !?types.ResearchEvent {
    const prefix = "data: ";
    if (!std.mem.startsWith(u8, line, prefix)) return null;
    const data = line[prefix.len..];
    if (data.len == 0) return null;
    if (std.mem.eql(u8, data, "[DONE]")) return null;

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, data, .{}) catch return null;
    defer parsed.deinit();

    const obj = switch (parsed.value) { .object => |o| o, else => return null };
    return try parseResearchEventInternal(allocator, obj);
}
