/// The `AnsiColor` enum provides a simple and type-safe way to use ANSI color codes
/// in terminal output. It includes both foreground and background colors, as well as
/// a method to reset the color. It offers two public methods to interact with the
/// color values: `to_string`, which returns the string representation of the color,
/// and `code`, which returns the ANSI escape code associated with the color.
pub const AnsiColor = enum(u8) {
    // Standard text colors
    black = 30,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    // Standard background colors
    bgBlack = 40,
    bgRed,
    bgGreen,
    bgYellow,
    bgBlue,
    bgMagenta,
    bgCyan,
    bgWhite,
    reset = 0,

    /// Returns the string representation of the color.
    /// This method makes it easy to identify a color by its name in the source code.
    ///
    /// Returns:
    /// A slice of constant u8 bytes representing the color's name.
    pub fn to_string(self: AnsiColor) []const u8 {
        return @tagName(self);
    }

    /// Returns the ANSI escape code for the color as a string.
    /// This method is used to apply the color to terminal output by embedding
    /// the returned string into an output sequence.
    ///
    /// Returns:
    /// A slice of constant u8 bytes representing the ANSI escape code for the color.
    pub fn code(self: AnsiColor) []const u8 {
        return switch (self) {
            .black => "30",
            .red => "31",
            .green => "32",
            .yellow => "33",
            .blue => "34",
            .magenta => "35",
            .cyan => "36",
            .white => "37",
            .bgBlack => "40",
            .bgRed => "41",
            .bgGreen => "42",
            .bgYellow => "43",
            .bgBlue => "44",
            .bgMagenta => "45",
            .bgCyan => "46",
            .bgWhite => "47",
            .reset => "0",
        };
    }
};
