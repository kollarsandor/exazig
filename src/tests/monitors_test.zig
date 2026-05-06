/// Comprehensive unit tests for the Search Monitors subsystem JSON layer.
const std = @import("std");
const exa = @import("exa");
const monitors_json = @import("../monitors/json.zig");
const monitors_types = @import("../monitors/types.zig");

// ---------------------------------------------------------------------------
// Serialization tests
// ---------------------------------------------------------------------------

test "serializeCreateSearchMonitorParams — minimal" {
    const allocator = std.testing.allocator;
    const params = monitors_types.CreateSearchMonitorParams{
        .search = .{ .query = "AI startups in NYC" },
        .webhook = .{ .url = "https://example.com/hook" },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"query\":\"AI startups in NYC\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"url\":\"https://example.com/hook\"") != null);
}

test "serializeCreateSearchMonitorParams — with name and trigger" {
    const allocator = std.testing.allocator;
    const params = monitors_types.CreateSearchMonitorParams{
        .name = "Weekly AI monitor",
        .search = .{
            .query = "AI news",
            .num_results = 10,
        },
        .trigger = .{ .type = "interval", .period = "week" },
        .webhook = .{ .url = "https://hooks.example.com/exa" },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"name\":\"Weekly AI monitor\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"numResults\":10") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"trigger\":{\"type\":\"interval\",\"period\":\"week\"}") != null);
}

test "serializeCreateSearchMonitorParams — with include/exclude domains" {
    const allocator = std.testing.allocator;
    var include = [_][]const u8{"techcrunch.com"};
    var exclude = [_][]const u8{ "reddit.com", "twitter.com" };
    const params = monitors_types.CreateSearchMonitorParams{
        .search = .{
            .query = "startup funding news",
            .include_domains = &include,
            .exclude_domains = &exclude,
        },
        .webhook = .{ .url = "https://hooks.example.com/monitor" },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"includeDomains\":[\"techcrunch.com\"]") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"excludeDomains\":[\"reddit.com\",\"twitter.com\"]") != null);
}

test "serializeCreateSearchMonitorParams — with text contents enabled" {
    const allocator = std.testing.allocator;
    const params = monitors_types.CreateSearchMonitorParams{
        .search = .{
            .query = "climate tech news",
            .contents = .{
                .text = .{ .enabled = true },
            },
        },
        .webhook = .{ .url = "https://example.com/hook" },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"contents\":{") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"text\":true") != null);
}

test "serializeCreateSearchMonitorParams — with summary query option" {
    const allocator = std.testing.allocator;
    const params = monitors_types.CreateSearchMonitorParams{
        .search = .{
            .query = "biotech news",
            .contents = .{
                .summary = .{ .options = .{ .query = "What is the main finding?" } },
            },
        },
        .webhook = .{ .url = "https://hooks.example.com/bio" },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"summary\":{") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"query\":\"What is the main finding?\"") != null);
}

test "serializeCreateSearchMonitorParams — extras key present in JSON" {
    const allocator = std.testing.allocator;
    const params = monitors_types.CreateSearchMonitorParams{
        .search = .{
            .query = "tech news",
            .contents = .{
                .extras = .{ .links = 5 },
            },
        },
        .webhook = .{ .url = "https://hooks.example.com/extras" },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"extras\":{") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"links\":5") != null);
}

test "serializeCreateSearchMonitorParams — with webhook events" {
    const allocator = std.testing.allocator;
    var events = [_]monitors_types.SearchMonitorWebhookEvent{.monitor_run_completed};
    const params = monitors_types.CreateSearchMonitorParams{
        .search = .{ .query = "fintech news" },
        .webhook = .{
            .url = "https://example.com/hook",
            .events = &events,
        },
    };
    const json = try monitors_json.serializeCreateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"events\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"monitor.run.completed\"") != null);
}

test "serializeUpdateSearchMonitorParams — name only" {
    const allocator = std.testing.allocator;
    const params = monitors_types.UpdateSearchMonitorParams{
        .name = "Updated monitor name",
    };
    const json = try monitors_json.serializeUpdateSearchMonitorParams(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"name\":\"Updated monitor name\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"search\"") == null);
}

// ---------------------------------------------------------------------------
// Parsing tests — SearchMonitor
// ---------------------------------------------------------------------------

