/// Retrieve page contents (text + summary) and find similar pages.
/// Run with: zig build run-contents
/// Requires EXA_API_KEY environment variable.
const std = @import("std");
const exa = @import("exa");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try exa.Exa.init(allocator, null, null, null);
    defer client.deinit();

    // --- getContents ---

    const urls = &[_][]const u8{
        "https://ziglang.org",
        "https://ziglang.org/learn/overview/",
    };

    std.debug.print("Fetching contents for {} URL(s)...\n\n", .{urls.len});

    const contents = try client.getContents(allocator, .{
        .urls = urls,
        .text = .{ .options = .{
            .max_characters = 800,
            .verbosity = .standard,
        } },
        .summary = .{ .options = .{
            .query = "What is the main topic of this page?",
        } },
    });
    defer contents.deinit();

    for (contents.results) |r| {
        std.debug.print("URL:     {s}\n", .{r.url});
        if (r.title) |t| std.debug.print("Title:   {s}\n", .{t});
        if (r.summary) |s| std.debug.print("Summary: {s}\n", .{s});
        if (r.text) |t| {
            const preview_len = @min(t.len, 200);
            std.debug.print("Text:    {s}{s}\n", .{
                t[0..preview_len],
                if (t.len > preview_len) "..." else "",
            });
        }
        std.debug.print("\n", .{});
    }

    // --- findSimilar ---

    std.debug.print("Finding pages similar to ziglang.org...\n\n", .{});

    const similar = try client.findSimilar(allocator, .{
        .url = "https://ziglang.org",
        .num_results = 3,
        .exclude_source_domain = true,
    });
    defer similar.deinit();

    for (similar.results, 1..) |r, i| {
        std.debug.print("{}. {s}\n   {s}\n\n", .{
            i,
            r.title orelse "(no title)",
            r.url,
        });
    }
}
