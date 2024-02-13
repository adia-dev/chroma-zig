const std = @import("std");
const AnsiColor = @import("ansi.zig").AnsiColor;
const chroma = @import("lib.zig");

// TESTS
const COLOR_OPEN = "\x1b[";
const RESET = "\x1b[0m";

test "format - Red text" {
    const red_hello = chroma.format("{red}Hello");

    const expected = COLOR_OPEN ++ "31m" ++ "Hello" ++ RESET;
    try std.testing.expectEqualStrings(expected, red_hello);
}

test "format - Multiple colors" {
    const colorful_text = chroma.format("{red}Hello{green}my name is{blue}Abdoulaye.");

    const expected = COLOR_OPEN ++ "31m" ++ "Hello" ++ COLOR_OPEN ++ "32m" ++ "my name is" ++ COLOR_OPEN ++ "34m" ++ "Abdoulaye." ++ RESET;
    try std.testing.expectEqualStrings(expected, colorful_text);
}

test "format - Background color and reset" {
    const bg_and_reset = chroma.format("{bgRed}Warning!{reset} Normal text.");

    const expected = COLOR_OPEN ++ "41m" ++ "Warning!" ++ RESET ++ " Normal text." ++ RESET;
    try std.testing.expectEqualStrings(expected, bg_and_reset);
}

test "format - Escaped braces" {
    const escaped_braces = chroma.format("{{This}} is {green}green.");

    const expected = "{" ++ "This" ++ "} is " ++ COLOR_OPEN ++ "32m" ++ "green." ++ RESET;
    try std.testing.expectEqualStrings(expected, escaped_braces);
}

// Test "format - Unmatched braces" would cause a compile-time error:
// const unmatched_braces =chroma.format("{red}Unmatched");
// This test is documented to ensure awareness of the behavior.

test "format - No color codes" {
    const no_color = chroma.format("Just plain text.");

    const expected = "Just plain text.";
    try std.testing.expectEqualStrings(expected, no_color);
}

test "format - Inline reset" {
    const inline_reset = chroma.format("{red}Colored{reset} Not colored.");

    const expected = COLOR_OPEN ++ "31m" ++ "Colored" ++ RESET ++ " Not colored." ++ RESET;
    try std.testing.expectEqualStrings(expected, inline_reset);
}

test "format - Text following color codes without braces" {
    const text_after_color = chroma.format("{red}Red {green}Green{reset} Reset.");

    const expected = COLOR_OPEN ++ "31m" ++ "Red " ++ COLOR_OPEN ++ "32m" ++ "Green" ++ RESET ++ " Reset." ++ RESET;
    try std.testing.expectEqualStrings(expected, text_after_color);
}

// test "format - Multiple color codes" {
//     const multiple_color_codes =chroma.format("{red}{bgGreen}Red on green");

//     const expected = COLOR_OPEN ++ "31;42m" ++ "Red on green" ++ RESET;
//     try std.testing.expectEqualStrings(expected, multiple_color_codes);
// }

// test "format - Multiple color codes with reset" {
//     const multiple_color_codes_with_reset =chroma.format("{red}{bgGreen}Red on green{reset} Reset.");

//     const expected = COLOR_OPEN ++ "31;42m" ++ "Red on green" ++ RESET ++ " Reset." ++ RESET;
//     try std.testing.expectEqualStrings(expected, multiple_color_codes_with_reset);
// }

// test "format - Multiple color codes with inline reset" {
//     const multiple_color_codes_with_inline_reset =chroma.format("{red}{bgGreen}Red on green{reset} Reset.");

//     const expected = COLOR_OPEN ++ "31;42m" ++ "Red on green" ++ RESET ++ " Reset." ++ RESET;
//     try std.testing.expectEqualStrings(expected, multiple_color_codes_with_inline_reset);
// }

// test "format - Multiple color codes with inline reset and text after" {
//     const multiple_color_codes_with_inline_reset_and_text_after =chroma.format("{red}{bgGreen}Red on green{reset} Reset.");

//     const expected = COLOR_OPEN ++ "31;42m" ++ "Red on green" ++ RESET ++ " Reset." ++ RESET;
//     try std.testing.expectEqualStrings(expected, multiple_color_codes_with_inline_reset_and_text_after);
// }
