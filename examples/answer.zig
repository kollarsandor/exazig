/// Exa answer + streaming answer example.
/// Run with: zig build run-answer
/// Requires EXA_API_KEY environment variable.
const std = @import("std");
const exa = @import("exa");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try exa.Exa.init(allocator, null, null, null);
    defer client.deinit();

    const question = "What are the main features of the Zig 0.14.0 release?";
    std.debug.print("Question: {s}\n\n", .{question});

    // --- Non-streaming answer ---

    const ans = try client.answer(allocator, question, null, null);
    defer ans.deinit(allocator);

    std.debug.print("=== Answer ===\n", .{});
    switch (ans.answer) {
        .text => |t| std.debug.print("{s}\n", .{t}),
        .object => std.debug.print("(structured JSON answer)\n", .{}),
    }

    if (ans.citations.len > 0) {
        std.debug.print("\n=== Citations ({}) ===\n", .{ans.citations.len});
        for (ans.citations, 1..) |c, i| {
            std.debug.print("{}. {s}\n   {s}\n", .{
                i,
                c.title orelse "(no title)",
                c.url,
            });
        }
    }

    std.debug.print("\n=== Streaming Answer ===\n", .{});

    // --- Streaming answer (SSE) ---

    var stream = try client.streamAnswer(allocator, question, null, null);
    defer stream.close();

    while (try stream.next()) |chunk| {
        defer chunk.deinit(allocator);
        if (chunk.content) |text| {
            std.debug.print("{s}", .{text});
        }
    }
    std.debug.print("\n", .{});
}
