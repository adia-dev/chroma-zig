const std = @import("std");
const chroma = @import("chroma");

const ui = chroma.Formatter(@import("chroma.zon"));

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const stdout_file = std.Io.File.stdout();
    const use_color = try chroma.terminal.detect(
        io,
        init.minimal.environ,
        stdout_file,
        .auto,
    );

    var output_buffer: [2048]u8 = undefined;
    var file_writer = stdout_file.writer(io, &output_buffer);
    const writer = &file_writer.interface;

    try printExample(writer, use_color);
    try writer.flush();
}

fn printExample(writer: *std.Io.Writer, use_color: bool) !void {
    const heading = comptime ui.render(
        "{@brand}CHROMA 0.2{@reset}  comptime-first terminal styling\n" ++
            "{@muted}Configured by examples/chroma.zon{@reset}\n\n",
    );
    try writeRendered(writer, heading, use_color);

    const semantic_styles = comptime ui.render(
        "  {@success}✓ success{@reset}   Build completed\n" ++
            "  {@warning}⚠ warning{@reset}   Configuration changed\n" ++
            "  {@failure}✗ failure{@reset}   Connection refused\n\n",
    );
    try writeRendered(writer, semantic_styles, use_color);

    const custom_grammar = comptime ui.render(
        "  {@label}custom grammar{@reset}  {@fg=255/120/50|bold}{s}{@reset}\n" ++
            "  {@label}runtime policy{@reset}  {s}\n",
    );
    if (use_color) {
        try writer.print(custom_grammar.ansi, .{ "{@fg=R/G/B|effect}", "ANSI selected" });
    } else {
        try writer.print(custom_grammar.plain, .{ "{@fg=R/G/B|effect}", "plain text selected" });
    }
}

fn writeRendered(writer: *std.Io.Writer, comptime rendered: chroma.Rendered, use_color: bool) !void {
    try writer.writeAll(rendered.select(use_color));
}
