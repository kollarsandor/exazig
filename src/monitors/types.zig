/// Search Monitors subsystem types.
const std = @import("std");
const utils = @import("../utils.zig");

pub const SearchMonitorStatus = enum {
    active, paused, disabled,
    pub fn toString(self: SearchMonitorStatus) []const u8 {
        return switch (self) { .active => "active", .paused => "paused", .disabled => "disabled" };
    }
    pub fn fromString(s: []const u8) ?SearchMonitorStatus {
        if (std.mem.eql(u8, s, "active")) return .active;
        if (std.mem.eql(u8, s, "paused")) return .paused;
        if (std.mem.eql(u8, s, "disabled")) return .disabled;
        return null;
    }
};

pub const SearchMonitorRunStatus = enum {
    pending, running, completed, failed, cancelled,
    pub fn toString(self: SearchMonitorRunStatus) []const u8 {
        return switch (self) {
            .pending => "pending", .running => "running",
            .completed => "completed", .failed => "failed", .cancelled => "cancelled",
        };
    }
    pub fn fromString(s: []const u8) ?SearchMonitorRunStatus {
        if (std.mem.eql(u8, s, "pending")) return .pending;
        if (std.mem.eql(u8, s, "running")) return .running;
        if (std.mem.eql(u8, s, "completed")) return .completed;
        if (std.mem.eql(u8, s, "failed")) return .failed;
        if (std.mem.eql(u8, s, "cancelled")) return .cancelled;
        return null;
    }
};

pub const SearchMonitorRunFailReason = enum {
    api_key_invalid,
    insufficient_credits,
    invalid_params,
    rate_limited,
    search_unavailable,
    search_failed,
    internal_error,

    pub fn toString(self: SearchMonitorRunFailReason) []const u8 {
        return switch (self) {
            .api_key_invalid => "api_key_invalid",
            .insufficient_credits => "insufficient_credits",
            .invalid_params => "invalid_params",
            .rate_limited => "rate_limited",
            .search_unavailable => "search_unavailable",
            .search_failed => "search_failed",
            .internal_error => "internal_error",
        };
    }

    pub fn fromString(s: []const u8) ?SearchMonitorRunFailReason {
        if (std.mem.eql(u8, s, "api_key_invalid")) return .api_key_invalid;
        if (std.mem.eql(u8, s, "insufficient_credits")) return .insufficient_credits;
        if (std.mem.eql(u8, s, "invalid_params")) return .invalid_params;
        if (std.mem.eql(u8, s, "rate_limited")) return .rate_limited;
        if (std.mem.eql(u8, s, "search_unavailable")) return .search_unavailable;
        if (std.mem.eql(u8, s, "search_failed")) return .search_failed;
        if (std.mem.eql(u8, s, "internal_error")) return .internal_error;
        return null;
    }
};

pub const SearchMonitorWebhookEvent = enum {
    monitor_created,
    monitor_updated,
    monitor_deleted,
    monitor_run_created,
    monitor_run_completed,

    pub fn toString(self: SearchMonitorWebhookEvent) []const u8 {
        return switch (self) {
            .monitor_created => "monitor.created",
            .monitor_updated => "monitor.updated",
            .monitor_deleted => "monitor.deleted",
            .monitor_run_created => "monitor.run.created",
            .monitor_run_completed => "monitor.run.completed",
        };
    }

    pub fn fromString(s: []const u8) ?SearchMonitorWebhookEvent {
        if (std.mem.eql(u8, s, "monitor.created")) return .monitor_created;
        if (std.mem.eql(u8, s, "monitor.updated")) return .monitor_updated;
        if (std.mem.eql(u8, s, "monitor.deleted")) return .monitor_deleted;
        if (std.mem.eql(u8, s, "monitor.run.created")) return .monitor_run_created;
        if (std.mem.eql(u8, s, "monitor.run.completed")) return .monitor_run_completed;
        return null;
    }
};

// ---------------------------------------------------------------------------
// Content option structs
// ---------------------------------------------------------------------------

pub const SearchMonitorTextContents = struct {
    max_characters: ?i64 = null,
    include_html_tags: ?bool = null,
    verbosity: ?[]const u8 = null,
    include_sections: ?[][]const u8 = null,
    exclude_sections: ?[][]const u8 = null,
};

pub const SearchMonitorHighlightsContents = struct {
    query: ?[]const u8 = null,
    max_characters: ?i64 = null,
    num_sentences: ?i64 = null,
    highlights_per_url: ?i64 = null,
};

pub const SearchMonitorSummaryContents = struct {
    query: ?[]const u8 = null,
    schema: ?std.json.Value = null,
};

pub const SearchMonitorExtrasContents = struct {
    links: ?i64 = null,
    image_links: ?i64 = null,
};

pub const SearchMonitorContents = struct {
    text: ?union(enum) { enabled: bool, options: SearchMonitorTextContents } = null,
    highlights: ?union(enum) { enabled: bool, options: SearchMonitorHighlightsContents } = null,
    summary: ?union(enum) { enabled: bool, options: SearchMonitorSummaryContents } = null,
    extras: ?SearchMonitorExtrasContents = null,
    context: ?union(enum) { enabled: bool, options: std.json.Value } = null,
    livecrawl: ?[]const u8 = null,
    livecrawl_timeout: ?i64 = null,
    max_age_hours: ?i64 = null,
    filter_empty_results: ?bool = null,
    subpages: ?i64 = null,
    subpage_target: ?union(enum) { single: []const u8, multiple: []const []const u8 } = null,
};

// ---------------------------------------------------------------------------
// Core structs
// ---------------------------------------------------------------------------

