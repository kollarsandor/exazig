const std = @import("std");
const exa = @import("exa");
const types = exa.types;
const json_utils = exa.json_utils;

test "serializeSearchParams defaults" {
    const allocator = std.testing.allocator;

    const params = types.SearchParams{
        .query = "zig programming language",
    };

    const body = try json_utils.serializeSearchParams(allocator, params);
    defer allocator.free(body);

    try std.testing.expect(std.mem.indexOf(u8, body, "\"query\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, body, "zig programming language") != null);
}

test "serializeSearchParams no contents" {
    const allocator = std.testing.allocator;

    const params = types.SearchParams{
        .query = "test",
        .contents = .{ .disabled = {} },
    };

    const body = try json_utils.serializeSearchParams(allocator, params);
    defer allocator.free(body);

    try std.testing.expect(std.mem.indexOf(u8, body, "\"contents\"") == null);
}

test "serializeSearchParams with contents" {
    const allocator = std.testing.allocator;

    const params = types.SearchParams{
        .query = "test",
        .contents = .{ .options = types.ContentsOptions{
            .text = .{ .options = types.TextContentsOptions{ .max_characters = 10_000 } },
        } },
    };

    const body = try json_utils.serializeSearchParams(allocator, params);
    defer allocator.free(body);

    try std.testing.expect(std.mem.indexOf(u8, body, "\"contents\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, body, "\"maxCharacters\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, body, "10000") != null);
}

test "parseSearchResponse full" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "results": [
        \\    {
        \\      "url": "https://example.com",
        \\      "id": "result-1",
        \\      "title": "Example Page",
        \\      "score": 0.95,
        \\      "text": "Some text content here"
        \\    }
        \\  ],
        \\  "resolvedSearchType": "neural",
        \\  "costDollars": {
        \\    "total": 0.001,
        \\    "search": { "neural": 0.001, "keyword": null }
        \\  },
        \\  "statuses": [
        \\    { "id": "s1", "status": "ok", "source": "cache" }
        \\  ]
        \\}
    ;

    const response = try json_utils.parseSearchResponse(allocator, json_str);
    defer response.deinit();

    try std.testing.expectEqual(@as(usize, 1), response.results.len);
    try std.testing.expectEqualStrings("https://example.com", response.results[0].url);
    try std.testing.expectEqualStrings("result-1", response.results[0].id);
    try std.testing.expectEqualStrings("Example Page", response.results[0].title.?);
    try std.testing.expectApproxEqAbs(@as(f64, 0.95), response.results[0].score.?, 1e-6);
    try std.testing.expectEqualStrings("neural", response.resolved_search_type.?);
    try std.testing.expect(response.cost_dollars != null);
    try std.testing.expectApproxEqAbs(@as(f64, 0.001), response.cost_dollars.?.total, 1e-6);
    try std.testing.expect(response.statuses != null);
    try std.testing.expectEqual(@as(usize, 1), response.statuses.?.len);
    try std.testing.expectEqualStrings("s1", response.statuses.?[0].id);
}

test "parseAnswerResponse text" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "answer": "Zig is a general-purpose programming language.",
        \\  "citations": []
        \\}
    ;

    const response = try json_utils.parseAnswerResponse(allocator, json_str);
    defer response.deinit(allocator);

    switch (response.answer) {
        .text => |t| try std.testing.expectEqualStrings("Zig is a general-purpose programming language.", t),
        .object => return error.UnexpectedAnswerType,
    }
    try std.testing.expectEqual(@as(usize, 0), response.citations.len);
}

test "parseAnswerResponse object" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "answer": { "language": "Zig", "version": "0.14.0" },
        \\  "citations": []
        \\}
    ;

    const response = try json_utils.parseAnswerResponse(allocator, json_str);
    defer response.deinit(allocator);

    switch (response.answer) {
        .object => |_| {},
        .text => return error.UnexpectedAnswerType,
    }
}

test "parseSseChunk content" {
    const allocator = std.testing.allocator;

    const line = "data: {\"choices\":[{\"delta\":{\"content\":\"hello\"}}]}";
    const chunk = try json_utils.parseSseChunk(allocator, line);
    try std.testing.expect(chunk != null);
    defer chunk.?.deinit(allocator);
    try std.testing.expectEqualStrings("hello", chunk.?.content.?);
}

test "parseSseChunk citations" {
    const allocator = std.testing.allocator;

    const line = "data: {\"choices\":[{\"delta\":{\"content\":\"hi\"}}],\"citations\":[{\"id\":\"c1\",\"url\":\"https://example.com\",\"title\":\"Example\"}]}";
    const chunk = try json_utils.parseSseChunk(allocator, line);
    try std.testing.expect(chunk != null);
    defer chunk.?.deinit(allocator);
    try std.testing.expect(chunk.?.citations != null);
    try std.testing.expectEqual(@as(usize, 1), chunk.?.citations.?.len);
    try std.testing.expectEqualStrings("c1", chunk.?.citations.?[0].id);
    try std.testing.expectEqualStrings("https://example.com", chunk.?.citations.?[0].url);
}

