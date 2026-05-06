/// Websets subsystem example: create, enrich, list items, then delete.
/// Run with: zig build run-websets
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
    // 1. Preview a potential webset query before committing
    // -----------------------------------------------------------------------

    std.debug.print("=== Previewing query ===\n", .{});

    const preview = try client.websets.preview(allocator, .{
        .query = "AI safety research labs",
        .entity = .company,
    });
    defer preview.deinit(allocator);

    std.debug.print("Preview: entity={s}, {} criteria\n\n", .{
        preview.search.entity.toString(),
        preview.search.criteria.len,
    });

    // -----------------------------------------------------------------------
    // 2. Create the webset
    // -----------------------------------------------------------------------

    std.debug.print("=== Creating webset ===\n", .{});

    const ws = try client.websets.create(allocator, .{
        .search = .{
            .query = "AI safety research labs",
            .count = 10,
            .entity = .company,
            .criteria = &[_]exa.CreateCriterionParameters{
                .{ .description = "Focused on AI alignment or safety research" },
            },
        },
    }, null);
    defer ws.deinit(allocator);

    std.debug.print("Created webset: {s} (status={s})\n\n", .{
        ws.id,
        ws.status.toString(),
    });

    // -----------------------------------------------------------------------
    // 3. Add an enrichment
    // -----------------------------------------------------------------------

    std.debug.print("=== Adding enrichment ===\n", .{});

    var funding_opts = [_]exa.EnrichmentOption{
        .{ .label = "seed" },
        .{ .label = "series-a" },
        .{ .label = "series-b-or-later" },
        .{ .label = "unknown" },
    };
    const enrichment = try client.websets.enrichments.create(allocator, ws.id, .{
        .description = "What is the organization's funding stage?",
        .format = .options,
        .options = &funding_opts,
    }, null);
    defer enrichment.deinit(allocator);

    std.debug.print("Enrichment: {s} (format={s})\n\n", .{
        enrichment.id,
        enrichment.format.?.toString(),
    });

    // -----------------------------------------------------------------------
    // 4. Wait until processing is complete (2-minute timeout, 5-second poll)
    // -----------------------------------------------------------------------

    std.debug.print("=== Waiting for webset to become idle... ===\n", .{});

    const idle_ws = client.websets.waitUntilIdle(allocator, ws.id, 120, 5, null) catch |err| {
        std.debug.print("Timed out or error waiting: {}\n", .{err});
        return;
    };
    defer idle_ws.deinit(allocator);

    std.debug.print("Webset is idle. {} search(es), {} enrichment(s).\n\n", .{
        idle_ws.searches.len,
        idle_ws.enrichments.len,
    });

    // -----------------------------------------------------------------------
    // 5. List items (ListWebsetItemResponse.deinit handles all cleanup)
    // -----------------------------------------------------------------------

    std.debug.print("=== Listing items ===\n", .{});

    const items = try client.websets.items.list(allocator, ws.id, null, 5);
    defer items.deinit(allocator);

    std.debug.print("Got {} item(s):\n", .{items.data.len});
    for (items.data, 1..) |item, i| {
        const url: []const u8 = switch (item.properties) {
            .company => |c| c.url,
            .person => |p| p.url,
            .article => |a| a.url,
            .research_paper => |r| r.url,
            .custom => |c| c.url,
        };
        const name: ?[]const u8 = switch (item.properties) {
            .company => |c| c.name,
            .person => |p| p.name,
            .article => |a| a.title,
            .research_paper => |r| r.title,
            .custom => null,
        };
        std.debug.print("  {}. {s}\n     {s}\n", .{
            i,
            name orelse "(no name)",
            url,
        });
    }
    std.debug.print("\n", .{});

    // -----------------------------------------------------------------------
    // 6. Delete the webset
    // -----------------------------------------------------------------------

    std.debug.print("=== Deleting webset ===\n", .{});

    const deleted = try client.websets.delete(allocator, ws.id);
    defer deleted.deinit(allocator);

    std.debug.print("Deleted: {s}\n", .{deleted.id});
}
