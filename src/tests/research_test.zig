/// Comprehensive unit tests for the Research subsystem JSON layer.
const std = @import("std");
const exa = @import("exa");
const research_json = @import("../research/json.zig");
const research_types = @import("../research/types.zig");

// ---------------------------------------------------------------------------
// Serialization tests
// ---------------------------------------------------------------------------

test "serializeCreateRequest — default model" {
    const allocator = std.testing.allocator;
    const req = research_types.ResearchCreateRequestDto{
        .instructions = "Summarise the latest advances in quantum computing.",
    };
    const json = try research_json.serializeCreateRequest(allocator, req);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"instructions\":") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "quantum computing") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"model\":") != null);
}

test "serializeCreateRequest — exa_research_fast model" {
    const allocator = std.testing.allocator;
    const req = research_types.ResearchCreateRequestDto{
        .model = .exa_research_fast,
        .instructions = "What are the top AI safety labs?",
    };
    const json = try research_json.serializeCreateRequest(allocator, req);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"model\":\"exa-research-fast\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "AI safety labs") != null);
}

test "serializeCreateRequest — exa_research_pro model" {
    const allocator = std.testing.allocator;
    const req = research_types.ResearchCreateRequestDto{
        .model = .exa_research_pro,
        .instructions = "Detailed competitive landscape for AI coding assistants.",
    };
    const json = try research_json.serializeCreateRequest(allocator, req);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"model\":\"exa-research-pro\"") != null);
}

test "serializeCreateRequest — with output schema" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    var obj = std.json.ObjectMap.init(aa);
    try obj.put("type", .{ .string = "object" });
    const schema = std.json.Value{ .object = obj };

    const req = research_types.ResearchCreateRequestDto{
        .instructions = "Top venture funds",
        .output_schema = schema,
    };
    const json = try research_json.serializeCreateRequest(allocator, req);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"outputSchema\":{") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"type\":\"object\"") != null);
}

test "serializeCreateRequest — instructions too long returns error" {
    const allocator = std.testing.allocator;
    const long_instructions = "x" ** 4097;
    const req = research_types.ResearchCreateRequestDto{
        .instructions = long_instructions,
    };
    const result = research_json.serializeCreateRequest(allocator, req);
    try std.testing.expectError(error.InstructionsTooLong, result);
}

test "serializeCreateRequest — exactly 4096 bytes is allowed" {
    const allocator = std.testing.allocator;
    const ok_instructions = "x" ** 4096;
    const req = research_types.ResearchCreateRequestDto{
        .instructions = ok_instructions,
    };
    const json = try research_json.serializeCreateRequest(allocator, req);
    defer allocator.free(json);
    try std.testing.expect(json.len > 0);
}

// ---------------------------------------------------------------------------
// Parsing tests — ResearchDto (union) — use arena to avoid complex deinit
// ---------------------------------------------------------------------------

test "parseResearchDto — pending variant" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const pending_json =
        \\{"status":"pending","researchId":"res_pending_001","model":"exa-research","instructions":"Top AI safety organizations","createdAt":1709294400.0}
    ;

    const dto = try research_json.parseResearchDto(allocator, pending_json);
    switch (dto) {
        .pending => |p| {
            try std.testing.expectEqualStrings("res_pending_001", p.base.research_id);
            try std.testing.expectEqual(research_types.ResearchModel.exa_research, p.base.model);
            try std.testing.expectEqualStrings("Top AI safety organizations", p.base.instructions);
        },
        else => return error.UnexpectedVariant,
    }
}

test "parseResearchDto — running variant" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const running_json =
        \\{"status":"running","researchId":"res_running_002","model":"exa-research","instructions":"CRISPR breakthroughs","createdAt":1709380800.0}
    ;

    const dto = try research_json.parseResearchDto(allocator, running_json);
    switch (dto) {
        .running => |r| {
            try std.testing.expectEqualStrings("res_running_002", r.base.research_id);
        },
        else => return error.UnexpectedVariant,
    }
}

test "parseResearchDto — completed variant with output and cost" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const completed_json =
        \\{"status":"completed","researchId":"res_done_003","model":"exa-research-pro","instructions":"Quantum computing in finance","createdAt":1709467200.0,"finishedAt":1709467500.0,"content":"Quantum computers are being explored...","costDollars":{"total":0.042}}
    ;

    const dto = try research_json.parseResearchDto(allocator, completed_json);
    switch (dto) {
        .completed => |c| {
            try std.testing.expectEqualStrings("res_done_003", c.base.research_id);
            try std.testing.expectEqual(research_types.ResearchModel.exa_research_pro, c.base.model);
            try std.testing.expect(c.output.content.len > 0);
            try std.testing.expectApproxEqAbs(@as(f64, 0.042), c.cost_dollars.total, 0.0001);
        },
        else => return error.UnexpectedVariant,
    }
}

