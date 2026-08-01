const chroma = @import("chroma");

comptime {
    _ = chroma.Formatter(.{
        .styles = &.{
            .{ .name = "brand", .style = .{} },
            .{ .name = "brand", .style = .{} },
        },
    });
}
