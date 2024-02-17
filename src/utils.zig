/// Asserts the provided condition is true; if not, it triggers a compile-time error
/// with the specified message. This utility function is designed to enforce
/// invariants and ensure correctness throughout the codebase.
pub fn compileAssert(ok: bool, msg: []const u8) void {
    if (!ok) {
        @compileError("Assertion failed: " ++ msg);
    }
}
