/// Research subsystem example: create a task, poll until finished, print output.
/// Run with: zig build run-research
/// Requires EXA_API_KEY environment variable.
///
/// NOTE: ResearchDto has no deinit — an ArenaAllocator is used so all
/// allocations from research calls are freed together at scope exit.
const std = @import("std");
const exa = @import("exa");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const gpa_alloc = gpa.allocator();

    var client = try exa.Exa.init(gpa_alloc, null, null, null);
    defer client.deinit();

    // Use an arena for all research API calls — ResearchDto has no deinit().
    var arena = std.heap.ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const allocator = arena.allocator();

    const instructions =
        "What are the most significant AI safety research organizations? " ++
        "Provide a brief summary of each including their founding year, focus area, and key outputs.";

    std.debug.print("=== Creating research task ===\n", .{});
    std.debug.print("Instructions: {s}\n\n", .{instructions});

    // Create returns a ResearchDto tagged union.
    const created = try client.research.create(allocator, .{
        .model = .exa_research,
        .instructions = instructions,
    });

    // Extract the research_id regardless of which variant we received.
    const research_id: []const u8 = switch (created) {
        inline else => |v| v.base.research_id,
    };

    std.debug.print("Research task created: {s}\n", .{research_id});
    std.debug.print("Polling every 5 s (5-minute timeout)...\n\n", .{});

    // Poll until finished — returns error.Timeout or error.TooManyFailures on failure.
    const finished = client.research.pollUntilFinished(
        allocator,
        research_id,
        5_000,
        300_000,
        false,
    ) catch |err| {
        switch (err) {
            error.Timeout => std.debug.print("Timed out waiting for research to finish.\n", .{}),
            error.TooManyFailures => std.debug.print("Too many consecutive poll errors.\n", .{}),
            else => return err,
        }
        return;
    };

    switch (finished) {
        .completed => |c| {
            std.debug.print("=== Research completed ===\n\n", .{});
            std.debug.print("{s}\n\n", .{c.output.content});
            std.debug.print("Cost: ${d:.6}\n", .{c.cost_dollars.total});
        },
        .failed => |f| {
            std.debug.print("Research failed: {s}\n", .{f.error_msg});
        },
        .canceled => {
            std.debug.print("Research was canceled.\n", .{});
        },
        else => {
            std.debug.print("Unexpected terminal state.\n", .{});
        },
    }

    // -----------------------------------------------------------------------
    // List recent research tasks
    // -----------------------------------------------------------------------

    std.debug.print("\n=== Recent research tasks ===\n", .{});

    const page = try client.research.list(allocator, null, 5);

    std.debug.print("Found {} task(s) (has_more={}):\n", .{
        page.data.len,
        page.has_more,
    });
    for (page.data, 1..) |task, i| {
        const tag_name: []const u8 = switch (task) {
            .pending => "pending",
            .running => "running",
            .completed => "completed",
            .canceled => "canceled",
            .failed => "failed",
        };
        const id: []const u8 = switch (task) {
            inline else => |v| v.base.research_id,
        };
        std.debug.print("  {}. [{s}] {s}\n", .{ i, tag_name, id });
    }
}
