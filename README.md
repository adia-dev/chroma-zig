# Chroma

**Version:** 0.13.0  
**License:** MIT  
**Language:** [Zig](https://ziglang.org)

Chroma is a Zig library for advanced ANSI color and text styling in terminal output. It allows developers to dynamically format strings with embedded placeholders (e.g. `{red}`, `{bold}`, `{fg:255;100;0}` for true color) and converts them into ANSI escape sequences. This makes it easy to apply complex styles, switch between foreground/background colors, and reset formatting on the fly—all at compile time.

<img width="720" alt="chroma" src="https://github.com/user-attachments/assets/251f16b7-8cfc-4222-86b6-699d05976c4b">

## ✨ Features

- **Simple, Readable Syntax:**  
  Use `{red}`, `{bold}`, or `{green,bgBlue}` inline within strings for clear and maintainable code.

- **Comprehensive ANSI Codes:**  
  Support for standard colors, background colors, bold, italic, underline, dim, and even less commonly supported effects like `blink` and `reverse`.

- **Extended and True Color Support:**  
  Take advantage of ANSI 256 extended color codes and true color (24-bit) formats using syntax like `{fg:120}`, `{bg:28}`, or `{fg:255;100;0}` for fine-grained color control.

- **Compile-Time Safety:**  
  Chroma verifies format strings at compile time, reducing runtime errors and ensuring your formatting instructions are valid.

- **Reset-Friendly:**  
  Automatically appends `"\x1b[0m"` when necessary, ensuring that styles don’t “bleed” into subsequent output.

## 🚀 Getting Started

### Prerequisite

1. Fetch the project using `zig fetch`

```bash
zig fetch --save https://github.com/adia-dev/chroma-zig/archive/refs/heads/main.zip
```

Or manually paste this in your `build.zig.zon`

```zig
.dependencies = .{
    // other deps...
    .chroma = .{
        .url = "https://github.com/adia-dev/chroma-zig/archive/refs/heads/main.zip",
        .hash = "12209a8a991121bba3b21f31d275588690dc7c0d7fa9c361fd892e782dd88e0fb2ba",
    },
    // ...
},
```

1. **Add Chroma to Your Zig Project:**
   Include Chroma as a dependency in your `build.zig` or your `build.zig.zon`. For example:

   ```zig
   const std = @import("std");

   pub fn build(b: *std.Build) void {
       const target = b.standardTargetOptions(.{});
       const optimize = b.standardOptimizeOption(.{});

       const lib = b.addStaticLibrary(.{
           .name = "chroma",
           .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/lib.zig" } },
           .target = target,
           .optimize = optimize,
       });

       b.installArtifact(lib);
   }
   ```

2. **Import and Use:**
   After building and installing, you can import `chroma` into your Zig code:

```zig
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

```

3. **Run and Test:**
   - Build your project with `zig build`.
   - Run your binary and see the styled output in your terminal!

## 🧪 Testing

Chroma includes a suite of unit tests to ensure reliability:

```bash
zig build test
```

If all tests pass, you’re good to go!

## 🔧 Configuration

Chroma works out-of-the-box. For more complex scenarios (e.g., custom labels, multiple color formats), refer to `src/lib.zig` and `src/ansi.zig` for detailed code comments that explain available options and their intended usage.

## 📦 New in Version 0.13.0

- **Updated Compatibility:** Now aligned with Zig `0.13.0`.
- **Improved Parser Logic:** More robust handling of multiple formats within the same placeholder.
- **Better Testing:** Additional tests ensure extended color and true color formats behave as expected.
- **Performance Tweaks:** Minor compile-time optimizations for faster builds.

## 🤝 Contributing

Contributions are welcome! To get involved:

1. **Fork & Clone:**  
   Fork the repository and clone it locally.

2. **Branch & Develop:**  
   Create a new branch and implement your changes or new features.

3. **Test & Document:**  
   Run `zig build test` to ensure your changes haven’t broken anything. Update or add documentation as needed.

4. **Pull Request:**  
   Submit a Pull Request describing what you changed and why. We’ll review and merge it if everything looks good.

## 📝 License

[MIT License](./LICENSE)

_Chroma aims to simplify ANSI coloring in Zig, making your command-line tools, logs, and output more expressive and visually appealing._
