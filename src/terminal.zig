const builtin = @import("builtin");
const std = @import("std");

/// Controls how terminal color capability is selected.
pub const ColorPolicy = enum {
    /// Honor NO_COLOR, CLICOLOR_FORCE, and terminal capability in that order.
    auto,
    /// Emit ANSI even when output is redirected or environment variables opt out.
    always,
    /// Never emit ANSI.
    never,
};

/// Inputs to the deterministic part of automatic color selection.
pub const AutoInputs = struct {
    /// Whether NO_COLOR is present and non-empty.
    no_color: bool = false,
    /// Whether CLICOLOR_FORCE is present and non-empty.
    clicolor_force: bool = false,
    /// Whether the output stream can consume ANSI sequences.
    ansi_capable: bool = false,
};

/// Resolve automatic color policy without reading process or terminal state.
/// This is useful to applications which already perform their own detection.
pub fn resolveAuto(inputs: AutoInputs) bool {
    if (inputs.no_color) return false;
    if (inputs.clicolor_force) return true;
    return inputs.ansi_capable;
}

/// Detect whether pre-rendered ANSI output should be selected for `file`.
///
/// In automatic mode this function also asks Zig's I/O implementation to
/// enable ANSI processing when necessary, including Windows virtual-terminal
/// processing. It performs no allocation and does not retain the file.
pub fn detect(
    io: std.Io,
    environ: std.process.Environ,
    file: std.Io.File,
    policy: ColorPolicy,
) std.Io.Cancelable!bool {
    switch (policy) {
        .never => return false,
        .always => {
            file.enableAnsiEscapeCodes(io) catch {};
            return true;
        },
        .auto => {},
    }

    const no_color = if (builtin.os.tag == .wasi)
        false
    else
        environ.containsUnemptyConstant("NO_COLOR");
    if (no_color) return false;

    const force_color = if (builtin.os.tag == .wasi)
        false
    else
        environ.containsUnemptyConstant("CLICOLOR_FORCE");
    if (force_color) {
        file.enableAnsiEscapeCodes(io) catch {};
        return true;
    }

    file.enableAnsiEscapeCodes(io) catch |err| switch (err) {
        error.Canceled => return error.Canceled,
        error.NotTerminalDevice, error.Unexpected => return false,
    };
    return true;
}

test "resolveAuto precedence" {
    try std.testing.expect(!resolveAuto(.{}));
    try std.testing.expect(resolveAuto(.{ .ansi_capable = true }));
    try std.testing.expect(resolveAuto(.{ .clicolor_force = true }));
    try std.testing.expect(!resolveAuto(.{
        .no_color = true,
        .clicolor_force = true,
        .ansi_capable = true,
    }));
}
