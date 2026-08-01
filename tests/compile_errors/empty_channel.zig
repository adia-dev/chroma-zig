const chroma = @import("chroma");

comptime {
    _ = chroma.format("{#fg:1;;2}text");
}
