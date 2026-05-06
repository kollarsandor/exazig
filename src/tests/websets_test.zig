/// Comprehensive unit tests for the Websets subsystem JSON layer.
const std = @import("std");
const exa = @import("exa");
const websets_json = @import("../websets/json.zig");
const websets_types = @import("../websets/types.zig");

// ---------------------------------------------------------------------------
// Serialization tests — CreateWebsetParameters
// ---------------------------------------------------------------------------

test "serializeCreateWebsetParameters — minimal (no entity, no enrichments)" {
    const allocator = std.testing.allocator;
    const params = websets_types.CreateWebsetParameters{
        .search = .{
            .query = "AI startups in London",
            .count = 20,
        },
    };
    const json = try websets_json.serializeCreateWebsetParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"query\":\"AI startups in London\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"count\":20") != null);
}

test "serializeCreateWebsetParameters — company entity" {
    const allocator = std.testing.allocator;
    const params = websets_types.CreateWebsetParameters{
        .search = .{
            .query = "SaaS companies",
            .count = 50,
            .entity = .company,
        },
    };
    const json = try websets_json.serializeCreateWebsetParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"entity\":\"company\"") != null);
}

test "serializeCreateWebsetParameters — research_paper entity" {
    const allocator = std.testing.allocator;
    const params = websets_types.CreateWebsetParameters{
        .search = .{
            .query = "papers on LLMs",
            .count = 10,
            .entity = .research_paper,
        },
    };
    const json = try websets_json.serializeCreateWebsetParameters(allocator, params);
    defer allocator.free(json);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"entity\":\"research_paper\"") != null);
}

test "serializeCreateWebsetParameters — with criteria" {
    const allocator = std.testing.allocator;
    var criteria = [_]websets_types.CreateCriterionParameters{
        .{ .description = "Must have raised funding" },
        .{ .description = "Must be in healthcare" },
    };
    const params = websets_types.CreateWebsetParameters{
        .search = .{
            .query = "biotech startups",
            .count = 30,
            .entity = .company,
            .criteria = &criteria,
        },
    };
    const json = try websets_json.serializeCreateWebsetParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"criteria\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"Must have raised funding\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"Must be in healthcare\"") != null);
}

test "serializeCreateWebsetParameters — with enrichments" {
    const allocator = std.testing.allocator;
    var opts = [_]websets_types.Option{ .{ .label = "yes" }, .{ .label = "no" } };
    var enrichments = [_]websets_types.CreateEnrichmentParameters{.{
        .description = "Is this company Series B or later?",
        .format = .options,
        .options = &opts,
    }};
    const params = websets_types.CreateWebsetParameters{
        .search = .{
            .query = "UK fintech companies",
            .count = 50,
            .entity = .company,
        },
        .enrichments = &enrichments,
    };
    const json = try websets_json.serializeCreateWebsetParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"enrichments\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"format\":\"options\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"label\":\"yes\"") != null);
}

// ---------------------------------------------------------------------------
// Serialization tests — CreateWebsetSearchParameters
// ---------------------------------------------------------------------------

test "serializeCreateWebsetSearchParameters — basic" {
    const allocator = std.testing.allocator;
    var criteria = [_]websets_types.CreateCriterionParameters{.{ .description = "Must be profitable" }};
    const params = websets_types.CreateWebsetSearchParameters{
        .query = "profitable SaaS companies",
        .count = 25,
        .entity = .company,
        .criteria = &criteria,
    };
    const json = try websets_json.serializeCreateWebsetSearchParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"query\":\"profitable SaaS companies\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"count\":25") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"entity\":\"company\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"criteria\":[") != null);
}

// ---------------------------------------------------------------------------
// Serialization tests — enrichments
// ---------------------------------------------------------------------------

test "serializeCreateEnrichmentParameters — text format" {
    const allocator = std.testing.allocator;
    const params = websets_types.CreateEnrichmentParameters{
        .description = "What is the company's main product?",
        .format = .text,
    };
    const json = try websets_json.serializeCreateEnrichmentParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"description\":\"What is the company's main product?\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"format\":\"text\"") != null);
}

