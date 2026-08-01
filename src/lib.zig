//! Compile-time ANSI format-string rendering.
//!
//! Chroma reserves only namespaced directives such as `{#red,bold}`. All
//! other braces are preserved for a later `std.fmt` call.

const std = @import("std");
const ansi = @import("ansi.zig");
const utils = @import("utils.zig");

pub const terminal = @import("terminal.zig");
pub const BasicColor = ansi.BasicColor;
pub const Rgb = ansi.Rgb;
pub const Color = ansi.Color;
pub const Effect = ansi.Effect;

/// A reusable semantic style. Omitted colors leave that color unchanged.
pub const Style = struct {
    /// Foreground color to apply, or null to leave it unchanged.
    foreground: ?Color = null,
    /// Background color to apply, or null to leave it unchanged.
    background: ?Color = null,
    /// Effects to enable when the style is used.
    effects: []const Effect = &.{},
};

/// A style made available as a directive in a configured formatter.
pub const NamedStyle = struct {
    /// Directive name, without the marker or braces.
    name: []const u8,
    /// Style changes applied by the directive.
    style: Style,
};

/// Configurable characters inside Chroma's fixed `{...}` envelope.
pub const Syntax = struct {
    /// Identifies Chroma fields immediately after `{`.
    marker: u8 = '#',
    /// Separates items in one Chroma directive.
    item_separator: u8 = ',',
    /// Separates `fg` or `bg` from a color value.
    value_separator: u8 = ':',
    /// Separates the three channels of an RGB value.
    channel_separator: u8 = ';',
};

/// Compile-time configuration for a formatter.
pub const Config = struct {
    /// Grammar characters used by this formatter.
    syntax: Syntax = .{},
    /// User-defined semantic styles.
    styles: []const NamedStyle = &.{},
    /// Append reset when the rendered string ends with active formatting.
    auto_reset: bool = true,
};

/// Both compile-time renderings of one Chroma format string.
pub const Rendered = struct {
    /// Format string containing ANSI SGR sequences.
    ansi: []const u8,
    /// The same format string with Chroma directives removed.
    plain: []const u8,

    /// Select a pre-rendered string without allocating or parsing at runtime.
    pub fn select(rendered: Rendered, use_color: bool) []const u8 {
        return if (use_color) rendered.ansi else rendered.plain;
    }
};

/// Create a compile-time formatter with an explicit configuration.
pub fn Formatter(comptime config: Config) type {
    comptime validateConfig(config);

    return struct {
        /// Render a format string containing ANSI escape sequences.
        pub fn format(comptime fmt: []const u8) []const u8 {
            return renderSlice(config, fmt, .ansi);
        }

        /// Render ANSI and plain variants of a format string at compile time.
        pub fn render(comptime fmt: []const u8) Rendered {
            return .{
                .ansi = renderSlice(config, fmt, .ansi),
                .plain = renderSlice(config, fmt, .plain),
            };
        }
    };
}

/// The formatter using Chroma's built-in syntax and palette.
pub const default = Formatter(.{});

/// Render with Chroma's built-in syntax and palette.
pub fn format(comptime fmt: []const u8) []const u8 {
    return default.format(fmt);
}

/// Render ANSI and plain variants with Chroma's default configuration.
pub fn render(comptime fmt: []const u8) Rendered {
    return default.render(fmt);
}

const OutputMode = enum { ansi, plain };

const FormatState = struct {
    foreground: Color = .default,
    background: Color = .default,
    effects: u8 = 0,

    fn active(state: FormatState) bool {
        return !isDefaultColor(state.foreground) or
            !isDefaultColor(state.background) or
            state.effects != 0;
    }
};

const TagResult = struct {
    state: FormatState,
    force_reset: bool = false,
};

const CountWriter = struct {
    len: usize = 0,

    fn writeAll(writer: *@This(), bytes: []const u8) void {
        writer.len += bytes.len;
    }
};

fn FixedWriter(comptime capacity: usize) type {
    return struct {
        buffer: *[capacity]u8,
        pos: usize = 0,

        fn writeAll(writer: *@This(), bytes: []const u8) void {
            @memcpy(writer.buffer[writer.pos..][0..bytes.len], bytes);
            writer.pos += bytes.len;
        }
    };
}

