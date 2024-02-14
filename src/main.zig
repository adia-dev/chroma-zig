const std = @import("std");
const chroma = @import("lib.zig");

pub fn main() !void {
    const examples = [_]struct { fmt: []const u8, arg: []const u8 }{
        // ANSI foreground and background colors
        .{ .fmt = "{yellow}ANSI {s}", .arg = "SUPPORTED" },
        .{ .fmt = "{blue}JJK is the best new {s}", .arg = "generation" },
        .{ .fmt = "{red}Disagree, and {cyan}Satoru Gojo will throw a {magenta}{s}{reset} at you", .arg = "purple ball" },
        .{ .fmt = "{bgMagenta}{white}Yuji Itadori's resolve: {s}", .arg = "I'll eat the finger." },
        .{ .fmt = "{bgYellow}{black}With this treasure, I summon: {s}", .arg = "Mahoraga or Makora idk" },
        .{ .fmt = "{bgBlue}{white}LeBron {s}", .arg = "James" },
        .{ .fmt = "{green}Please, Lonzo Ball, come back in {s}", .arg = "2024" },
        .{ .fmt = "{blue}JJK is the best new {s}{red} once again", .arg = "generation" },

        // ANSI 256 extended colors
        .{ .fmt = "\n{221}256 Extended set, too! {s}", .arg = "eheh" },
        .{ .fmt = "{121}Finding examples is hard, {s}", .arg = "shirororororo" },

        // TrueColors
        .{ .fmt = "\n{221;10;140}How about {13;45;200}{s}??", .arg = "true colors" },
        .{ .fmt = "{255;202;255}Toge Inumaki says: {s}", .arg = "Salmon" },
        .{ .fmt = "{255;105;180}Nobara Kugisaki's fierce {s}", .arg = "Nail Hammer" },
        .{ .fmt = "{10;94;13}Juujika no {s}", .arg = "Rokunin" },
    };

    inline for (examples) |example| {
        std.debug.print(chroma.format(example.fmt) ++ "\n", .{example.arg});
    }

    std.debug.print(chroma.format("{blue}Eventually, the {red}formatting{reset} looks like {130;43;122}{s}!\n"), .{"this"});
}