pub const SearchMonitorSearch = struct {
    query: []const u8,
    num_results: ?i64 = null,
    include_domains: ?[][]const u8 = null,
    exclude_domains: ?[][]const u8 = null,
    contents: ?SearchMonitorContents = null,
};

pub const SearchMonitorTrigger = struct {
    type: []const u8,
    period: []const u8,
};

pub const SearchMonitorWebhook = struct {
    url: []const u8,
    events: ?[]SearchMonitorWebhookEvent = null,
};

pub const GroundingCitation = struct {
    url: []const u8,
    title: []const u8,
};

pub const GroundingEntry = struct {
    field: []const u8,
    citations: []GroundingCitation,
    confidence: []const u8,
};

pub const SearchMonitorRunOutput = struct {
    results: ?std.json.Value = null,
    content: ?[]const u8 = null,
    grounding: ?[]GroundingEntry = null,
};

pub const SearchMonitor = struct {
    id: []const u8,
    name: ?[]const u8 = null,
    status: SearchMonitorStatus,
    search: SearchMonitorSearch,
    trigger: ?SearchMonitorTrigger = null,
    output_schema: ?std.json.Value = null,
    metadata: ?std.json.Value = null,
    webhook: SearchMonitorWebhook,
    next_run_at: ?[]const u8 = null,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: SearchMonitor, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        if (self.name) |v| allocator.free(v);
        allocator.free(self.search.query);
        if (self.search.num_results) |_| {}
        if (self.search.include_domains) |ds| {
            for (ds) |d| allocator.free(d);
            allocator.free(ds);
        }
        if (self.search.exclude_domains) |ds| {
            for (ds) |d| allocator.free(d);
            allocator.free(ds);
        }
        if (self.trigger) |t| {
            allocator.free(t.type);
            allocator.free(t.period);
        }
        if (self.output_schema) |v| utils.freeValue(allocator, v);
        if (self.metadata) |v| utils.freeValue(allocator, v);
        allocator.free(self.webhook.url);
        if (self.webhook.events) |evts| allocator.free(evts);
        if (self.next_run_at) |v| allocator.free(v);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const CreateSearchMonitorResponse = struct {
    monitor: SearchMonitor,
    webhook_secret: []const u8,

    pub fn deinit(self: CreateSearchMonitorResponse, allocator: std.mem.Allocator) void {
        self.monitor.deinit(allocator);
        allocator.free(self.webhook_secret);
    }
};

pub const SearchMonitorRun = struct {
    id: []const u8,
    monitor_id: []const u8,
    status: SearchMonitorRunStatus,
    output: ?SearchMonitorRunOutput = null,
    fail_reason: ?SearchMonitorRunFailReason = null,
    started_at: ?[]const u8 = null,
    completed_at: ?[]const u8 = null,
    failed_at: ?[]const u8 = null,
    cancelled_at: ?[]const u8 = null,
    duration_ms: ?i64 = null,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: SearchMonitorRun, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.monitor_id);
        if (self.output) |o| {
            if (o.results) |v| utils.freeValue(allocator, v);
            if (o.content) |v| allocator.free(v);
            if (o.grounding) |gs| {
                for (gs) |g| {
                    allocator.free(g.field);
                    for (g.citations) |c| {
                        allocator.free(c.url);
                        allocator.free(c.title);
                    }
                    allocator.free(g.citations);
                    allocator.free(g.confidence);
                }
                allocator.free(gs);
            }
        }
        if (self.started_at) |v| allocator.free(v);
        if (self.completed_at) |v| allocator.free(v);
        if (self.failed_at) |v| allocator.free(v);
        if (self.cancelled_at) |v| allocator.free(v);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const CreateSearchMonitorParams = struct {
    name: ?[]const u8 = null,
    search: SearchMonitorSearch,
    trigger: ?SearchMonitorTrigger = null,
    output_schema: ?std.json.Value = null,
    metadata: ?std.json.Value = null,
    webhook: SearchMonitorWebhook,

    pub fn deinit(self: CreateSearchMonitorParams, allocator: std.mem.Allocator) void {
        if (self.name) |v| allocator.free(v);
        allocator.free(self.search.query);
        if (self.output_schema) |v| utils.freeValue(allocator, v);
        if (self.metadata) |v| utils.freeValue(allocator, v);
        allocator.free(self.webhook.url);
    }
};

pub const UpdateSearchMonitorParams = struct {
    name: ?[]const u8 = null,
    status: ?SearchMonitorStatus = null,
    search: ?SearchMonitorSearch = null,
    trigger: ?SearchMonitorTrigger = null,
    output_schema: ?std.json.Value = null,
    metadata: ?std.json.Value = null,
    webhook: ?SearchMonitorWebhook = null,

    pub fn deinit(self: UpdateSearchMonitorParams, allocator: std.mem.Allocator) void {
        if (self.name) |v| allocator.free(v);
        if (self.search) |s| allocator.free(s.query);
        if (self.output_schema) |v| utils.freeValue(allocator, v);
        if (self.metadata) |v| utils.freeValue(allocator, v);
        if (self.webhook) |w| allocator.free(w.url);
    }
};

pub const TriggerSearchMonitorResponse = struct {
    triggered: bool,
};

pub const ListSearchMonitorsResponse = struct {
    data: []SearchMonitor,
    has_more: bool,
    next_cursor: ?[]const u8 = null,

    pub fn deinit(self: ListSearchMonitorsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |m| m.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListSearchMonitorRunsResponse = struct {
    data: []SearchMonitorRun,
    has_more: bool,
    next_cursor: ?[]const u8 = null,

    pub fn deinit(self: ListSearchMonitorRunsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |r| r.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};
