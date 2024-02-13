/// Asserts the given condition is true; triggers a compile Error if not.
pub fn compileAssert(ok: bool, msg: []const u8) void {
    if (!ok) {
        @compileError("Assertion failed: " ++ msg);
    }
}
