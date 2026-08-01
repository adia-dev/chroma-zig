const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const chroma = b.addModule("chroma", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const example_module = b.createModule(.{
        .root_source_file = b.path("examples/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    example_module.addImport("chroma", chroma);

    const example = b.addExecutable(.{
        .name = "chroma-example",
        .root_module = example_module,
    });
    b.installArtifact(example);

    const run_command = b.addRunArtifact(example);
    run_command.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_command.addArgs(args);

    const run_step = b.step("run", "Run the Chroma example");
    run_step.dependOn(&run_command.step);

    const library_tests = b.addTest(.{ .root_module = chroma });
    const run_library_tests = b.addRunArtifact(library_tests);

    const example_tests = b.addTest(.{ .root_module = example_module });
    const run_example_tests = b.addRunArtifact(example_tests);

    const test_step = b.step("test", "Run unit and compile-error tests");
    test_step.dependOn(&run_library_tests.step);
    test_step.dependOn(&run_example_tests.step);

    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/unknown_directive.zig",
        "error: chroma: unknown directive 'wat' at byte 2",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/missing_close.zig",
        "error: chroma: missing closing '}' for Chroma directive at byte 0",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/invalid_rgb.zig",
        "error: chroma: RGB colors require exactly three channels at byte 5",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/duplicate_style.zig",
        "error: chroma config: duplicate style name 'brand'",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/color_overflow.zig",
        "error: chroma: color channel exceeds 255 at byte 5",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/empty_channel.zig",
        "error: chroma: empty numeric color channel at byte 7",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/reserved_style.zig",
        "error: chroma config: style name 'red' is reserved",
    );
    addCompileErrorTest(
        b,
        test_step,
        chroma,
        target,
        optimize,
        "tests/compile_errors/invalid_syntax.zig",
        "error: chroma config: syntax characters must be distinct",
    );

    const benchmark_module = b.createModule(.{
        .root_source_file = b.path("benchmarks/compile.zig"),
        .target = target,
        .optimize = optimize,
    });
    benchmark_module.addImport("chroma", chroma);
    const benchmark_compile = b.addTest(.{ .root_module = benchmark_module });

    const benchmark_step = b.step("benchmark", "Compile the large comptime benchmark fixture");
    benchmark_step.dependOn(&benchmark_compile.step);
}

fn addCompileErrorTest(
    b: *std.Build,
    test_step: *std.Build.Step,
    chroma: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    path: []const u8,
    expected: []const u8,
) void {
    const fixture_module = b.createModule(.{
        .root_source_file = b.path(path),
        .target = target,
        .optimize = optimize,
    });
    fixture_module.addImport("chroma", chroma);

    const fixture = b.addTest(.{ .root_module = fixture_module });
    fixture.expect_errors = .{ .contains = expected };
    test_step.dependOn(&fixture.step);
}
