/// Research subsystem types.
const std = @import("std");
const utils = @import("../utils.zig");

pub const ResearchModel = enum {
    exa_research_fast,
    exa_research,
    exa_research_pro,

    pub fn toString(self: ResearchModel) []const u8 {
        return switch (self) {
            .exa_research_fast => "exa-research-fast",
            .exa_research => "exa-research",
            .exa_research_pro => "exa-research-pro",
        };
    }

    pub fn fromString(s: []const u8) ?ResearchModel {
        if (std.mem.eql(u8, s, "exa-research-fast")) return .exa_research_fast;
        if (std.mem.eql(u8, s, "exa-research")) return .exa_research;
        if (std.mem.eql(u8, s, "exa-research-pro")) return .exa_research_pro;
        return null;
    }
};

pub const ResearchStatus = enum {
    pending, running, completed, canceled, failed,

    pub fn toString(self: ResearchStatus) []const u8 {
        return switch (self) {
            .pending => "pending",
            .running => "running",
            .completed => "completed",
            .canceled => "canceled",
            .failed => "failed",
        };
    }

    pub fn fromString(s: []const u8) ?ResearchStatus {
        if (std.mem.eql(u8, s, "pending")) return .pending;
        if (std.mem.eql(u8, s, "running")) return .running;
        if (std.mem.eql(u8, s, "completed")) return .completed;
        if (std.mem.eql(u8, s, "canceled")) return .canceled;
        if (std.mem.eql(u8, s, "failed")) return .failed;
        return null;
    }
};

pub const ResearchSearchType = enum {
    neural, keyword, auto, fast,

    pub fn toString(self: ResearchSearchType) []const u8 {
        return switch (self) {
            .neural => "neural",
            .keyword => "keyword",
            .auto => "auto",
            .fast => "fast",
        };
    }

    pub fn fromString(s: []const u8) ?ResearchSearchType {
        if (std.mem.eql(u8, s, "neural")) return .neural;
        if (std.mem.eql(u8, s, "keyword")) return .keyword;
        if (std.mem.eql(u8, s, "auto")) return .auto;
        if (std.mem.eql(u8, s, "fast")) return .fast;
        return null;
    }
};

// ---------------------------------------------------------------------------
// Operation types
// ---------------------------------------------------------------------------

pub const ResearchResult = struct {
    url: []const u8,
};

pub const ResearchThinkOperation = struct {
    content: []const u8,
};

pub const ResearchSearchOperation = struct {
    search_type: ResearchSearchType,
    query: []const u8,
    results: []ResearchResult,
    page_tokens: f64,
    goal: ?[]const u8 = null,
};

pub const ResearchCrawlOperation = struct {
    result: ResearchResult,
    page_tokens: f64,
    goal: ?[]const u8 = null,
};

pub const ResearchOperation = union(enum) {
    think: ResearchThinkOperation,
    search: ResearchSearchOperation,
    crawl: ResearchCrawlOperation,
};

// ---------------------------------------------------------------------------
// Event types
// ---------------------------------------------------------------------------

pub const ResearchDefinitionEvent = struct {
    research_id: []const u8,
    created_at: f64,
    instructions: []const u8,
    output_schema: ?std.json.Value = null,
};

pub const ResearchCostDollars = struct {
    total: f64,
    num_pages: f64,
    num_searches: f64,
    reasoning_tokens: f64,
};

pub const ResearchOutputCompleted = struct {
    content: []const u8,
    cost_dollars: ResearchCostDollars,
    parsed: ?std.json.Value = null,
};

pub const ResearchOutputFailed = struct {
    error_msg: []const u8,
};

pub const ResearchOutputEvent = struct {
    research_id: []const u8,
    created_at: f64,
    output: union(enum) {
        completed: ResearchOutputCompleted,
        failed: ResearchOutputFailed,
    },
};

pub const ResearchPlanDefinitionEvent = struct {
    research_id: []const u8,
    plan_id: []const u8,
    created_at: f64,
};

pub const ResearchPlanOperationEvent = struct {
    research_id: []const u8,
    plan_id: []const u8,
    operation_id: []const u8,
    created_at: f64,
    data: ResearchOperation,
};

pub const ResearchPlanOutputTasks = struct {
    reasoning: []const u8,
    tasks_instructions: [][]const u8,
};

pub const ResearchPlanOutputStop = struct {
    reasoning: []const u8,
};

pub const ResearchPlanOutputEvent = struct {
    research_id: []const u8,
    plan_id: []const u8,
    created_at: f64,
    output: union(enum) {
        tasks: ResearchPlanOutputTasks,
        stop: ResearchPlanOutputStop,
    },
};

pub const ResearchTaskDefinitionEvent = struct {
    research_id: []const u8,
    plan_id: []const u8,
    task_id: []const u8,
    created_at: f64,
    instructions: []const u8,
};

pub const ResearchTaskOperationEvent = struct {
    research_id: []const u8,
    plan_id: []const u8,
    task_id: []const u8,
    operation_id: []const u8,
    created_at: f64,
    data: ResearchOperation,
};

pub const ResearchTaskOutput = struct {
    content: []const u8,
};

pub const ResearchTaskOutputEvent = struct {
    research_id: []const u8,
    plan_id: []const u8,
    task_id: []const u8,
    created_at: f64,
    output: ResearchTaskOutput,
};

pub const ResearchEvent = union(enum) {
    research_definition: ResearchDefinitionEvent,
    research_output: ResearchOutputEvent,
    plan_definition: ResearchPlanDefinitionEvent,
    plan_operation: ResearchPlanOperationEvent,
    plan_output: ResearchPlanOutputEvent,
    task_definition: ResearchTaskDefinitionEvent,
    task_operation: ResearchTaskOperationEvent,
    task_output: ResearchTaskOutputEvent,
};

// ---------------------------------------------------------------------------
// DTO types
// ---------------------------------------------------------------------------

pub const ResearchOutput = struct {
    content: []const u8,
    parsed: ?std.json.Value = null,
};

pub const ResearchBaseDto = struct {
    research_id: []const u8,
    created_at: f64,
    model: ResearchModel,
    instructions: []const u8,
    output_schema: ?std.json.Value = null,
};

pub const ResearchDto = union(enum) {
    pending: struct { base: ResearchBaseDto },
    running: struct { base: ResearchBaseDto, events: ?[]ResearchEvent },
    completed: struct {
        base: ResearchBaseDto,
        finished_at: f64,
        events: ?[]ResearchEvent,
        output: ResearchOutput,
        cost_dollars: ResearchCostDollars,
    },
    canceled: struct { base: ResearchBaseDto, finished_at: f64, events: ?[]ResearchEvent },
    failed: struct {
        base: ResearchBaseDto,
        finished_at: f64,
        events: ?[]ResearchEvent,
        error_msg: []const u8,
    },
};

pub const ListResearchResponseDto = struct {
    data: []ResearchDto,
    has_more: bool,
    next_cursor: ?[]const u8,
};

pub const ResearchCreateRequestDto = struct {
    model: ResearchModel = .exa_research,
    /// Must be <= 4096 bytes.
    instructions: []const u8,
    output_schema: ?std.json.Value = null,
};
