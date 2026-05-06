/// Utility functions for exazig: case conversion and JSON object helpers.
const std = @import("std");

/// Converts a snake_case string to camelCase.
/// Special cases:
///   "schema_"  → "$schema"
///   "not_"     → "not"
/// Returns an owned slice; caller must free.
pub fn snakeToCamel(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    if (std.mem.eql(u8, input, "schema_")) {
        const result = try allocator.dupe(u8, "$schema");
        return result;
    }
    if (std.mem.eql(u8, input, "not_")) {
        const result = try allocator.dupe(u8, "not");
        return result;
    }

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var first_segment = true;
    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '_') {
            i += 1;
            first_segment = false;
            continue;
        }
        if (!first_segment) {
            // Capitalise first character of this segment
            if (i < input.len) {
                try out.append(std.ascii.toUpper(input[i]));
                i += 1;
                // Copy rest of segment until next '_'
                while (i < input.len and input[i] != '_') {
                    try out.append(input[i]);
                    i += 1;
                }
            }
        } else {
            // Copy first segment verbatim until '_'
            while (i < input.len and input[i] != '_') {
                try out.append(input[i]);
                i += 1;
            }
        }
    }

    return out.toOwnedSlice();
}

/// Converts a camelCase string to snake_case.
/// Inserts '_' before any uppercase letter that follows a lowercase letter or digit,
/// and before any uppercase letter that is followed by a lowercase letter and preceded
/// by an uppercase letter. Lowercases the entire result.
/// Returns an owned slice; caller must free.
pub fn camelToSnake(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    for (input, 0..) |c, idx| {
        if (std.ascii.isUpper(c)) {
            const prev_lower_or_digit = idx > 0 and (std.ascii.isLower(input[idx - 1]) or std.ascii.isDigit(input[idx - 1]));
            const prev_upper = idx > 0 and std.ascii.isUpper(input[idx - 1]);
            const next_lower = idx + 1 < input.len and std.ascii.isLower(input[idx + 1]);

            if (prev_lower_or_digit or (prev_upper and next_lower)) {
                try out.append('_');
            }
            try out.append(std.ascii.toLower(c));
        } else {
            try out.append(c);
        }
    }

    return out.toOwnedSlice();
}

/// A lightweight wrapper around std.json.ObjectMap with helpers for key conversion.
pub const JsonObject = struct {
    map: std.json.ObjectMap,

    /// Returns a new JsonObject with all keys recursively converted to camelCase.
    /// Keys present in skip_keys have their values copied without recursive key conversion.
    /// Entries whose value is .null are omitted.
    pub fn toCamelCase(self: JsonObject, allocator: std.mem.Allocator, skip_keys: []const []const u8) error{OutOfMemory}!JsonObject {
        var new_map = std.json.ObjectMap.init(allocator);
        errdefer {
            var it = new_map.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.key_ptr.*);
            }
            new_map.deinit();
        }

        var it = self.map.iterator();
        while (it.next()) |entry| {
            const key = entry.key_ptr.*;
            const val = entry.value_ptr.*;

            // Skip null values
            if (val == .null) continue;

            const new_key = try snakeToCamel(allocator, key);
            errdefer allocator.free(new_key);

            // Check if this key is in skip_keys
            var is_skip = false;
            for (skip_keys) |sk| {
                if (std.mem.eql(u8, key, sk)) {
                    is_skip = true;
                    break;
                }
            }

            const new_val = if (!is_skip)
                try convertValueToCamelCase(allocator, val, skip_keys)
            else
                try cloneValue(allocator, val);

            try new_map.put(new_key, new_val);
        }

        return JsonObject{ .map = new_map };
    }

    /// Returns a new JsonObject with all keys recursively converted to snake_case.
    pub fn toSnakeCase(self: JsonObject, allocator: std.mem.Allocator) error{OutOfMemory}!JsonObject {
        var new_map = std.json.ObjectMap.init(allocator);
        errdefer {
            var it = new_map.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.key_ptr.*);
            }
            new_map.deinit();
        }

        var it = self.map.iterator();
        while (it.next()) |entry| {
            const key = entry.key_ptr.*;
            const val = entry.value_ptr.*;

            const new_key = try camelToSnake(allocator, key);
            errdefer allocator.free(new_key);

            const new_val = try convertValueToSnakeCase(allocator, val);
            try new_map.put(new_key, new_val);
        }

        return JsonObject{ .map = new_map };
    }

    /// Frees all owned memory in this JsonObject.
    pub fn deinit(self: JsonObject, allocator: std.mem.Allocator) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            freeValue(allocator, entry.value_ptr.*);
        }
        var mutable = self.map;
        mutable.deinit();
    }
};