fn renderSlice(comptime config: Config, comptime fmt: []const u8, comptime mode: OutputMode) []const u8 {
    const len = comptime renderedLength(config, fmt, mode);
    const bytes = comptime renderArray(config, fmt, mode, len);
    return &bytes;
}

fn renderedLength(comptime config: Config, comptime fmt: []const u8, comptime mode: OutputMode) usize {
    var writer: CountWriter = .{};
    process(config, fmt, mode, &writer);
    return writer.len;
}

fn renderArray(
    comptime config: Config,
    comptime fmt: []const u8,
    comptime mode: OutputMode,
    comptime len: usize,
) [len]u8 {
    var bytes: [len]u8 = undefined;
    var writer: FixedWriter(len) = .{ .buffer = &bytes };
    process(config, fmt, mode, &writer);
    std.debug.assert(writer.pos == len);
    return bytes;
}

fn process(
    comptime config: Config,
    comptime fmt: []const u8,
    comptime mode: OutputMode,
    writer: anytype,
) void {
    // Parsing cost is proportional to input and configured style count. Avoid
    // imposing the former blanket two-million branch quota on every call.
    @setEvalBranchQuota(@max(2000, fmt.len * (128 + config.styles.len * 16)));

    var state: FormatState = .{};
    var i: usize = 0;
    var text_start: usize = 0;

    while (i < fmt.len) {
        const escaped_brace = i + 1 < fmt.len and
            (fmt[i] == '{' or fmt[i] == '}') and
            fmt[i + 1] == fmt[i];
        if (escaped_brace) {
            i += 2;
            continue;
        }

        const is_tag = fmt[i] == '{' and
            i + 1 < fmt.len and
            fmt[i + 1] == config.syntax.marker;
        if (!is_tag) {
            i += 1;
            continue;
        }

        writer.writeAll(fmt[text_start..i]);

        var close = i + 2;
        while (close < fmt.len and fmt[close] != '}') : (close += 1) {}
        if (close == fmt.len) {
            utils.failAt("missing closing '}' for Chroma directive", i);
        }

        const before = state;
        const tag = parseTag(config, fmt, i + 2, close, state);
        state = tag.state;
        if (mode == .ansi) emitTransition(writer, before, state, tag.force_reset);

        i = close + 1;
        text_start = i;
    }

    writer.writeAll(fmt[text_start..]);
    if (mode == .ansi and config.auto_reset and state.active()) {
        writer.writeAll("\x1b[0m");
    }
}

fn parseTag(
    comptime config: Config,
    comptime fmt: []const u8,
    begin: usize,
    end: usize,
    initial: FormatState,
) TagResult {
    if (begin == end) utils.failAt("empty Chroma directive", begin);

    var result: TagResult = .{ .state = initial };
    var item_start = begin;
    var cursor = begin;

    while (cursor <= end) : (cursor += 1) {
        if (cursor != end and fmt[cursor] != config.syntax.item_separator) continue;
        if (cursor == item_start) utils.failAt("empty item in Chroma directive", cursor);

        applyToken(config, fmt[item_start..cursor], item_start, &result);
        item_start = cursor + 1;
    }

    return result;
}

fn applyToken(
    comptime config: Config,
    token: []const u8,
    offset: usize,
    result: *TagResult,
) void {
    if (std.mem.eql(u8, token, "reset")) {
        result.state = .{};
        result.force_reset = true;
        return;
    }

    if (parseBasicColor(token)) |color| {
        result.state.foreground = colorValue(color);
        return;
    }

    if (parseEnabledEffect(token)) |effect| {
        setEffect(&result.state, effect, true);
        return;
    }

    if (std.mem.eql(u8, token, "normal-intensity")) {
        setEffect(&result.state, .bold, false);
        setEffect(&result.state, .dim, false);
        return;
    }

    if (parseDisabledEffect(token)) |effect| {
        setEffect(&result.state, effect, false);
        return;
    }

    if (std.mem.indexOfScalar(u8, token, config.syntax.value_separator)) |separator| {
        const key = token[0..separator];
        const value = token[separator + 1 ..];
        if (value.len == 0) utils.failAt("missing color value", offset + separator + 1);

        const background = if (std.mem.eql(u8, key, "fg"))
            false
        else if (std.mem.eql(u8, key, "bg"))
            true
        else
            failUnknown(token, offset);

        const color = parseColorValue(config, value, offset + separator + 1);
        if (background) {
            result.state.background = color;
        } else {
            result.state.foreground = color;
        }
        return;
    }

    for (config.styles) |named| {
        if (!std.mem.eql(u8, token, named.name)) continue;
        applyStyle(named.style, &result.state);
        return;
    }

    failUnknown(token, offset);
}