const search_monitor_json =
    \\{
    \\  "id": "mon_001",
    \\  "name": "Daily tech news",
    \\  "status": "active",
    \\  "search": {
    \\    "query": "tech startup funding",
    \\    "numResults": 10
    \\  },
    \\  "trigger": {
    \\    "type": "interval",
    \\    "period": "day"
    \\  },
    \\  "webhook": {
    \\    "url": "https://example.com/hook"
    \\  },
    \\  "createdAt": "2024-03-01T00:00:00Z",
    \\  "updatedAt": "2024-03-01T00:00:00Z"
    \\}
;

test "parseSearchMonitor — active status" {
    const allocator = std.testing.allocator;
    var mon = try monitors_json.parseSearchMonitor(allocator, search_monitor_json);
    defer mon.deinit(allocator);

    try std.testing.expectEqualStrings("mon_001", mon.id);
    try std.testing.expectEqualStrings("Daily tech news", mon.name.?);
    try std.testing.expectEqual(monitors_types.SearchMonitorStatus.active, mon.status);
    try std.testing.expectEqualStrings("tech startup funding", mon.search.query);
    try std.testing.expectEqual(@as(?i64, 10), mon.search.num_results);
    try std.testing.expectEqualStrings("day", mon.trigger.?.period);
    try std.testing.expectEqualStrings("https://example.com/hook", mon.webhook.url);
}

const search_monitor_paused_json =
    \\{
    \\  "id": "mon_002",
    \\  "status": "paused",
    \\  "search": {
    \\    "query": "paused query"
    \\  },
    \\  "webhook": {
    \\    "url": "https://example.com/paused"
    \\  },
    \\  "createdAt": "2024-03-02T00:00:00Z",
    \\  "updatedAt": "2024-03-02T00:00:00Z"
    \\}
;

test "parseSearchMonitor — paused status, no name, no trigger" {
    const allocator = std.testing.allocator;
    var mon = try monitors_json.parseSearchMonitor(allocator, search_monitor_paused_json);
    defer mon.deinit(allocator);

    try std.testing.expectEqual(monitors_types.SearchMonitorStatus.paused, mon.status);
    try std.testing.expect(mon.name == null);
    try std.testing.expect(mon.trigger == null);
}

const search_monitor_disabled_json =
    \\{
    \\  "id": "mon_003",
    \\  "status": "disabled",
    \\  "search": {"query": "disabled query"},
    \\  "webhook": {"url": "https://example.com/dis"},
    \\  "createdAt": "2024-03-03T00:00:00Z",
    \\  "updatedAt": "2024-03-03T00:00:00Z"
    \\}
;

test "parseSearchMonitor — disabled status" {
    const allocator = std.testing.allocator;
    var mon = try monitors_json.parseSearchMonitor(allocator, search_monitor_disabled_json);
    defer mon.deinit(allocator);

    try std.testing.expectEqual(monitors_types.SearchMonitorStatus.disabled, mon.status);
}

// ---------------------------------------------------------------------------
// Parsing tests — CreateSearchMonitorResponse
// ---------------------------------------------------------------------------

const create_monitor_response_json =
    \\{
    \\  "id": "mon_new_001",
    \\  "name": "New monitor",
    \\  "status": "active",
    \\  "search": {
    \\    "query": "new query",
    \\    "numResults": 5
    \\  },
    \\  "webhook": {
    \\    "url": "https://example.com/new"
    \\  },
    \\  "webhookSecret": "secret_abc123",
    \\  "createdAt": "2024-04-01T00:00:00Z",
    \\  "updatedAt": "2024-04-01T00:00:00Z"
    \\}
;

test "parseCreateSearchMonitorResponse" {
    const allocator = std.testing.allocator;
    var resp = try monitors_json.parseCreateSearchMonitorResponse(allocator, create_monitor_response_json);
    defer resp.deinit(allocator);

    try std.testing.expectEqualStrings("mon_new_001", resp.monitor.id);
    try std.testing.expectEqual(monitors_types.SearchMonitorStatus.active, resp.monitor.status);
    try std.testing.expectEqualStrings("secret_abc123", resp.webhook_secret);
}

// ---------------------------------------------------------------------------
// Parsing tests — SearchMonitorRun
// ---------------------------------------------------------------------------