fn convertValueToCamelCase(allocator: std.mem.Allocator, val: std.json.Value, skip_keys: []const []const u8) error{OutOfMemory}!std.json.Value {
    switch (val) {
        .object => |obj| {
            var inner = JsonObject{ .map = obj };
            const converted = try inner.toCamelCase(allocator, skip_keys);
            return std.json.Value{ .object = converted.map };
        },
        .array => |arr| {
            var new_arr = std.json.Array.init(allocator);
            errdefer new_arr.deinit();
            for (arr.items) |item| {
                const new_item = try convertValueToCamelCase(allocator, item, skip_keys);
                try new_arr.append(new_item);
            }
            return std.json.Value{ .array = new_arr };
        },
        else => return try cloneValue(allocator, val),
    }
}

fn convertValueToSnakeCase(allocator: std.mem.Allocator, val: std.json.Value) error{OutOfMemory}!std.json.Value {
    switch (val) {
        .object => |obj| {
            var inner = JsonObject{ .map = obj };
            const converted = try inner.toSnakeCase(allocator);
            return std.json.Value{ .object = converted.map };
        },
        .array => |arr| {
            var new_arr = std.json.Array.init(allocator);
            errdefer new_arr.deinit();
            for (arr.items) |item| {
                const new_item = try convertValueToSnakeCase(allocator, item);
                try new_arr.append(new_item);
            }
            return std.json.Value{ .array = new_arr };
        },
        else => return try cloneValue(allocator, val),
    }
}

/// Deep-clones a std.json.Value, allocating new strings/arrays/objects.
pub fn cloneValue(allocator: std.mem.Allocator, val: std.json.Value) !std.json.Value {
    switch (val) {
        .null => return .null,
        .bool => |b| return .{ .bool = b },
        .integer => |n| return .{ .integer = n },
        .float => |f| return .{ .float = f },
        .number_string => |s| return .{ .number_string = try allocator.dupe(u8, s) },
        .string => |s| return .{ .string = try allocator.dupe(u8, s) },
        .array => |arr| {
            var new_arr = std.json.Array.init(allocator);
            errdefer new_arr.deinit();
            for (arr.items) |item| {
                try new_arr.append(try cloneValue(allocator, item));
            }
            return .{ .array = new_arr };
        },
        .object => |obj| {
            var new_obj = std.json.ObjectMap.init(allocator);
            errdefer {
                var it2 = new_obj.iterator();
                while (it2.next()) |entry| allocator.free(entry.key_ptr.*);
                new_obj.deinit();
            }
            var it = obj.iterator();
            while (it.next()) |entry| {
                const new_key = try allocator.dupe(u8, entry.key_ptr.*);
                errdefer allocator.free(new_key);
                const new_val = try cloneValue(allocator, entry.value_ptr.*);
                try new_obj.put(new_key, new_val);
            }
            return .{ .object = new_obj };
        },
    }
}

/// Recursively frees a std.json.Value that was allocated with the given allocator.
pub fn freeValue(allocator: std.mem.Allocator, val: std.json.Value) void {
    switch (val) {
        .string => |s| allocator.free(s),
        .number_string => |s| allocator.free(s),
        .array => |arr| {
            for (arr.items) |item| freeValue(allocator, item);
            var mutable = arr;
            mutable.deinit();
        },
        .object => |obj| {
            var it = obj.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.key_ptr.*);
                freeValue(allocator, entry.value_ptr.*);
            }
            var mutable = obj;
            mutable.deinit();
        },
        else => {},
    }
}

/// Returns the library version string.
pub fn getPackageVersion() []const u8 {
    return "2.11.0";
}
