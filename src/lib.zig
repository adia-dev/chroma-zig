/// This module provides a flexible way to format strings with ANSI color codes
/// dynamically using {colorName} placeholders within the text. It supports standard
/// ANSI colors, ANSI 256 extended colors, and true color (24-bit) formats.
/// It intelligently handles color formatting by parsing placeholders and replacing
/// them with the appropriate ANSI escape codes for terminal output.
const std = @import("std");
const AnsiColor = @import("ansi.zig").AnsiColor;
const compileAssert = @import("utils.zig").compileAssert;

/// Formats a string with ANSI, ANSI 256 color codes, and RGB color specifications.
/// Unrecognized placeholders are output as-is, allowing for literal '{' and '}' via
/// double braces '{{' and '}}'.
///
/// Arguments:
/// - `fmt`: The format string with {colorName} placeholders.
///
/// Returns:
/// A formatted string with color escape codes embedded.
// TODO: Refactor this lol
pub fn format(comptime fmt: []const u8) []const u8 {
    @setEvalBranchQuota(2000000);
    comptime var i: usize = 0;
    comptime var output: []const u8 = "";
    comptime var at_least_one_color = false;

    inline while (i < fmt.len) {
        const start_index = i;

        // Find next '{' or '}' or end of string
        inline while (i < fmt.len and fmt[i] != '{' and fmt[i] != '}') : (i += 1) {}

        // Append text up to the next control character
        if (start_index != i) {
            output = output ++ fmt[start_index..i];
        }

        // Handle escaped braces '{{' or '}}'
        if (i + 1 < fmt.len and fmt[i + 1] == fmt[i]) {
            output = output ++ fmt[i .. i + 1]; // Append a single brace
            i += 2; // Skip both braces
            continue;
        }

        if (i >= fmt.len) break; // End of string

        // Process color formatting
        comptime compileAssert(fmt[i] == '{', "Expected '{' to start color format");
        i += 1; // Skip '{'

        const fmt_begin = i;
        inline while (i < fmt.len and fmt[i] != '}') : (i += 1) {} // Find closing '}'
        const fmt_end = i;

        comptime compileAssert(i < fmt.len, "Missing closing '}' in color format");

        const maybe_color_fmt = fmt[fmt_begin..fmt_end];
        comptime {
            var found = false;

            if (std.ascii.isDigit(maybe_color_fmt[0])) {
                var channels_value: [3]u8 = .{ 0, 0, 0 };
                var channels_length: [3]u8 = .{ 0, 0, 0 };
                var channel = 0;
                for (maybe_color_fmt) |c| {
                    switch (c) {
                        '0'...'9' => {
                            var res = @mulWithOverflow(channels_value[channel], 10);
                            if (res[1] > 0) {
                                @compileError("Invalid number format, channel value too high >= 256, expected: {0-255} or {0-255;0-255;0-255}");
                            }
                            channels_value[channel] = res[0];

                            res = @addWithOverflow(channels_value[channel], c - '0');
                            if (res[1] > 0) {
                                @compileError("Invalid number format, channel value too high >= 256, expected: {0-255} or {0-255;0-255;0-255}");
                            }
                            channels_value[channel] = res[0];

                            channels_length[channel] += 1;
                        },
                        ';' => {
                            channel += 1;

                            if (channel >= 3) {
                                @compileError("Invalid number format, too many channels, expected: {0-255} or {0-255;0-255;0-255}");
                            }
                        },
                        else => {
                            @compileError("Invalid number format, expected: {0-255} or {0-255;0-255;0-255}");
                        },
                    }
                }

                // ANSI 256 extended
                if (channel == 0) {
                    const color: []const u8 = maybe_color_fmt[0..channels_length[0]];
                    at_least_one_color = true;
                    output = output ++ "\x1b[38;5;" ++ color ++ "m";
                }
                // TRUECOLOR
                // TODO: check for compatibility, is it possible at comptime ??
                else if (channel == 2) {
                    var color: []const u8 = "";
                    var start = 0;
                    for (0..channel + 1) |c| {
                        const end = start + channels_length[c];
                        color = color ++ maybe_color_fmt[start..end] ++ if (c == channel) "" else ";";

                        // +1 to skip the ;
                        start += channels_length[c] + 1;
                    }
                    at_least_one_color = true;
                    output = output ++ "\x1b[38;2;" ++ color ++ "m";
                } else {
                    @compileError("Invalid number format, check the number of channels, must be 1 or 3, expected: {0-255} or {0-255;0-255;0-255}");
                }
            } else {
                for (@typeInfo(AnsiColor).Enum.fields) |field| {
                    if (std.mem.eql(u8, field.name, maybe_color_fmt)) {
                        const color: AnsiColor = @enumFromInt(field.value);
                        at_least_one_color = true;
                        output = output ++ "\x1b[" ++ color.code() ++ "m";
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    output = output ++ "{" ++ maybe_color_fmt ++ "}";
                }
            }
        }

        i += 1; // Skip '}'
    }

    if (at_least_one_color) {
        return output ++ "\x1b[0m";
    }

    return output;
}

comptime {
    _ = @import("tests.zig");
}
