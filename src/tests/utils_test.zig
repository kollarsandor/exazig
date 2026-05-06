const std = @import("std");
const exa = @import("exa");
const utils = exa.utils;

test "snakeToCamel basic" {
    const allocator = std.testing.allocator;

    const r1 = try utils.snakeToCamel(allocator, "hello_world");
    defer allocator.free(r1);
    try std.testing.expectEqualStrings("helloWorld", r1);

    const r2 = try utils.snakeToCamel(allocator, "foo_bar_baz");
    defer allocator.free(r2);
    try std.testing.expectEqualStrings("fooBarBaz", r2);

    const r3 = try utils.snakeToCamel(allocator, "already");
    defer allocator.free(r3);
    try std.testing.expectEqualStrings("already", r3);
}

test "snakeToCamel special cases" {
    const allocator = std.testing.allocator;

    const r1 = try utils.snakeToCamel(allocator, "schema_");
    defer allocator.free(r1);
    try std.testing.expectEqualStrings("$schema", r1);

    const r2 = try utils.snakeToCamel(allocator, "not_");
    defer allocator.free(r2);
    try std.testing.expectEqualStrings("not", r2);
}

test "camelToSnake basic" {
    const allocator = std.testing.allocator;

    const r1 = try utils.camelToSnake(allocator, "helloWorld");
    defer allocator.free(r1);
    try std.testing.expectEqualStrings("hello_world", r1);

    const r2 = try utils.camelToSnake(allocator, "fooBarBaz");
    defer allocator.free(r2);
    try std.testing.expectEqualStrings("foo_bar_baz", r2);

    const r3 = try utils.camelToSnake(allocator, "already");
    defer allocator.free(r3);
    try std.testing.expectEqualStrings("already", r3);
}

test "camelToSnake acronyms" {
    const allocator = std.testing.allocator;

    const r1 = try utils.camelToSnake(allocator, "numResults");
    defer allocator.free(r1);
    try std.testing.expectEqualStrings("num_results", r1);

    const r2 = try utils.camelToSnake(allocator, "maxAgeHours");
    defer allocator.free(r2);
    try std.testing.expectEqualStrings("max_age_hours", r2);
}

test "JsonObject toCamelCase omits null" {
    const allocator = std.testing.allocator;

    // Parse JSON into an owned value so std.json manages all memory
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator,
        \\{"foo_bar":"hello","null_field":null}
    , .{});
    defer parsed.deinit();

    const obj = utils.JsonObject{ .map = parsed.value.object };
    const camel = try obj.toCamelCase(allocator, &.{});
    defer camel.deinit(allocator);

    try std.testing.expect(camel.map.get("fooBar") != null);
    try std.testing.expect(camel.map.get("nullField") == null);
}

test "JsonObject toCamelCase skip_keys" {
    const allocator = std.testing.allocator;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator,
        \\{"skip_me":{"nested_key":"value"},"convert_me":"yes"}
    , .{});
    defer parsed.deinit();

    const skip_keys = [_][]const u8{"skip_me"};
    const obj = utils.JsonObject{ .map = parsed.value.object };
    const camel = try obj.toCamelCase(allocator, &skip_keys);
    defer camel.deinit(allocator);

    // "convert_me" → "convertMe"
    try std.testing.expect(camel.map.get("convertMe") != null);
    // "skip_me" → "skipMe" but its nested keys must NOT be converted
    const skipped = camel.map.get("skipMe");
    try std.testing.expect(skipped != null);
    if (skipped) |sv| {
        if (sv == .object) {
            try std.testing.expect(sv.object.get("nested_key") != null);
            try std.testing.expect(sv.object.get("nestedKey") == null);
        }
    }
}

test "JsonObject toSnakeCase recursive" {
    const allocator = std.testing.allocator;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator,
        \\{"outerKey":{"nestedKey":"val"}}
    , .{});
    defer parsed.deinit();

    const obj = utils.JsonObject{ .map = parsed.value.object };
    const snake = try obj.toSnakeCase(allocator);
    defer snake.deinit(allocator);

    try std.testing.expect(snake.map.get("outer_key") != null);
    const outer = snake.map.get("outer_key").?;
    try std.testing.expect(outer == .object);
    try std.testing.expect(outer.object.get("nested_key") != null);
}
