const std = @import("std");
const chroma = @import("lib.zig");

pub fn main() !void {
    const examples = [_]struct { fmt: []const u8, arg: ?[]const u8 }{
        // Basic color and style
        .{ .fmt = "{bold,red}Bold and Red{reset}", .arg = null },
        // Combining background and foreground with styles
        .{ .fmt = "{fg:cyan,bg:magenta}{underline}Cyan on Magenta underline{reset}", .arg = null },
        // Nested styles and colors
        .{ .fmt = "{green}Green {bold}and Bold{reset,blue,italic} to blue italic{reset}", .arg = null },
        // Extended ANSI color with arg example
        .{ .fmt = "{bg:120}Extended ANSI {s}{reset}", .arg = "Background" },
        // True color specification
        .{ .fmt = "{fg:255;100;0}True Color Orange Text{reset}", .arg = null },
        // Mixed color and style formats
        .{ .fmt = "{bg:28,italic}{fg:231}Mixed Background and Italic{reset}", .arg = null },
        // Unsupported/Invalid color code >= 256, Error thrown at compile time
        // .{ .fmt = "{fg:999}This should not crash{reset}", .arg = null },
        // Demonstrating blink, note: may not be supported in all terminals
        .{ .fmt = "{blink}Blinking Text (if supported){reset}", .arg = null },
        // Using dim and reverse video
        .{ .fmt = "{dim,reverse}Dim and Reversed{reset}", .arg = null },
        // Custom message with dynamic content
        .{ .fmt = "{blue,bg:magenta}User {bold}{s}{reset,0;255;0} logged in successfully.", .arg = "Charlie" },
        // Combining multiple styles and reset
        .{ .fmt = "{underline,cyan}Underlined Cyan{reset} then normal", .arg = null },
        // Multiple format specifiers for complex formatting
        .{ .fmt = "{fg:144,bg:52,bold,italic}Fancy {underline}Styling{reset}", .arg = null },
        // Jujutsu Kaisen !!
        .{ .fmt = "{bg:72,bold,italic}Jujutsu Kaisen !!{reset}", .arg = null },
    };

    inline for (examples) |example| {
        if (example.arg) |arg| {
            std.debug.print(chroma.format(example.fmt) ++ "\n", .{arg});
        } else {
            std.debug.print(chroma.format(example.fmt) ++ "\n", .{});
        }
    }

    std.debug.print(chroma.format("{blue}{underline}Eventually{reset}, the {red}formatting{reset} looks like {130;43;122}{s}!\n"), .{"this"});
}