test "serializeCreateEnrichmentParameters — options format" {
    const allocator = std.testing.allocator;
    var opts = [_]websets_types.Option{ .{ .label = "B2B" }, .{ .label = "B2C" }, .{ .label = "Both" } };
    const params = websets_types.CreateEnrichmentParameters{
        .description = "Business model",
        .format = .options,
        .options = &opts,
    };
    const json = try websets_json.serializeCreateEnrichmentParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"options\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"label\":\"B2B\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"label\":\"Both\"") != null);
}

test "serializeUpdateEnrichmentParameters — description only" {
    const allocator = std.testing.allocator;
    const params = websets_types.UpdateEnrichmentParameters{
        .description = "Updated description",
    };
    const json = try websets_json.serializeUpdateEnrichmentParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"description\":\"Updated description\"") != null);
}

// ---------------------------------------------------------------------------
// Serialization tests — webhooks
// ---------------------------------------------------------------------------

test "serializeCreateWebhookParameters — with events" {
    const allocator = std.testing.allocator;
    var events = [_]websets_types.EventType{ .webset_item_created, .webset_idle };
    const params = websets_types.CreateWebhookParameters{
        .url = "https://example.com/webhook",
        .events = &events,
    };
    const json = try websets_json.serializeCreateWebhookParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"url\":\"https://example.com/webhook\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"webset.item.created\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"webset.idle\"") != null);
}

test "serializeUpdateWebhookParameters — url only" {
    const allocator = std.testing.allocator;
    const params = websets_types.UpdateWebhookParameters{
        .url = "https://new.example.com/hook",
    };
    const json = try websets_json.serializeUpdateWebhookParameters(allocator, params);
    defer allocator.free(json);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"url\":\"https://new.example.com/hook\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"events\"") == null);
}

// ---------------------------------------------------------------------------
// Serialization tests — monitors (websets subsystem)
// ---------------------------------------------------------------------------

test "serializeCreateMonitorParameters — basic" {
    const allocator = std.testing.allocator;
    const params = websets_types.CreateMonitorParameters{
        .webset_id = "ws_test_123",
        .cadence = .{ .cron = "0 9 * * 1", .timezone = "America/New_York" },
        .behavior = .{ .search = .{ .config = .{ .count = 15 } } },
    };
    const json = try websets_json.serializeCreateMonitorParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"cron\":\"0 9 * * 1\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"timezone\":\"America/New_York\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"count\":15") != null);
}

// ---------------------------------------------------------------------------
// Serialization tests — preview
// ---------------------------------------------------------------------------

test "serializePreviewWebsetParameters — entity and query" {
    const allocator = std.testing.allocator;
    const params = websets_types.PreviewWebsetParameters{
        .query = "biotech startups",
        .entity = .company,
    };
    const json = try websets_json.serializePreviewWebsetParameters(allocator, params);
    defer allocator.free(json);

    try std.testing.expect(std.mem.indexOf(u8, json, "\"query\":\"biotech startups\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"entity\":\"company\"") != null);
}

// ---------------------------------------------------------------------------
// Parsing tests — Webset
// ---------------------------------------------------------------------------

const webset_json =
    \\{
    \\  "id": "ws_abc123",
    \\  "object": "webset",
    \\  "status": "running",
    \\  "dashboardUrl": "https://dashboard.exa.ai/websets/ws_abc123",
    \\  "searches": [],
    \\  "enrichments": [],
    \\  "monitors": [],
    \\  "createdAt": "2024-03-01T10:00:00Z",
    \\  "updatedAt": "2024-03-01T10:05:00Z"
    \\}
;

test "parseWebset — running status" {
    const allocator = std.testing.allocator;
    var ws = try websets_json.parseWebset(allocator, webset_json);
    defer ws.deinit(allocator);

    try std.testing.expectEqualStrings("ws_abc123", ws.id);
    try std.testing.expectEqualStrings("webset", ws.object);
    try std.testing.expectEqual(websets_types.WebsetStatus.running, ws.status);
    try std.testing.expectEqualStrings("2024-03-01T10:00:00Z", ws.created_at);
}

