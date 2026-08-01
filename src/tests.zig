const std = @import("std");
const chroma = @import("lib.zig");

const CSI = "\x1b[";
const RESET = CSI ++ "0m";

test "format - plain text and empty input" {
    try std.testing.expectEqualStrings("Just plain text.", chroma.format("Just plain text."));
    try std.testing.expectEqualStrings("", chroma.format(""));
}

test "format - standard and bright foreground colors" {
    try std.testing.expectEqualStrings(CSI ++ "31mred" ++ RESET, chroma.format("{#red}red"));
    try std.testing.expectEqualStrings(CSI ++ "94mblue" ++ RESET, chroma.format("{#bright-blue}blue"));
}

test "format - combined color, background, and effects use one sequence" {
    const actual = chroma.format("{#bold,red,bg:blue,underline}styled");
    try std.testing.expectEqualStrings(CSI ++ "31;44;1;4mstyled" ++ RESET, actual);
}

test "format - indexed and true colors" {
    const actual = chroma.format("{#fg:120}indexed{#fg:255;100;0,bg:4;5;6}rgb");
    const expected = CSI ++ "38;5;120mindexed" ++ CSI ++ "38;2;255;100;0;48;2;4;5;6mrgb" ++ RESET;
    try std.testing.expectEqualStrings(expected, actual);
}

test "format - explicit reset prevents redundant trailing reset" {
    const actual = chroma.format("{#red}warning{#reset} normal");
    try std.testing.expectEqualStrings(CSI ++ "31mwarning" ++ RESET ++ " normal", actual);
}

test "format - selective resets update tracked state" {
    const actual = chroma.format("{#bold,dim,red}a{#normal-intensity}b{#fg:default}c");
    const expected = CSI ++ "31;1;2ma" ++ CSI ++ "22mb" ++ CSI ++ "39mc";
    try std.testing.expectEqualStrings(expected, actual);
}

test "format - individual effects can be disabled" {
    const actual = chroma.format("{#italic,underline,blink,reverse,hidden,strikethrough}a{#no-italic,no-underline,no-blink,no-reverse,no-hidden,no-strikethrough}b");
    const expected = CSI ++ "3;4;5;7;8;9ma" ++ CSI ++ "23;24;25;27;28;29mb";
    try std.testing.expectEqualStrings(expected, actual);
}

test "format - later colors in a tag win" {
    try std.testing.expectEqualStrings(CSI ++ "34mblue" ++ RESET, chroma.format("{#red,green,blue}blue"));
}

test "format - Zig fields and escaped braces pass through unchanged" {
    const actual = chroma.format("{{literal}} {s: >8} {d} {red}");
    try std.testing.expectEqualStrings("{{literal}} {s: >8} {d} {red}", actual);
}

test "render - plain output strips only Chroma directives" {
    const rendered = chroma.render("{{status}} {#bold,red}failure: {s}{#reset}");
    try std.testing.expectEqualStrings("{{status}} " ++ CSI ++ "31;1mfailure: {s}" ++ RESET, rendered.ansi);
    try std.testing.expectEqualStrings("{{status}} failure: {s}", rendered.plain);
    try std.testing.expectEqualStrings(rendered.ansi, rendered.select(true));
    try std.testing.expectEqualStrings(rendered.plain, rendered.select(false));
}

test "formatter - imported ZON config supplies styles and syntax" {
    const ui = chroma.Formatter(@import("test_theme.zon"));
    const actual = ui.format("{@error|underline}failure{@reset}");
    const expected = CSI ++ "38;2;220;50;47;103;1;4mfailure" ++ RESET;
    try std.testing.expectEqualStrings(expected, actual);
}

test "formatter - named style can leave existing colors unchanged" {
    const ui = chroma.Formatter(.{
        .styles = &.{.{
            .name = "emphasis",
            .style = .{ .effects = &.{.bold} },
        }},
    });
    try std.testing.expectEqualStrings(
        CSI ++ "32mgreen " ++ CSI ++ "1mstrong" ++ RESET,
        ui.format("{#green}green {#emphasis}strong"),
    );
}

test "formatter - automatic reset can be disabled" {
    const no_reset = chroma.Formatter(.{ .auto_reset = false });
    try std.testing.expectEqualStrings(CSI ++ "31mred", no_reset.format("{#red}red"));
}

test "format - all ANSI colors produce canonical foreground codes" {
    const cases = .{
        .{ "black", "30" },
        .{ "red", "31" },
        .{ "green", "32" },
        .{ "yellow", "33" },
        .{ "blue", "34" },
        .{ "magenta", "35" },
        .{ "cyan", "36" },
        .{ "white", "37" },
        .{ "bright-black", "90" },
        .{ "bright-red", "91" },
        .{ "bright-green", "92" },
        .{ "bright-yellow", "93" },
        .{ "bright-blue", "94" },
        .{ "bright-magenta", "95" },
        .{ "bright-cyan", "96" },
        .{ "bright-white", "97" },
    };

    inline for (cases) |case| {
        const input = "{#" ++ case[0] ++ "}x";
        const expected = CSI ++ case[1] ++ "mx" ++ RESET;
        try std.testing.expectEqualStrings(expected, chroma.format(input));
    }
}

test "format - all ANSI colors produce canonical background codes" {
    const cases = .{
        .{ "black", "40" },
        .{ "red", "41" },
        .{ "green", "42" },
        .{ "yellow", "43" },
        .{ "blue", "44" },
        .{ "magenta", "45" },
        .{ "cyan", "46" },
        .{ "white", "47" },
        .{ "bright-black", "100" },
        .{ "bright-red", "101" },
        .{ "bright-green", "102" },
        .{ "bright-yellow", "103" },
        .{ "bright-blue", "104" },
        .{ "bright-magenta", "105" },
        .{ "bright-cyan", "106" },
        .{ "bright-white", "107" },
    };

    inline for (cases) |case| {
        const input = "{#bg:" ++ case[0] ++ "}x";
        const expected = CSI ++ case[1] ++ "mx" ++ RESET;
        try std.testing.expectEqualStrings(expected, chroma.format(input));
    }
}

test "format - UTF-8 text remains byte-exact" {
    try std.testing.expectEqualStrings(
        CSI ++ "36mhéllø 世界" ++ RESET,
        chroma.format("{#cyan}héllø 世界"),
    );
}

test "format - large compile-time input" {
    const input = ("{#red}x{#reset}" ** 128);
    const actual = chroma.format(input);
    try std.testing.expectEqual(@as(usize, (CSI ++ "31mx" ++ RESET).len * 128), actual.len);
}