const monitor_run_json =
    \\{
    \\  "id": "run_001",
    \\  "monitorId": "mon_001",
    \\  "status": "completed",
    \\  "completedAt": "2024-03-01T10:01:00Z",
    \\  "durationMs": 1200,
    \\  "createdAt": "2024-03-01T10:00:00Z",
    \\  "updatedAt": "2024-03-01T10:01:00Z"
    \\}
;

test "parseSearchMonitorRun — completed" {
    const allocator = std.testing.allocator;
    var run = try monitors_json.parseSearchMonitorRun(allocator, monitor_run_json);
    defer run.deinit(allocator);

    try std.testing.expectEqualStrings("run_001", run.id);
    try std.testing.expectEqualStrings("mon_001", run.monitor_id);
    try std.testing.expectEqual(monitors_types.SearchMonitorRunStatus.completed, run.status);
    try std.testing.expect(run.completed_at != null);
    try std.testing.expectEqual(@as(?i64, 1200), run.duration_ms);
}

const monitor_run_failed_json =
    \\{
    \\  "id": "run_002",
    \\  "monitorId": "mon_001",
    \\  "status": "failed",
    \\  "failReason": "search_failed",
    \\  "failedAt": "2024-03-02T10:02:00Z",
    \\  "createdAt": "2024-03-02T10:00:00Z",
    \\  "updatedAt": "2024-03-02T10:02:00Z"
    \\}
;

test "parseSearchMonitorRun — failed with reason" {
    const allocator = std.testing.allocator;
    var run = try monitors_json.parseSearchMonitorRun(allocator, monitor_run_failed_json);
    defer run.deinit(allocator);

    try std.testing.expectEqual(monitors_types.SearchMonitorRunStatus.failed, run.status);
    try std.testing.expect(run.failed_at != null);
    try std.testing.expect(run.fail_reason != null);
    try std.testing.expectEqual(monitors_types.SearchMonitorRunFailReason.search_failed, run.fail_reason.?);
}

const monitor_run_running_json =
    \\{
    \\  "id": "run_003",
    \\  "monitorId": "mon_001",
    \\  "status": "running",
    \\  "startedAt": "2024-03-03T09:00:00Z",
    \\  "createdAt": "2024-03-03T09:00:00Z",
    \\  "updatedAt": "2024-03-03T09:00:05Z"
    \\}
;

test "parseSearchMonitorRun — running status" {
    const allocator = std.testing.allocator;
    var run = try monitors_json.parseSearchMonitorRun(allocator, monitor_run_running_json);
    defer run.deinit(allocator);

    try std.testing.expectEqual(monitors_types.SearchMonitorRunStatus.running, run.status);
    try std.testing.expect(run.started_at != null);
    try std.testing.expect(run.completed_at == null);
}

// ---------------------------------------------------------------------------
// Parsing tests — list responses
// ---------------------------------------------------------------------------

const list_monitors_json =
    \\{
    \\  "data": [
    \\    {
    \\      "id": "mon_a",
    \\      "name": "Monitor A",
    \\      "status": "active",
    \\      "search": {"query": "query a"},
    \\      "webhook": {"url": "https://example.com/a"},
    \\      "createdAt": "2024-01-01T00:00:00Z",
    \\      "updatedAt": "2024-01-01T00:00:00Z"
    \\    },
    \\    {
    \\      "id": "mon_b",
    \\      "status": "disabled",
    \\      "search": {"query": "query b"},
    \\      "webhook": {"url": "https://example.com/b"},
    \\      "createdAt": "2024-02-01T00:00:00Z",
    \\      "updatedAt": "2024-02-01T00:00:00Z"
    \\    }
    \\  ],
    \\  "hasMore": false
    \\}
;

test "parseListSearchMonitorsResponse — two monitors" {
    const allocator = std.testing.allocator;
    const result = try monitors_json.parseListSearchMonitorsResponse(allocator, list_monitors_json);
    defer {
        for (result.data) |*m| m.deinit(allocator);
        allocator.free(result.data);
        if (result.next_cursor) |nc| allocator.free(nc);
    }

    try std.testing.expectEqual(@as(usize, 2), result.data.len);
    try std.testing.expectEqualStrings("mon_a", result.data[0].id);
    try std.testing.expectEqualStrings("Monitor A", result.data[0].name.?);
    try std.testing.expectEqual(monitors_types.SearchMonitorStatus.active, result.data[0].status);
    try std.testing.expectEqualStrings("mon_b", result.data[1].id);
    try std.testing.expectEqual(monitors_types.SearchMonitorStatus.disabled, result.data[1].status);
    try std.testing.expect(!result.has_more);
}