const webset_idle_json =
    \\{
    \\  "id": "ws_idle999",
    \\  "object": "webset",
    \\  "status": "idle",
    \\  "dashboardUrl": "https://dashboard.exa.ai/websets/ws_idle999",
    \\  "searches": [],
    \\  "enrichments": [],
    \\  "monitors": [],
    \\  "createdAt": "2024-01-15T08:00:00Z",
    \\  "updatedAt": "2024-01-15T08:30:00Z"
    \\}
;

test "parseWebset — idle status" {
    const allocator = std.testing.allocator;
    var ws = try websets_json.parseWebset(allocator, webset_idle_json);
    defer ws.deinit(allocator);

    try std.testing.expectEqualStrings("ws_idle999", ws.id);
    try std.testing.expectEqual(websets_types.WebsetStatus.idle, ws.status);
}

const list_websets_json =
    \\{
    \\  "data": [
    \\    {
    \\      "id": "ws_first",
    \\      "object": "webset",
    \\      "status": "idle",
    \\      "dashboardUrl": "https://dashboard.exa.ai/websets/ws_first",
    \\      "searches": [],
    \\      "enrichments": [],
    \\      "monitors": [],
    \\      "createdAt": "2024-01-01T00:00:00Z",
    \\      "updatedAt": "2024-01-01T00:00:00Z"
    \\    },
    \\    {
    \\      "id": "ws_second",
    \\      "object": "webset",
    \\      "status": "paused",
    \\      "dashboardUrl": "https://dashboard.exa.ai/websets/ws_second",
    \\      "searches": [],
    \\      "enrichments": [],
    \\      "monitors": [],
    \\      "createdAt": "2024-02-01T00:00:00Z",
    \\      "updatedAt": "2024-02-01T00:00:00Z"
    \\    }
    \\  ],
    \\  "hasMore": true,
    \\  "nextCursor": "cursor_xyz"
    \\}
;

test "parseListWebsetsResponse — two websets with cursor" {
    const allocator = std.testing.allocator;
    const result = try websets_json.parseListWebsetsResponse(allocator, list_websets_json);
    defer {
        for (result.data) |*ws| ws.deinit(allocator);
        allocator.free(result.data);
        if (result.next_cursor) |nc| allocator.free(nc);
    }

    try std.testing.expectEqual(@as(usize, 2), result.data.len);
    try std.testing.expectEqualStrings("ws_first", result.data[0].id);
    try std.testing.expectEqualStrings("ws_second", result.data[1].id);
    try std.testing.expectEqual(websets_types.WebsetStatus.paused, result.data[1].status);
    try std.testing.expect(result.has_more);
    try std.testing.expectEqualStrings("cursor_xyz", result.next_cursor.?);
}

// ---------------------------------------------------------------------------
// Parsing tests — WebsetItem
// ---------------------------------------------------------------------------

const company_item_json =
    \\{
    \\  "id": "item_co_001",
    \\  "object": "webset_item",
    \\  "source": "search",
    \\  "sourceId": "src_001",
    \\  "websetId": "ws_abc123",
    \\  "entityType": "company",
    \\  "properties": {
    \\    "url": "https://acme.example.com",
    \\    "description": "Acme Corp makes anvils",
    \\    "content": null,
    \\    "name": "Acme Corp",
    \\    "industry": "Manufacturing"
    \\  },
    \\  "evaluations": [],
    \\  "enrichments": [],
    \\  "createdAt": "2024-03-01T12:00:00Z",
    \\  "updatedAt": "2024-03-01T12:00:00Z"
    \\}
;

test "parseWebsetItem — company entity" {
    const allocator = std.testing.allocator;
    var item = try websets_json.parseWebsetItem(allocator, company_item_json);
    defer item.deinit(allocator);

    try std.testing.expectEqualStrings("item_co_001", item.id);
    try std.testing.expectEqualStrings("ws_abc123", item.webset_id);
    try std.testing.expectEqual(websets_types.Source.search, item.source);
    switch (item.properties) {
        .company => |c| {
            try std.testing.expectEqualStrings("https://acme.example.com", c.url);
            try std.testing.expectEqualStrings("Acme Corp", c.name.?);
            try std.testing.expectEqualStrings("Manufacturing", c.industry.?);
        },
        else => return error.UnexpectedEntityType,
    }
}

