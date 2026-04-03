# Memory Browser Guide

The Memory Browser lets you peek inside the Commodore 64's brain — reading and writing the 64KB of memory that controls everything from what's on screen to what sounds the SID chip is making.

## Getting Started

1. Connect to your C64 Ultimate in Toolbox mode
2. Click **Memory Browser** in the sidebar
3. You'll see a hex dump of memory starting at address $0000

## Navigation

- **Address field**: Type a hex address (e.g., `D020`) and press Enter or click Go
- **Jump to…** dropdown: Quick presets for common memory regions
- **Prev/Next**: Move through memory in 256-byte pages
- **Auto-refresh**: Check this to see memory update live (every 250ms)

## What You're Looking At

Each row shows:
- **Address** (yellow): The starting memory address for that row
- **Hex bytes**: 16 bytes shown in hexadecimal (00-FF)
- **Characters** (gray): ASCII representation of those bytes (· for non-printable)

## Fun Things to Try

### Change the Border Color
1. Jump to **$D020** (VIC-II registers)
2. Enable **Edit** mode
3. Click the first byte (the border color register)
4. Type a new color value (0-F):
   - `00` = Black, `01` = White, `02` = Red, `03` = Cyan
   - `04` = Purple, `05` = Green, `06` = Blue, `07` = Yellow
   - `08` = Orange, `09` = Brown, `0A` = Light Red
   - `0B` = Dark Gray, `0C` = Medium Gray, `0D` = Light Green
   - `0E` = Light Blue, `0F` = Light Gray
5. Click **Write** — watch the border change!

### Change the Background Color
Same as above but edit the byte at **$D021** (second byte in the VIC-II page).

### See What's On Screen
1. Jump to **Screen** ($0400)
2. The 1000 bytes here (40 columns × 25 rows) are the screen codes for each character position
3. Turn on **Auto-refresh** to watch it update as text appears on the C64

### Play a Sound
1. Jump to **SID** ($D400)
2. Enable Edit mode
3. Set these bytes to hear a note:
   - $D400 = `17` (frequency low)
   - $D401 = `11` (frequency high)
   - $D405 = `09` (attack/decay)
   - $D406 = `00` (sustain/release)
   - $D418 = `0F` (volume max)
   - $D404 = `11` (gate on + triangle wave)
4. Click Write after each change (or edit all, then Write once)

### Peek at Your BASIC Program
1. Jump to **BASIC** ($0801)
2. This shows your BASIC program in tokenized form
3. Each line starts with a pointer to the next line, then the line number, then tokenized bytes

## Important Memory Regions

| Address | Name | Description |
|---------|------|-------------|
| $0000-$00FF | Zero Page | Fast-access processor variables |
| $0277-$0280 | Keyboard Buffer | Characters waiting to be processed (max 10) |
| $0400-$07FF | Screen Memory | 40×25 character codes (what's displayed) |
| $0801-$9FFF | BASIC Program | Your BASIC code in tokenized form |
| $A000-$BFFF | BASIC ROM | The BASIC interpreter (read-only) |
| $D000-$D02E | VIC-II | Graphics chip — sprites, colors, modes |
| $D020 | Border Color | Single byte, values 0-15 |
| $D021 | Background Color | Single byte, values 0-15 |
| $D400-$D41C | SID | Sound chip — 3 voices, filters |
| $D800-$DBFF | Color RAM | Color for each screen character (4-bit) |
| $DC00-$DC0F | CIA 1 | Keyboard scanning, joystick ports |
| $DD00-$DD0F | CIA 2 | Serial bus, user port |
| $E000-$FFFF | KERNAL ROM | Operating system routines (read-only) |

## Tips

- **Auto-refresh + Screen memory** is a great way to watch a program run in real-time
- **VIC-II registers** at $D000 let you move sprites, change graphics modes, and more
- **Be careful editing memory while programs are running** — you might crash the C64! (Just reset if that happens)
- The memory browser reads whatever the CPU sees — if ROM is banked in, you'll see ROM contents; if I/O is mapped in, you'll see registers
