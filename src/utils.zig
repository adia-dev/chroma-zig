const std = @import("std");

/// Emit a consistently formatted compile-time parser diagnostic.
pub fn failAt(comptime message: []const u8, comptime offset: usize) noreturn {
    @compileError(std.fmt.comptimePrint("chroma: {s} at byte {d}", .{ message, offset }));
}

/// Emit a consistently formatted compile-time configuration diagnostic.
pub fn failConfig(comptime message: []const u8) noreturn {
    @compileError("chroma config: " ++ message);
}
