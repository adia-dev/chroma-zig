const chroma = @import("chroma");

comptime {
    _ = chroma.Formatter(.{
        .styles = &.{.{ .name = "red", .style = .{} }},
    });
}
