const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -----------------------------------------------------------------------
    // Public module — downstream projects access this with:
    //   const dep = b.dependency("exazig", .{ .target = target, .optimize = optimize });
    //   exe.root_module.addImport("exa", dep.module("exa"));
    // -----------------------------------------------------------------------

    const exa_module = b.addModule("exa", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // -----------------------------------------------------------------------
    // Static library  →  zig-out/lib/libexazig.a
    // -----------------------------------------------------------------------

    const lib = b.addStaticLibrary(.{
        .name = "exazig",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // -----------------------------------------------------------------------
    // Examples  —  zig build run-search / run-answer / run-contents
    // -----------------------------------------------------------------------

    const example_files = .{
        .{ "search", "examples/search.zig", "Search Exa and print results" },
        .{ "answer", "examples/answer.zig", "Ask Exa a question and print the answer" },
        .{ "contents", "examples/contents.zig", "Fetch page contents via Exa" },
        .{ "websets", "examples/websets.zig", "Websets: create, enrich, list items, delete" },
        .{ "research", "examples/research.zig", "Research: create task, poll until finished" },
        .{ "monitors", "examples/monitors.zig", "Monitors: create, trigger, list runs, delete" },
    };

    inline for (example_files) |ex| {
        const exe = b.addExecutable(.{
            .name = ex[0],
            .root_source_file = b.path(ex[1]),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("exa", exa_module);

        const run = b.addRunArtifact(exe);
        run.step.dependOn(b.getInstallStep());
        if (b.args) |args| run.addArgs(args);

        const step = b.step("run-" ++ ex[0], ex[2]);
        step.dependOn(&run.step);
    }

    // -----------------------------------------------------------------------
    // Tests  —  zig build test
    // -----------------------------------------------------------------------

    const test_step = b.step("test", "Run all unit tests");

    const test_files = [_][]const u8{
        "src/tests/utils_test.zig",
        "src/tests/json_utils_test.zig",
        "src/tests/client_test.zig",
        "src/tests/websets_test.zig",
        "src/tests/research_test.zig",
        "src/tests/monitors_test.zig",
    };

    for (test_files) |test_file| {
        const unit_tests = b.addTest(.{
            .root_source_file = b.path(test_file),
            .target = target,
            .optimize = optimize,
        });
        unit_tests.root_module.addImport("exa", exa_module);
        test_step.dependOn(&b.addRunArtifact(unit_tests).step);
    }
}
