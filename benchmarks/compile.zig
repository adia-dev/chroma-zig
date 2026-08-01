const chroma = @import("chroma");

comptime {
    const repetitions = 512;
    const input = "{#red,bold}x{#reset}" ** repetitions;
    const expected_unit = "\x1b[31;1mx\x1b[0m";
    const output = chroma.format(input);

    if (output.len != expected_unit.len * repetitions) {
        @compileError("unexpected benchmark output length");
    }
}
