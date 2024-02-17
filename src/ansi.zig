/// The `AnsiCode` enum offers a comprehensive set of ANSI escape codes for both
/// styling and coloring text in the terminal. This includes basic styles like bold
/// and italic, foreground and background colors, and special modes like blinking or
/// hidden text. It provides methods for obtaining the string name and the corresponding
/// ANSI escape code of each color or style, enabling easy and readable text formatting.
pub const AnsiCode = enum(u8) {
    // Standard style codes
    reset = 0,
    bold,
    dim,
    italic,
    underline,
    ///Not widely supported
    blink,
    reverse = 7,
    hidden,

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

    /// Returns the string representation of the color.
    /// This method makes it easy to identify a color by its name in the source code.
    ///
    /// Returns:
    /// A slice of constant u8 bytes representing the color's name.
    pub fn to_string(self: AnsiCode) []const u8 {
        return @tagName(self);
    }

    /// Returns the ANSI escape code for the color as a string.
    /// This method is used to apply the color to terminal output by embedding
    /// the returned string into an output sequence.
    ///
    /// Returns:
    /// A slice of constant u8 bytes representing the ANSI escape code for the color.
    pub fn code(self: AnsiCode) []const u8 {
        return switch (self) {
            // Standard style codes
            .reset => "0",
            .bold => "1",
            .dim => "2",
            .italic => "3",
            .underline => "4",
            // Not widely supported
            .blink => "5",
            .reverse => "7",
            .hidden => "8",
            // foregroond colors
            .black => "30",
            .red => "31",
            .green => "32",
            .yellow => "33",
            .blue => "34",
            .magenta => "35",
            .cyan => "36",
            .white => "37",
            // background colors
            .bgBlack => "40",
            .bgRed => "41",
            .bgGreen => "42",
            .bgYellow => "43",
            .bgBlue => "44",
            .bgMagenta => "45",
            .bgCyan => "46",
            .bgWhite => "47",
        };
    }
};
