const chroma = @import("chroma");

comptime {
    _ = chroma.format("{#fg:256}text");
}
