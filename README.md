# Chroma

**Version:** 0.13.0  
**License:** MIT  
**Language:** [Zig](https://ziglang.org)

Chroma is a Zig library for advanced ANSI color and text styling in terminal output. It allows developers to dynamically format strings with embedded placeholders (e.g. `{red}`, `{bold}`, `{fg:255;100;0}` for true color) and converts them into ANSI escape sequences. This makes it easy to apply complex styles, switch between foreground/background colors, and reset formatting on the fly—all at compile time.

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
       std.debug.print(chroma.format("{bold,red}Hello, Red World!{reset}\n"), .{});
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