fn parseColorValue(
    comptime config: Config,
    value: []const u8,
    offset: usize,
) Color {
    if (std.mem.eql(u8, value, "default")) return .default;
    if (parseBasicColor(value)) |color| return colorValue(color);

    var separator_count: usize = 0;
    for (value) |byte| {
        if (byte == config.syntax.channel_separator) separator_count += 1;
    }

    if (separator_count == 0) {
        return .{ .indexed = parseChannel(value, offset) };
    }
    if (separator_count != 2) {
        utils.failAt("RGB colors require exactly three channels", offset);
    }

    var channels: [3]u8 = undefined;
    var channel_index: usize = 0;
    var start: usize = 0;
    var cursor: usize = 0;
    while (cursor <= value.len) : (cursor += 1) {
        if (cursor != value.len and value[cursor] != config.syntax.channel_separator) continue;
        channels[channel_index] = parseChannel(value[start..cursor], offset + start);
        channel_index += 1;
        start = cursor + 1;
    }

    return .{ .rgb = .{ .r = channels[0], .g = channels[1], .b = channels[2] } };
}

fn parseChannel(value: []const u8, offset: usize) u8 {
    if (value.len == 0) utils.failAt("empty numeric color channel", offset);

    var number: u16 = 0;
    for (value, 0..) |byte, index| {
        if (!std.ascii.isDigit(byte)) utils.failAt("color channels must be decimal integers", offset + index);
        number = number * 10 + (byte - '0');
        if (number > 255) utils.failAt("color channel exceeds 255", offset);
    }
    return @intCast(number);
}

fn applyStyle(style: Style, state: *FormatState) void {
    if (style.foreground) |color| state.foreground = color;
    if (style.background) |color| state.background = color;
    for (style.effects) |effect| setEffect(state, effect, true);
}

fn emitTransition(
    writer: anytype,
    before: FormatState,
    after: FormatState,
    force_reset: bool,
) void {
    if (!force_reset and statesEqual(before, after)) return;

    writer.writeAll("\x1b[");
    var has_parameter = false;

    if (force_reset) {
        writeParameter(writer, &has_parameter, 0);
        emitColorIfActive(writer, &has_parameter, after.foreground, false);
        emitColorIfActive(writer, &has_parameter, after.background, true);
        for (std.enums.values(Effect)) |effect| {
            if (hasEffect(after, effect)) writeParameter(writer, &has_parameter, effect.enableCode());
        }
    } else {
        if (!std.meta.eql(before.foreground, after.foreground)) {
            writeColor(writer, &has_parameter, after.foreground, false);
        }
        if (!std.meta.eql(before.background, after.background)) {
            writeColor(writer, &has_parameter, after.background, true);
        }

        emitIntensityTransition(writer, &has_parameter, before, after);
        inline for (.{ Effect.italic, Effect.underline, Effect.blink, Effect.reverse, Effect.hidden, Effect.strikethrough }) |effect| {
            const was_enabled = hasEffect(before, effect);
            const is_enabled = hasEffect(after, effect);
            if (was_enabled == is_enabled) continue;
            writeParameter(writer, &has_parameter, if (is_enabled) effect.enableCode() else effect.disableCode());
        }
    }

    std.debug.assert(has_parameter);
    writer.writeAll("m");
}