const person_item_json =
    \\{
    \\  "id": "item_person_001",
    \\  "object": "webset_item",
    \\  "source": "import",
    \\  "sourceId": "imp_001",
    \\  "websetId": "ws_abc123",
    \\  "entityType": "person",
    \\  "properties": {
    \\    "url": "https://linkedin.com/in/janedoe",
    \\    "description": "Software engineer",
    \\    "content": null,
    \\    "name": "Jane Doe",
    \\    "location": "San Francisco, CA"
    \\  },
    \\  "evaluations": [],
    \\  "enrichments": [],
    \\  "createdAt": "2024-03-05T09:00:00Z",
    \\  "updatedAt": "2024-03-05T09:00:00Z"
    \\}
;

test "parseWebsetItem — person entity" {
    const allocator = std.testing.allocator;
    var item = try websets_json.parseWebsetItem(allocator, person_item_json);
    defer item.deinit(allocator);

    switch (item.properties) {
        .person => |p| {
            try std.testing.expectEqualStrings("Jane Doe", p.name.?);
            try std.testing.expectEqualStrings("San Francisco, CA", p.location.?);
        },
        else => return error.UnexpectedEntityType,
    }
}

const article_item_json =
    \\{
    \\  "id": "item_art_001",
    \\  "object": "webset_item",
    \\  "source": "search",
    \\  "sourceId": "src_art",
    \\  "websetId": "ws_news",
    \\  "entityType": "article",
    \\  "properties": {
    \\    "url": "https://techcrunch.com/2024/01/01/ai-news",
    \\    "description": "Latest AI developments",
    \\    "content": "Full article text...",
    \\    "title": "AI in 2024",
    \\    "publishedDate": "2024-01-01"
    \\  },
    \\  "evaluations": [],
    \\  "enrichments": [],
    \\  "createdAt": "2024-01-01T12:00:00Z",
    \\  "updatedAt": "2024-01-01T12:00:00Z"
    \\}
;

test "parseWebsetItem — article entity" {
    const allocator = std.testing.allocator;
    var item = try websets_json.parseWebsetItem(allocator, article_item_json);
    defer item.deinit(allocator);

    switch (item.properties) {
        .article => |a| {
            try std.testing.expectEqualStrings("AI in 2024", a.title.?);
            try std.testing.expectEqualStrings("2024-01-01", a.published_date.?);
            try std.testing.expectEqualStrings("Full article text...", a.content.?);
        },
        else => return error.UnexpectedEntityType,
    }
}

const research_paper_item_json =
    \\{
    \\  "id": "item_paper_001",
    \\  "object": "webset_item",
    \\  "source": "search",
    \\  "sourceId": "src_paper",
    \\  "websetId": "ws_research",
    \\  "entityType": "research_paper",
    \\  "properties": {
    \\    "url": "https://arxiv.org/abs/2401.00001",
    \\    "description": "Novel attention mechanism",
    \\    "content": null,
    \\    "title": "Flash Attention 3",
    \\    "authors": ["Alice Smith", "Bob Jones"]
    \\  },
    \\  "evaluations": [],
    \\  "enrichments": [],
    \\  "createdAt": "2024-01-10T00:00:00Z",
    \\  "updatedAt": "2024-01-10T00:00:00Z"
    \\}
;

test "parseWebsetItem — research_paper entity with authors" {
    const allocator = std.testing.allocator;
    var item = try websets_json.parseWebsetItem(allocator, research_paper_item_json);
    defer item.deinit(allocator);

    switch (item.properties) {
        .research_paper => |rp| {
            try std.testing.expectEqualStrings("Flash Attention 3", rp.title.?);
            try std.testing.expectEqual(@as(usize, 2), rp.authors.?.len);
            try std.testing.expectEqualStrings("Alice Smith", rp.authors.?[0]);
            try std.testing.expectEqualStrings("Bob Jones", rp.authors.?[1]);
        },
        else => return error.UnexpectedEntityType,
    }
}

