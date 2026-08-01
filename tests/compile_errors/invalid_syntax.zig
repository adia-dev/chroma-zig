const chroma = @import("chroma");

comptime {
    _ = chroma.Formatter(.{
        .syntax = .{
            .marker = '#',
            .item_separator = ',',
            .value_separator = ',',
            .channel_separator = ';',
        },
    });
}