fn emitIntensityTransition(
    writer: anytype,
    has_parameter: *bool,
    before: FormatState,
    after: FormatState,
) void {
    const before_bold = hasEffect(before, .bold);
    const before_dim = hasEffect(before, .dim);
    const after_bold = hasEffect(after, .bold);
    const after_dim = hasEffect(after, .dim);
    if (before_bold == after_bold and before_dim == after_dim) return;

    if ((before_bold and !after_bold) or (before_dim and !after_dim)) {
        writeParameter(writer, has_parameter, 22);
        if (after_bold) writeParameter(writer, has_parameter, Effect.bold.enableCode());
        if (after_dim) writeParameter(writer, has_parameter, Effect.dim.enableCode());
        return;
    }

    if (!before_bold and after_bold) writeParameter(writer, has_parameter, Effect.bold.enableCode());
    if (!before_dim and after_dim) writeParameter(writer, has_parameter, Effect.dim.enableCode());
}

fn emitColorIfActive(writer: anytype, has_parameter: *bool, color: Color, background: bool) void {
    if (!isDefaultColor(color)) writeColor(writer, has_parameter, color, background);
}

fn writeColor(writer: anytype, has_parameter: *bool, color: Color, background: bool) void {
    switch (color) {
        .default => writeParameter(writer, has_parameter, if (background) 49 else 39),
        .basic => |basic| writeParameter(writer, has_parameter, ansi.basicCode(basic, false, background)),
        .bright => |basic| writeParameter(writer, has_parameter, ansi.basicCode(basic, true, background)),
        .indexed => |index| {
            writeParameter(writer, has_parameter, if (background) 48 else 38);
            writeParameter(writer, has_parameter, 5);
            writeParameter(writer, has_parameter, index);
        },
        .rgb => |rgb| {
            writeParameter(writer, has_parameter, if (background) 48 else 38);
            writeParameter(writer, has_parameter, 2);
            writeParameter(writer, has_parameter, rgb.r);
            writeParameter(writer, has_parameter, rgb.g);
            writeParameter(writer, has_parameter, rgb.b);
        },
    }
}

fn writeParameter(writer: anytype, has_parameter: *bool, value: u8) void {
    if (has_parameter.*) writer.writeAll(";");
    has_parameter.* = true;
    writeDecimal(writer, value);
}

fn writeDecimal(writer: anytype, value: u8) void {
    var buffer: [3]u8 = undefined;
    var start: usize = buffer.len;
    var remaining = value;
    while (true) {
        start -= 1;
        buffer[start] = '0' + remaining % 10;
        remaining /= 10;
        if (remaining == 0) break;
    }
    writer.writeAll(buffer[start..]);
}

const ParsedBasicColor = struct {
    color: BasicColor,
    bright: bool,
};

fn parseBasicColor(name: []const u8) ?ParsedBasicColor {
    const bright_prefix = "bright-";
    const bright = std.mem.startsWith(u8, name, bright_prefix);
    const base = if (bright) name[bright_prefix.len..] else name;

    const color: BasicColor = if (std.mem.eql(u8, base, "black"))
        .black
    else if (std.mem.eql(u8, base, "red"))
        .red
    else if (std.mem.eql(u8, base, "green"))
        .green
    else if (std.mem.eql(u8, base, "yellow"))
        .yellow
    else if (std.mem.eql(u8, base, "blue"))
        .blue
    else if (std.mem.eql(u8, base, "magenta"))
        .magenta
    else if (std.mem.eql(u8, base, "cyan"))
        .cyan
    else if (std.mem.eql(u8, base, "white"))
        .white
    else
        return null;

    return .{ .color = color, .bright = bright };
}

fn colorValue(color: ParsedBasicColor) Color {
    return if (color.bright)
        .{ .bright = color.color }
    else
        .{ .basic = color.color };
}

fn parseEnabledEffect(name: []const u8) ?Effect {
    if (std.mem.eql(u8, name, "bold")) return .bold;
    if (std.mem.eql(u8, name, "dim")) return .dim;
    if (std.mem.eql(u8, name, "italic")) return .italic;
    if (std.mem.eql(u8, name, "underline")) return .underline;
    if (std.mem.eql(u8, name, "blink")) return .blink;
    if (std.mem.eql(u8, name, "reverse")) return .reverse;
    if (std.mem.eql(u8, name, "hidden")) return .hidden;
    if (std.mem.eql(u8, name, "strikethrough")) return .strikethrough;
    return null;
}

