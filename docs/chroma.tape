Require zig

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font Mono, Menlo, monospace"
Set FontSize 17
Set LetterSpacing 0
Set LineHeight 1.15
Set Width 1040
Set Height 430
Set Padding 24
Set Margin 24
Set MarginFill "#11111b"
Set BorderRadius 14
Set WindowBar "Colorful"
Set WindowBarSize 38
Set Theme "Catppuccin Mocha"
Set TypingSpeed 25ms

Hide
Type "export PS1='$ '"
Enter
Type "unset NO_COLOR; export CLICOLOR_FORCE=1"
Enter
Type "clear"
Enter
Show

Type "zig build run"
Enter
Sleep 2s

Screenshot docs/assets/chroma-configurable.png
Sleep 1s