test "parseSseChunk empty" {
    const allocator = std.testing.allocator;

    const line = "data: {\"choices\":[{\"delta\":{}}]}";
    const chunk = try json_utils.parseSseChunk(allocator, line);
    try std.testing.expect(chunk == null);
}

test "parseEntities company" {
    const allocator = std.testing.allocator;

    const json_str =
        \\[{
        \\  "type": "company",
        \\  "id": "ent-1",
        \\  "version": 1,
        \\  "properties": {
        \\    "name": "Acme Corp",
        \\    "workforce": { "total": 500 },
        \\    "headquarters": { "city": "San Francisco", "country": "US", "address": "123 Main St", "postalCode": "94105" },
        \\    "financials": { "revenueAnnual": 1000000, "fundingTotal": 5000000 },
        \\    "webTraffic": { "visitsMonthly": 100000 }
        \\  }
        \\}]
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const entities = try json_utils.parseEntities(allocator, parsed.value);
    try std.testing.expect(entities != null);
    defer {
        if (entities) |ents| {
            for (ents) |ent| {
                switch (ent) {
                    .company => |c| {
                        allocator.free(c.id);
                        if (c.properties.name) |v| allocator.free(v);
                        if (c.properties.headquarters) |hq| {
                            if (hq.address) |v| allocator.free(v);
                            if (hq.city) |v| allocator.free(v);
                            if (hq.postal_code) |v| allocator.free(v);
                            if (hq.country) |v| allocator.free(v);
                        }
                    },
                    .person => |p| allocator.free(p.id),
                }
            }
            allocator.free(ents);
        }
    }

    try std.testing.expectEqual(@as(usize, 1), entities.?.len);
    const company = entities.?[0].company;
    try std.testing.expectEqualStrings("ent-1", company.id);
    try std.testing.expectEqual(@as(i64, 500), company.properties.workforce.?.total.?);
    try std.testing.expectEqualStrings("San Francisco", company.properties.headquarters.?.city.?);
    try std.testing.expectEqual(@as(i64, 1000000), company.properties.financials.?.revenue_annual.?);
    try std.testing.expectEqual(@as(i64, 100000), company.properties.web_traffic.?.visits_monthly.?);
}

test "parseEntities person" {
    const allocator = std.testing.allocator;

    const json_str =
        \\[{
        \\  "type": "person",
        \\  "id": "person-1",
        \\  "version": 1,
        \\  "properties": {
        \\    "name": "Jane Doe",
        \\    "location": "New York",
        \\    "workHistory": [{
        \\      "title": "Engineer",
        \\      "location": "SF",
        \\      "dates": { "from": "2020-01-01", "to": "2023-01-01" },
        \\      "company": { "id": "co-1", "name": "TechCorp" }
        \\    }]
        \\  }
        \\}]
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const entities = try json_utils.parseEntities(allocator, parsed.value);
    try std.testing.expect(entities != null);
    defer {
        if (entities) |ents| {
            for (ents) |ent| {
                switch (ent) {
                    .person => |p| {
                        allocator.free(p.id);
                        if (p.properties.name) |v| allocator.free(v);
                        if (p.properties.location) |v| allocator.free(v);
                        if (p.properties.work_history) |wh| {
                            for (wh) |entry| {
                                if (entry.title) |v| allocator.free(v);
                                if (entry.location) |v| allocator.free(v);
                                if (entry.dates) |d| {
                                    if (d.from_date) |v| allocator.free(v);
                                    if (d.to_date) |v| allocator.free(v);
                                }
                                if (entry.company) |c| {
                                    if (c.id) |v| allocator.free(v);
                                    if (c.name) |v| allocator.free(v);
                                }
                            }
                            allocator.free(wh);
                        }
                    },
                    .company => |c| allocator.free(c.id),
                }
            }
            allocator.free(ents);
        }
    }

    try std.testing.expectEqual(@as(usize, 1), entities.?.len);
    const person = entities.?[0].person;
    try std.testing.expectEqualStrings("person-1", person.id);
    try std.testing.expect(person.properties.work_history != null);
    const wh = person.properties.work_history.?;
    try std.testing.expectEqual(@as(usize, 1), wh.len);
    try std.testing.expectEqualStrings("Engineer", wh[0].title.?);
    try std.testing.expectEqualStrings("2020-01-01", wh[0].dates.?.from_date.?);
    try std.testing.expectEqualStrings("TechCorp", wh[0].company.?.name.?);
}
