/// Search Monitors example: create a monitor, trigger it, list runs, then delete.
/// Run with: zig build run-monitors
/// Requires EXA_API_KEY environment variable.
const std = @import("std");
const exa = @import("exa");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try exa.Exa.init(allocator, null, null, null);
    defer client.deinit();

    // -----------------------------------------------------------------------
    // 1. Create a search monitor
    // -----------------------------------------------------------------------

    std.debug.print("=== Creating search monitor ===\n", .{});

    const created = try client.monitors.create(allocator, .{
        .name = "Zig language news",
        .search = .{
            .query = "Zig programming language news",
            .num_results = 10,
            .contents = .{
                .text = .{ .enabled = false },
                .summary = .{ .enabled = true },
            },
        },
        .trigger = .{ .type = "interval", .period = "week" },
        .webhook = .{ .url = "https://webhook.site/exazig-test" },
    });
    defer created.deinit(allocator);

    std.debug.print("Monitor created:  {s}\n", .{created.monitor.id});
    std.debug.print("Webhook secret:   {s}\n", .{created.webhook_secret});
    std.debug.print("Status:           {s}\n\n", .{created.monitor.status.toString()});

    const monitor_id = created.monitor.id;

    // -----------------------------------------------------------------------
    // 2. Trigger the monitor manually
    // -----------------------------------------------------------------------

    std.debug.print("=== Triggering monitor ===\n", .{});

    const trigger_result = try client.monitors.trigger(allocator, monitor_id);
    std.debug.print("Triggered: {}\n\n", .{trigger_result.triggered});

    // -----------------------------------------------------------------------
    // 3. List all active monitors (ListSearchMonitorsResponse.deinit handles cleanup)
    // -----------------------------------------------------------------------

    std.debug.print("=== Active monitors ===\n", .{});

    const active = try client.monitors.list(allocator, .active, null, 10);
    defer active.deinit(allocator);

    std.debug.print("Found {} active monitor(s):\n", .{active.data.len});
    for (active.data, 1..) |m, i| {
        std.debug.print("  {}. [{s}] {s}  query=\"{s}\"\n", .{
            i,
            m.status.toString(),
            m.name orelse m.id,
            m.search.query,
        });
    }
    std.debug.print("\n", .{});

    // -----------------------------------------------------------------------
    // 4. List all runs for our monitor (paginated)
    // -----------------------------------------------------------------------

    std.debug.print("=== Listing all runs ===\n", .{});

    const all_runs = try client.monitors.runs.listAll(allocator, monitor_id, null);
    defer {
        for (all_runs) |r| r.deinit(allocator);
        allocator.free(all_runs);
    }

    std.debug.print("Total runs: {}\n", .{all_runs.len});
    for (all_runs, 1..) |run, i| {
        std.debug.print("  {}. {s}  [{s}]\n", .{
            i,
            run.id,
            run.status.toString(),
        });
    }
    std.debug.print("\n", .{});

    // -----------------------------------------------------------------------
    // 5. Delete the monitor
    // -----------------------------------------------------------------------

    std.debug.print("=== Deleting monitor ===\n", .{});

    const deleted = try client.monitors.delete(allocator, monitor_id);
    defer deleted.deinit(allocator);

    std.debug.print("Deleted: {s}\n", .{deleted.id});
}
