const chroma = @import("chroma");

comptime {
    _ = chroma.format("{#wat}text");
}