fn parseDisabledEffect(name: []const u8) ?Effect {
    if (std.mem.eql(u8, name, "no-italic")) return .italic;
    if (std.mem.eql(u8, name, "no-underline")) return .underline;
    if (std.mem.eql(u8, name, "no-blink")) return .blink;
    if (std.mem.eql(u8, name, "no-reverse")) return .reverse;
    if (std.mem.eql(u8, name, "no-hidden")) return .hidden;
    if (std.mem.eql(u8, name, "no-strikethrough")) return .strikethrough;
    return null;
}

fn setEffect(state: *FormatState, effect: Effect, enabled: bool) void {
    const mask = effectMask(effect);
    if (enabled) {
        state.effects |= mask;
    } else {
        state.effects &= ~mask;
    }
}

fn hasEffect(state: FormatState, effect: Effect) bool {
    return state.effects & effectMask(effect) != 0;
}

fn effectMask(effect: Effect) u8 {
    return @as(u8, 1) << @intFromEnum(effect);
}

fn statesEqual(a: FormatState, b: FormatState) bool {
    return std.meta.eql(a.foreground, b.foreground) and
        std.meta.eql(a.background, b.background) and
        a.effects == b.effects;
}

fn isDefaultColor(color: Color) bool {
    return color == .default;
}

fn failUnknown(token: []const u8, offset: usize) noreturn {
    utils.failAt(std.fmt.comptimePrint("unknown directive '{s}'", .{token}), offset);
}

fn validateConfig(comptime config: Config) void {
    const characters = [_]u8{
        config.syntax.marker,
        config.syntax.item_separator,
        config.syntax.value_separator,
        config.syntax.channel_separator,
    };

    inline for (characters, 0..) |character, index| {
        if (!std.ascii.isPunctuation(character) or character == '{' or character == '}') {
            utils.failConfig("syntax characters must be ASCII punctuation other than braces");
        }
        inline for (characters[index + 1 ..]) |other| {
            if (character == other) utils.failConfig("syntax characters must be distinct");
        }
    }

    inline for (config.styles, 0..) |named, index| {
        validateStyleName(named.name);
        inline for (named.name) |character| {
            if (character == config.syntax.item_separator or
                character == config.syntax.value_separator or
                character == config.syntax.channel_separator)
            {
                utils.failConfig(std.fmt.comptimePrint("style name '{s}' contains a syntax separator", .{named.name}));
            }
        }
        if (isReservedName(named.name)) {
            utils.failConfig(std.fmt.comptimePrint("style name '{s}' is reserved", .{named.name}));
        }
        inline for (config.styles[index + 1 ..]) |other| {
            if (std.mem.eql(u8, named.name, other.name)) {
                utils.failConfig(std.fmt.comptimePrint("duplicate style name '{s}'", .{named.name}));
            }
        }

        var seen_effects: u8 = 0;
        inline for (named.style.effects) |effect| {
            const mask = effectMask(effect);
            if (seen_effects & mask != 0) {
                utils.failConfig(std.fmt.comptimePrint("style '{s}' repeats an effect", .{named.name}));
            }
            seen_effects |= mask;
        }
    }
}

fn validateStyleName(comptime name: []const u8) void {
    if (name.len == 0 or !std.ascii.isAlphabetic(name[0])) {
        utils.failConfig("style names must start with an ASCII letter");
    }
    inline for (name[1..]) |character| {
        if (!std.ascii.isAlphanumeric(character) and character != '-' and character != '_') {
            utils.failConfig(std.fmt.comptimePrint("invalid style name '{s}'", .{name}));
        }
    }
}

fn isReservedName(comptime name: []const u8) bool {
    return std.mem.eql(u8, name, "reset") or
        std.mem.eql(u8, name, "normal-intensity") or
        parseBasicColor(name) != null or
        parseEnabledEffect(name) != null or
        parseDisabledEffect(name) != null;
}

test {
    _ = @import("tests.zig");
    _ = @import("terminal.zig");
}