const list_items_json =
    \\{
    \\  "data": [
    \\    {
    \\      "id": "item_a",
    \\      "object": "webset_item",
    \\      "source": "search",
    \\      "sourceId": "s1",
    \\      "websetId": "ws_1",
    \\      "entityType": "company",
    \\      "properties": {"url":"https://a.com","description":"A","content":null,"name":"A Corp","industry":null},
    \\      "evaluations": [],
    \\      "enrichments": [],
    \\      "createdAt": "2024-01-01T00:00:00Z",
    \\      "updatedAt": "2024-01-01T00:00:00Z"
    \\    }
    \\  ],
    \\  "hasMore": false
    \\}
;

test "parseListWebsetItemResponse" {
    const allocator = std.testing.allocator;
    const result = try websets_json.parseListWebsetItemResponse(allocator, list_items_json);
    defer {
        for (result.data) |*it| it.deinit(allocator);
        allocator.free(result.data);
        if (result.next_cursor) |nc| allocator.free(nc);
    }

    try std.testing.expectEqual(@as(usize, 1), result.data.len);
    try std.testing.expectEqualStrings("item_a", result.data[0].id);
    try std.testing.expect(!result.has_more);
    try std.testing.expect(result.next_cursor == null);
}

// ---------------------------------------------------------------------------
// Parsing tests — WebsetSearch
// ---------------------------------------------------------------------------

const webset_search_json =
    \\{
    \\  "id": "wss_001",
    \\  "object": "webset_search",
    \\  "websetId": "ws_abc123",
    \\  "status": "completed",
    \\  "query": "AI startups in London",
    \\  "entity": "company",
    \\  "criteria": [
    \\    {"description": "Must be profitable", "successRate": 0.75}
    \\  ],
    \\  "count": 20,
    \\  "progress": {"found": 20, "completion": 100},
    \\  "createdAt": "2024-03-01T10:00:00Z",
    \\  "updatedAt": "2024-03-01T10:30:00Z"
    \\}
;

test "parseWebsetSearch — completed" {
    const allocator = std.testing.allocator;
    var search = try websets_json.parseWebsetSearch(allocator, webset_search_json);
    defer search.deinit(allocator);

    try std.testing.expectEqualStrings("wss_001", search.id);
    try std.testing.expectEqualStrings("ws_abc123", search.webset_id);
    try std.testing.expectEqual(websets_types.WebsetSearchStatus.completed, search.status);
    try std.testing.expectEqualStrings("AI startups in London", search.query);
    try std.testing.expectEqual(@as(usize, 1), search.criteria.len);
    try std.testing.expectEqualStrings("Must be profitable", search.criteria[0].description);
    try std.testing.expectApproxEqAbs(@as(f64, 0.75), search.criteria[0].success_rate, 0.001);
    try std.testing.expectApproxEqAbs(@as(f64, 20), search.progress.found, 0.001);
}

const list_searches_json =
    \\{
    \\  "data": [
    \\    {
    \\      "id": "wss_a",
    \\      "object": "webset_search",
    \\      "websetId": "ws_1",
    \\      "status": "created",
    \\      "query": "query a",
    \\      "entity": "person",
    \\      "criteria": [],
    \\      "count": 10,
    \\      "progress": {"found": 0, "completion": 0},
    \\      "createdAt": "2024-01-01T00:00:00Z",
    \\      "updatedAt": "2024-01-01T00:00:00Z"
    \\    }
    \\  ],
    \\  "hasMore": false
    \\}
;

test "parseListWebsetSearchesResponse" {
    const allocator = std.testing.allocator;
    const result = try websets_json.parseListWebsetSearchesResponse(allocator, list_searches_json);
    defer {
        for (result.data) |*s| s.deinit(allocator);
        allocator.free(result.data);
        if (result.next_cursor) |nc| allocator.free(nc);
    }

    try std.testing.expectEqual(@as(usize, 1), result.data.len);
    try std.testing.expectEqualStrings("wss_a", result.data[0].id);
    try std.testing.expectEqual(websets_types.WebsetSearchStatus.created, result.data[0].status);
}

// ---------------------------------------------------------------------------
// Parsing tests — WebsetEnrichment
// ---------------------------------------------------------------------------