test "parseResearchDto — failed variant" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const failed_json =
        \\{"status":"failed","researchId":"res_fail_004","model":"exa-research","instructions":"Something that failed","createdAt":1709553600.0,"finishedAt":1709553660.0,"errorMsg":"Rate limit exceeded"}
    ;

    const dto = try research_json.parseResearchDto(allocator, failed_json);
    switch (dto) {
        .failed => |f| {
            try std.testing.expectEqualStrings("res_fail_004", f.base.research_id);
            try std.testing.expectEqualStrings("Rate limit exceeded", f.error_msg);
        },
        else => return error.UnexpectedVariant,
    }
}

test "parseResearchDto — canceled variant" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const canceled_json =
        \\{"status":"canceled","researchId":"res_cancel_005","model":"exa-research","instructions":"Canceled query","createdAt":1709640000.0,"finishedAt":1709640120.0}
    ;

    const dto = try research_json.parseResearchDto(allocator, canceled_json);
    switch (dto) {
        .canceled => |c| {
            try std.testing.expectEqualStrings("res_cancel_005", c.base.research_id);
            try std.testing.expectApproxEqAbs(@as(f64, 1709640120.0), c.finished_at, 0.001);
        },
        else => return error.UnexpectedVariant,
    }
}

// ---------------------------------------------------------------------------
// Parsing tests — ListResearchResponseDto — use arena allocator
// ---------------------------------------------------------------------------

test "parseListResearchResponseDto — two items with cursor" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const list_json =
        \\{"data":[{"status":"completed","researchId":"res_a","model":"exa-research","instructions":"First query","createdAt":1706745600.0,"finishedAt":1706745900.0,"content":"Result A","costDollars":{"total":0.01}},{"status":"pending","researchId":"res_b","model":"exa-research","instructions":"Second query","createdAt":1706832000.0}],"hasMore":true,"nextCursor":"next_page_token"}
    ;

    const result = try research_json.parseListResearchResponseDto(allocator, list_json);

    try std.testing.expectEqual(@as(usize, 2), result.data.len);
    switch (result.data[0]) {
        .completed => |c| try std.testing.expectEqualStrings("res_a", c.base.research_id),
        else => return error.UnexpectedVariant,
    }
    switch (result.data[1]) {
        .pending => |p| try std.testing.expectEqualStrings("res_b", p.base.research_id),
        else => return error.UnexpectedVariant,
    }
    try std.testing.expect(result.has_more);
    try std.testing.expectEqualStrings("next_page_token", result.next_cursor.?);
}

test "parseListResearchResponseDto — empty list" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const empty_json =
        \\{"data":[],"hasMore":false}
    ;

    const result = try research_json.parseListResearchResponseDto(allocator, empty_json);
    try std.testing.expectEqual(@as(usize, 0), result.data.len);
    try std.testing.expect(!result.has_more);
    try std.testing.expect(result.next_cursor == null);
}

test "parseListResearchResponseDto — all statuses" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const all_statuses_json =
        \\{"data":[{"status":"pending","researchId":"r1","model":"exa-research","instructions":"q1","createdAt":1.0},{"status":"running","researchId":"r2","model":"exa-research","instructions":"q2","createdAt":2.0},{"status":"canceled","researchId":"r3","model":"exa-research","instructions":"q3","createdAt":3.0,"finishedAt":4.0},{"status":"failed","researchId":"r4","model":"exa-research","instructions":"q4","createdAt":5.0,"finishedAt":6.0,"errorMsg":"oops"}],"hasMore":false}
    ;

    const result = try research_json.parseListResearchResponseDto(allocator, all_statuses_json);
    try std.testing.expectEqual(@as(usize, 4), result.data.len);

    switch (result.data[0]) {
        .pending => {},
        else => return error.Expected_pending,
    }
    switch (result.data[1]) {
        .running => {},
        else => return error.Expected_running,
    }
    switch (result.data[2]) {
        .canceled => {},
        else => return error.Expected_canceled,
    }
    switch (result.data[3]) {
        .failed => |f| try std.testing.expectEqualStrings("oops", f.error_msg),
        else => return error.Expected_failed,
    }
}

// ---------------------------------------------------------------------------
// Parsing tests — SSE research events
// NOTE: parseSseResearchEvent uses "eventType" key (not "type")
// ---------------------------------------------------------------------------

test "parseSseResearchEvent — DONE sentinel returns null" {
    const allocator = std.testing.allocator;
    const event = try research_json.parseSseResearchEvent(allocator, "data: [DONE]");
    try std.testing.expect(event == null);
}

test "parseSseResearchEvent — empty line returns null" {
    const allocator = std.testing.allocator;
    const event = try research_json.parseSseResearchEvent(allocator, "");
    try std.testing.expect(event == null);
}

test "parseSseResearchEvent — non-data line returns null" {
    const allocator = std.testing.allocator;
    const event = try research_json.parseSseResearchEvent(allocator, "event: keep-alive");
    try std.testing.expect(event == null);
}

