/// Basic Exa search example.
/// Run with: zig build run-search
/// Requires EXA_API_KEY environment variable.
const std = @import("std");
const exa = @import("exa");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Reads EXA_API_KEY from environment automatically when api_key is null.
    var client = try exa.Exa.init(allocator, null, null, null);
    defer client.deinit();

    std.debug.print("Searching Exa...\n\n", .{});

    const results = try client.search(allocator, .{
        .query = "Zig programming language latest news",
        .num_results = 5,
        .search_type = .neural,
        .contents = .{ .options = .{
            .text = .{ .options = .{ .max_characters = 300 } },
            .summary = .{ .options = .{ .query = "What is this page about?" } },
        } },
    });
    defer results.deinit();

    std.debug.print("Found {} result(s)\n\n", .{results.results.len});

    for (results.results, 1..) |r, i| {
        std.debug.print("{}. {s}\n   {s}\n", .{
            i,
            r.title orelse "(no title)",
            r.url,
        });
        if (r.summary) |s| {
            std.debug.print("   Summary: {s}\n", .{s});
        }
        if (r.score) |score| {
            std.debug.print("   Score:   {d:.4}\n", .{score});
        }
        std.debug.print("\n", .{});
    }

    if (results.cost_dollars) |cost| {
        std.debug.print("Cost: ${d:.6}\n", .{cost.total});
    }
}