const list_monitor_runs_json =
    \\{
    \\  "data": [
    \\    {
    \\      "id": "run_x",
    \\      "monitorId": "mon_a",
    \\      "status": "completed",
    \\      "completedAt": "2024-03-01T10:01:00Z",
    \\      "createdAt": "2024-03-01T10:00:00Z",
    \\      "updatedAt": "2024-03-01T10:01:00Z"
    \\    },
    \\    {
    \\      "id": "run_y",
    \\      "monitorId": "mon_a",
    \\      "status": "running",
    \\      "startedAt": "2024-03-02T10:00:00Z",
    \\      "createdAt": "2024-03-02T10:00:00Z",
    \\      "updatedAt": "2024-03-02T10:00:30Z"
    \\    }
    \\  ],
    \\  "hasMore": true,
    \\  "nextCursor": "page2"
    \\}
;

test "parseListSearchMonitorRunsResponse — two runs with cursor" {
    const allocator = std.testing.allocator;
    const result = try monitors_json.parseListSearchMonitorRunsResponse(allocator, list_monitor_runs_json);
    defer {
        for (result.data) |*r| r.deinit(allocator);
        allocator.free(result.data);
        if (result.next_cursor) |nc| allocator.free(nc);
    }

    try std.testing.expectEqual(@as(usize, 2), result.data.len);
    try std.testing.expectEqualStrings("run_x", result.data[0].id);
    try std.testing.expectEqual(monitors_types.SearchMonitorRunStatus.completed, result.data[0].status);
    try std.testing.expectEqualStrings("run_y", result.data[1].id);
    try std.testing.expectEqual(monitors_types.SearchMonitorRunStatus.running, result.data[1].status);
    try std.testing.expect(result.has_more);
    try std.testing.expectEqualStrings("page2", result.next_cursor.?);
}

// ---------------------------------------------------------------------------
// Parsing tests — TriggerSearchMonitorResponse
// ---------------------------------------------------------------------------

test "parseTriggerSearchMonitorResponse — triggered=true" {
    const allocator = std.testing.allocator;
    const resp = try monitors_json.parseTriggerSearchMonitorResponse(allocator, "{\"triggered\":true}");
    try std.testing.expect(resp.triggered);
}

test "parseTriggerSearchMonitorResponse — triggered=false" {
    const allocator = std.testing.allocator;
    const resp = try monitors_json.parseTriggerSearchMonitorResponse(allocator, "{\"triggered\":false}");
    try std.testing.expect(!resp.triggered);
}

test "parseTriggerSearchMonitorResponse — empty object defaults to false" {
    const allocator = std.testing.allocator;
    const resp = try monitors_json.parseTriggerSearchMonitorResponse(allocator, "{}");
    try std.testing.expect(!resp.triggered);
}

// ---------------------------------------------------------------------------
// Top-level alias smoke test
// ---------------------------------------------------------------------------

test "top-level re-exports — monitors types are reachable" {
    _ = exa.SearchMonitor;
    _ = exa.SearchMonitorRun;
    _ = exa.SearchMonitorStatus;
    _ = exa.SearchMonitorRunStatus;
    _ = exa.SearchMonitorRunFailReason;
    _ = exa.SearchMonitorWebhookEvent;
    _ = exa.SearchMonitorSearch;
    _ = exa.SearchMonitorTrigger;
    _ = exa.SearchMonitorWebhook;
    _ = exa.SearchMonitorContents;
    _ = exa.SearchMonitorTextContents;
    _ = exa.SearchMonitorHighlightsContents;
    _ = exa.SearchMonitorSummaryContents;
    _ = exa.SearchMonitorExtrasContents;
    _ = exa.SearchMonitorRunOutput;
    _ = exa.CreateSearchMonitorParams;
    _ = exa.UpdateSearchMonitorParams;
    _ = exa.CreateSearchMonitorResponse;
    _ = exa.TriggerSearchMonitorResponse;
    _ = exa.ListSearchMonitorsResponse;
    _ = exa.ListSearchMonitorRunsResponse;
    _ = exa.SearchMonitorsClient;
    _ = exa.SearchMonitorRunsClient;
}