test "parseSseResearchEvent — data-only prefix with no payload returns null" {
    const allocator = std.testing.allocator;
    const event = try research_json.parseSseResearchEvent(allocator, "data: ");
    try std.testing.expect(event == null);
}

test "parseSseResearchEvent — research_definition event" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const line = "data: {\"eventType\":\"research.definition\",\"researchId\":\"res_001\",\"instructions\":\"test instructions\",\"createdAt\":1709294400.0}";
    const event = try research_json.parseSseResearchEvent(allocator, line);
    try std.testing.expect(event != null);
    switch (event.?) {
        .research_definition => |d| {
            try std.testing.expectEqualStrings("res_001", d.research_id);
            try std.testing.expectEqualStrings("test instructions", d.instructions);
        },
        else => return error.UnexpectedEventType,
    }
}

test "parseSseResearchEvent — plan_definition event" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const line = "data: {\"eventType\":\"plan.definition\",\"researchId\":\"res_001\",\"planId\":\"plan_001\",\"createdAt\":1709294401.0}";
    const event = try research_json.parseSseResearchEvent(allocator, line);
    try std.testing.expect(event != null);
    switch (event.?) {
        .plan_definition => |d| {
            try std.testing.expectEqualStrings("plan_001", d.plan_id);
        },
        else => return error.UnexpectedEventType,
    }
}

test "parseSseResearchEvent — plan_operation think event" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const line = "data: {\"eventType\":\"plan.operation\",\"researchId\":\"res_001\",\"planId\":\"plan_001\",\"operationId\":\"op_001\",\"operationType\":\"think\",\"data\":{\"content\":\"Analyzing sources\"},\"createdAt\":1709294402.0}";
    const event = try research_json.parseSseResearchEvent(allocator, line);
    try std.testing.expect(event != null);
    switch (event.?) {
        .plan_operation => |op| {
            try std.testing.expectEqualStrings("op_001", op.operation_id);
            switch (op.data) {
                .think => |t| try std.testing.expectEqualStrings("Analyzing sources", t.content),
                else => return error.Expected_think,
            }
        },
        else => return error.UnexpectedEventType,
    }
}

test "parseSseResearchEvent — task_definition event" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const line = "data: {\"eventType\":\"task.definition\",\"researchId\":\"res_001\",\"planId\":\"plan_001\",\"taskId\":\"task_001\",\"instructions\":\"Research AI labs\",\"createdAt\":1709294403.0}";
    const event = try research_json.parseSseResearchEvent(allocator, line);
    try std.testing.expect(event != null);
    switch (event.?) {
        .task_definition => |t| {
            try std.testing.expectEqualStrings("task_001", t.task_id);
            try std.testing.expectEqualStrings("Research AI labs", t.instructions);
        },
        else => return error.UnexpectedEventType,
    }
}

// ---------------------------------------------------------------------------
// ResearchModel enum coverage
// ---------------------------------------------------------------------------

test "ResearchModel — all variants serialize correctly" {
    try std.testing.expectEqualStrings("exa-research-fast", research_types.ResearchModel.exa_research_fast.toString());
    try std.testing.expectEqualStrings("exa-research", research_types.ResearchModel.exa_research.toString());
    try std.testing.expectEqualStrings("exa-research-pro", research_types.ResearchModel.exa_research_pro.toString());
}

test "ResearchModel — fromString parses all variants" {
    try std.testing.expectEqual(research_types.ResearchModel.exa_research_fast, research_types.ResearchModel.fromString("exa-research-fast").?);
    try std.testing.expectEqual(research_types.ResearchModel.exa_research, research_types.ResearchModel.fromString("exa-research").?);
    try std.testing.expectEqual(research_types.ResearchModel.exa_research_pro, research_types.ResearchModel.fromString("exa-research-pro").?);
    try std.testing.expect(research_types.ResearchModel.fromString("exa") == null);
    try std.testing.expect(research_types.ResearchModel.fromString("") == null);
}

// ---------------------------------------------------------------------------
// Top-level alias smoke test
// ---------------------------------------------------------------------------

test "top-level re-exports — research types are reachable" {
    _ = exa.ResearchDto;
    _ = exa.ResearchBaseDto;
    _ = exa.ListResearchResponseDto;
    _ = exa.ResearchCreateRequestDto;
    _ = exa.ResearchStatus;
    _ = exa.ResearchModel;
    _ = exa.ResearchSearchType;
    _ = exa.ResearchOutput;
    _ = exa.ResearchOperation;
    _ = exa.ResearchEvent;
    _ = exa.ResearchDefinitionEvent;
    _ = exa.ResearchOutputEvent;
    _ = exa.ResearchCostDollars;
    _ = exa.ResearchResult;
    _ = exa.ResearchClient;
    _ = exa.ResearchStreamIterator;
}
