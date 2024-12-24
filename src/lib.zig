//BUG: apparently {{}} is not reflected to {}

/// This module provides a flexible way to format strings with ANSI color codes
/// dynamically using {colorName} placeholders within the text. It supports standard
/// ANSI colors, ANSI 256 extended colors, and true color (24-bit) formats.
/// It intelligently handles color formatting by parsing placeholders and replacing
/// them with the appropriate ANSI escape codes for terminal output.
const std = @import("std");
const AnsiCode = @import("ansi.zig").AnsiCode;
const compileAssert = @import("utils.zig").compileAssert;

/// Provides dynamic string formatting capabilities with ANSI escape codes for both
/// color and text styling within terminal outputs. This module supports a wide range
/// of formatting options including standard ANSI colors, ANSI 256 extended color set,
/// and true color (24-bit) specifications. It parses given format strings with embedded
/// placeholders (e.g., `{color}` or `{style}`) and replaces them with the corresponding
/// ANSI escape codes. The format function is designed to be used at compile time,
/// enhancing readability and maintainability of terminal output styling in Zig applications.
///
/// The formatting syntax supports modifiers (`fg` for foreground and `bg` for background),
/// as well as multiple formats within a single placeholder. Unrecognized placeholders
/// are output as-is, allowing for the inclusion of literal braces by doubling them (`{{` and `}}`).
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

        // Handle escaped braces '{{' or '}}'
        if (i + 1 < fmt.len and fmt[i + 1] == fmt[i]) {
            i += 2; // Skip both braces
        }

        // Append text up to the next control character
        if (start_index != i) {
            output = output ++ fmt[start_index..i];
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

        if (maybe_color_fmt.len == 0) {
            // since empty, write the braces, skip the closing one
            // and continue
            output = output ++ "{" ++ maybe_color_fmt ++ "}";
            i += 1;
            continue;
        }

        comptime {
            var start = 0;
            var end = 0;
            var is_background = false;

            style_loop: while (start < maybe_color_fmt.len) {
                while (end < maybe_color_fmt.len and maybe_color_fmt[end] != ',') : (end += 1) {}

                var modifier_end = start;
                while (modifier_end < maybe_color_fmt.len and maybe_color_fmt[modifier_end] != ':') : (modifier_end += 1) {}

                if (modifier_end != maybe_color_fmt.len) {
                    if (std.mem.eql(u8, maybe_color_fmt[start..modifier_end], "bg")) {
                        is_background = true;
                        end = modifier_end + 1;
                        start = end;
                        continue :style_loop;
                    } else if (std.mem.eql(u8, maybe_color_fmt[start..modifier_end], "fg")) {
                        is_background = false;
                        end = modifier_end + 1;
                        start = end;
                        continue :style_loop;
                    }
                }

                if (std.ascii.isDigit(maybe_color_fmt[start])) {
                    const color = parse256OrTrueColor(maybe_color_fmt[start..end], is_background);
                    output = output ++ color;
                    at_least_one_color = true;
                } else {
                    var found = false;
                    for (@typeInfo(AnsiCode).@"enum".fields) |field| {
                        if (std.mem.eql(u8, field.name, maybe_color_fmt[start..end])) {
                            // HACK: this would not work if I put bgMagenta for example as a color
                            // TODO: fix this eheh
                            const color: AnsiCode = @enumFromInt(field.value + if (is_background) 10 else 0);
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

                end = end + 1;
                start = end;
                is_background = false;
            }
        }

        i += 1; // Skip '}'
    }

    if (at_least_one_color) {
        return output ++ "\x1b[0m";
    }

    return output;
}

// TODO: maybe keep the compile error and dedicate this function to be comptime only
fn parse256OrTrueColor(fmt: []const u8, background: bool) []const u8 {
    var channels_value: [3]u8 = .{ 0, 0, 0 };
    var channels_length: [3]u8 = .{ 0, 0, 0 };
    var channel = 0;
    var output: []const u8 = "";

    for (fmt) |c| {
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
            ',' => {
                break;
            },
            else => {
                @compileError("Invalid number format, expected: {0-255} or {0-255;0-255;0-255}");
            },
        }
    }

    // ANSI 256 extended
    if (channel == 0) {
        const color: []const u8 = fmt[0..channels_length[0]];
        if (background) {
            output = output ++ "\x1b[48;5;" ++ color ++ "m";
        } else {
            output = output ++ "\x1b[38;5;" ++ color ++ "m";
        }
    }
    // TRUECOLOR
    // TODO: check for compatibility, is it possible at comptime ??
    else if (channel == 2) {
        var color: []const u8 = "";
        var start = 0;
        for (0..channel + 1) |c| {
            const end = start + channels_length[c];
            color = color ++ fmt[start..end] ++ if (c == channel) "" else ";";

            // +1 to skip the ;
            start += channels_length[c] + 1;
        }
        if (background) {
            output = output ++ "\x1b[48;2;" ++ color ++ "m";
        } else {
            output = output ++ "\x1b[38;2;" ++ color ++ "m";
        }
    } else {
        @compileError("Invalid number format, check the number of channels, must be 1 or 3, expected: {0-255} or {0-255;0-255;0-255}");
    }

    return output;
}

comptime {
    _ = @import("tests.zig");
}
