/// The eight portable ANSI colors. Brightness is represented separately so
/// themes can express all sixteen foreground and background colors.
pub const BasicColor = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
};

/// A 24-bit terminal color.
pub const Rgb = struct {
    /// Red channel.
    r: u8,
    /// Green channel.
    g: u8,
    /// Blue channel.
    b: u8,
};

/// A foreground or background color supported by Chroma.
pub const Color = union(enum) {
    /// Restore the terminal's default foreground or background color.
    default,
    /// One of the eight standard ANSI colors.
    basic: BasicColor,
    /// One of the eight bright ANSI colors.
    bright: BasicColor,
    /// An entry in the ANSI 256-color palette.
    indexed: u8,
    /// A 24-bit true color.
    rgb: Rgb,
};

/// Text effects which may be enabled by built-in directives or named styles.
pub const Effect = enum(u3) {
    bold,
    dim,
    italic,
    underline,
    blink,
    reverse,
    hidden,
    strikethrough,

    /// Return the SGR parameter which enables this effect.
    pub fn enableCode(effect: Effect) u8 {
        return switch (effect) {
            .bold => 1,
            .dim => 2,
            .italic => 3,
            .underline => 4,
            .blink => 5,
            .reverse => 7,
            .hidden => 8,
            .strikethrough => 9,
        };
    }

    /// Return the SGR parameter which disables this effect.
    pub fn disableCode(effect: Effect) u8 {
        return switch (effect) {
            .bold, .dim => 22,
            .italic => 23,
            .underline => 24,
            .blink => 25,
            .reverse => 27,
            .hidden => 28,
            .strikethrough => 29,
        };
    }
};

/// Return the standard SGR foreground or background parameter for a color.
pub fn basicCode(color: BasicColor, bright: bool, background: bool) u8 {
    const offset: u8 = @intFromEnum(color);
    if (bright) return (if (background) 100 else 90) + offset;
    return (if (background) 40 else 30) + offset;
}