const enrichment_json =
    \\{
    \\  "id": "enr_001",
    \\  "object": "webset_enrichment",
    \\  "websetId": "ws_abc123",
    \\  "status": "pending",
    \\  "description": "Is this company profitable?",
    \\  "format": "options",
    \\  "options": [
    \\    {"label": "yes"},
    \\    {"label": "no"},
    \\    {"label": "unknown"}
    \\  ],
    \\  "createdAt": "2024-03-01T10:00:00Z",
    \\  "updatedAt": "2024-03-01T10:00:00Z"
    \\}
;

test "parseWebsetEnrichment — with options" {
    const allocator = std.testing.allocator;
    var enr = try websets_json.parseWebsetEnrichment(allocator, enrichment_json);
    defer enr.deinit(allocator);

    try std.testing.expectEqualStrings("enr_001", enr.id);
    try std.testing.expectEqual(websets_types.WebsetEnrichmentStatus.pending, enr.status);
    try std.testing.expectEqualStrings("Is this company profitable?", enr.description);
    try std.testing.expectEqual(websets_types.EnrichmentFormat.options, enr.format.?);
    try std.testing.expectEqual(@as(usize, 3), enr.options.?.len);
    try std.testing.expectEqualStrings("yes", enr.options.?[0].label);
}

const list_enrichments_json =
    \\{
    \\  "data": [
    \\    {
    \\      "id": "enr_x",
    \\      "object": "webset_enrichment",
    \\      "websetId": "ws_1",
    \\      "status": "completed",
    \\      "description": "Revenue tier",
    \\      "format": "options",
    \\      "createdAt": "2024-01-01T00:00:00Z",
    \\      "updatedAt": "2024-01-02T00:00:00Z"
    \\    }
    \\  ],
    \\  "hasMore": false
    \\}
;

test "parseListWebsetEnrichmentsResponse" {
    const allocator = std.testing.allocator;
    const result = try websets_json.parseListWebsetEnrichmentsResponse(allocator, list_enrichments_json);
    defer {
        for (result.data) |*e| e.deinit(allocator);
        allocator.free(result.data);
        if (result.next_cursor) |nc| allocator.free(nc);
    }

    try std.testing.expectEqual(@as(usize, 1), result.data.len);
    try std.testing.expectEqualStrings("enr_x", result.data[0].id);
    try std.testing.expectEqual(websets_types.WebsetEnrichmentStatus.completed, result.data[0].status);
}

// ---------------------------------------------------------------------------
// Parsing tests — Webhook
// ---------------------------------------------------------------------------

const webhook_json =
    \\{
    \\  "id": "wh_001",
    \\  "object": "webset_webhook",
    \\  "websetId": "ws_abc123",
    \\  "url": "https://example.com/hooks/exa",
    \\  "status": "active",
    \\  "events": ["webset.item.created", "webset.idle"],
    \\  "createdAt": "2024-03-01T00:00:00Z",
    \\  "updatedAt": "2024-03-01T00:00:00Z"
    \\}
;

test "parseWebhook — active status, two events" {
    const allocator = std.testing.allocator;
    var wh = try websets_json.parseWebhook(allocator, webhook_json);
    defer wh.deinit(allocator);

    try std.testing.expectEqualStrings("wh_001", wh.id);
    try std.testing.expectEqualStrings("https://example.com/hooks/exa", wh.url);
    try std.testing.expectEqual(websets_types.WebhookStatus.active, wh.status);
    try std.testing.expectEqual(@as(usize, 2), wh.events.len);
}

// ---------------------------------------------------------------------------
// Parsing tests — PreviewWebsetResponse
// ---------------------------------------------------------------------------

const preview_json =
    \\{
    \\  "search": {
    \\    "query": "AI startups",
    \\    "entity": "company",
    \\    "count": 10,
    \\    "criteria": [
    \\      {"description": "Must have raised Series A", "successRate": 0.9}
    \\    ]
    \\  },
    \\  "enrichments": [
    \\    {
    \\      "description": "Is profitable?",
    \\      "format": "options"
    \\    }
    \\  ]
    \\}
;

test "parsePreviewWebsetResponse" {
    const allocator = std.testing.allocator;
    var result = try websets_json.parsePreviewWebsetResponse(allocator, preview_json);
    defer result.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 1), result.search.criteria.len);
    try std.testing.expectEqualStrings("Must have raised Series A", result.search.criteria[0].description);
    try std.testing.expectEqual(@as(usize, 1), result.enrichments.len);
    try std.testing.expectEqualStrings("Is profitable?", result.enrichments[0].description);
}

// ---------------------------------------------------------------------------
// Parsing tests — Websets-subsystem Monitor
// ---------------------------------------------------------------------------

const webset_monitor_json =
    \\{
    \\  "id": "mon_ws_001",
    \\  "object": "webset_monitor",
    \\  "websetId": "ws_abc123",
    \\  "status": "enabled",
    \\  "cadence": {
    \\    "cron": "0 8 * * *",
    \\    "timezone": "UTC"
    \\  },
    \\  "behavior": {
    \\    "search": {
    \\      "config": {"count": 10}
    \\    }
    \\  },
    \\  "createdAt": "2024-03-01T00:00:00Z",
    \\  "updatedAt": "2024-03-01T00:00:00Z"
    \\}
;

test "parseMonitor (websets subsystem)" {
    const allocator = std.testing.allocator;
    var mon = try websets_json.parseMonitor(allocator, webset_monitor_json);
    defer mon.deinit(allocator);

    try std.testing.expectEqualStrings("mon_ws_001", mon.id);
    try std.testing.expectEqualStrings("ws_abc123", mon.webset_id);
    try std.testing.expectEqual(websets_types.MonitorStatus.enabled, mon.status);
    try std.testing.expectEqualStrings("0 8 * * *", mon.cadence.cron);
    try std.testing.expectEqualStrings("UTC", mon.cadence.timezone.?);
}

// ---------------------------------------------------------------------------
// Parsing tests — Import
// ---------------------------------------------------------------------------

const import_json =
    \\{
    \\  "id": "imp_001",
    \\  "object": "webset_import",
    \\  "status": "completed",
    \\  "format": "csv",
    \\  "entity": "company",
    \\  "title": "My CSV Import",
    \\  "count": 150,
    \\  "createdAt": "2024-03-01T00:00:00Z",
    \\  "updatedAt": "2024-03-01T01:00:00Z"
    \\}
;

test "parseImport — completed csv" {
    const allocator = std.testing.allocator;
    const imp = try websets_json.parseImport(allocator, import_json);
    defer imp.deinit(allocator);

    try std.testing.expectEqualStrings("imp_001", imp.id);
    try std.testing.expectEqualStrings("My CSV Import", imp.title);
    try std.testing.expectEqual(websets_types.ImportStatus.completed, imp.status);
    try std.testing.expectEqual(websets_types.ImportFormat.csv, imp.format);
    try std.testing.expectApproxEqAbs(@as(f64, 150), imp.count, 0.001);
}

// ---------------------------------------------------------------------------
// Top-level alias smoke test
// ---------------------------------------------------------------------------

test "top-level re-exports — websets types are reachable" {
    _ = exa.Webset;
    _ = exa.WebsetItem;
    _ = exa.WebsetSearch;
    _ = exa.WebsetEnrichment;
    _ = exa.Webhook;
    _ = exa.WebsetImport;
    _ = exa.WebsetMonitor;
    _ = exa.WebsetMonitorRun;
    _ = exa.ListWebsetsResponse;
    _ = exa.ListWebsetItemResponse;
    _ = exa.ListWebsetSearchesResponse;
    _ = exa.ListWebsetEnrichmentsResponse;
    _ = exa.ListWebhooksResponse;
    _ = exa.PreviewWebsetResponse;
    _ = exa.WebsetEvent;
    _ = exa.WebsetItemCreatedEvent;
    _ = exa.WebsetsClient;
    _ = exa.WebsetItemsClient;
    _ = exa.WebsetSearchesClient;
    _ = exa.WebsetEnrichmentsClient;
    _ = exa.WebsetWebhooksClient;
    _ = exa.WebsetMonitorsSubClient;
    _ = exa.WebsetImportsClient;
    _ = exa.WebsetEventsClient;
}
