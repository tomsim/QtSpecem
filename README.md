
QtSpecem v0.81
(C) 2019 Rui Fernando Ferreira Ribero

Z80 emulation core (C) 1991-2019 Rui Fernando Ferreira Ribeiro

New Qt5 ZX Spectrum emulator

Z80 C emulation from my old emulators WSpecem/emz80, corrected, fixed and improved to support the documented and undocumented funcionalities of a Z80 from Zilog (including WZ/MEMPTR).

Real time emulator, no sound support. Still (very) rudimentary user interface.

The project idea will be being an debugger, for the moment just uploaded for backup and for people to test the Z80 part.

Supports drag-and-drop, file as arguments, and SLT, TAP, Z80, SNA, SNX, SIT, RAW, ZX, PRG, ACH, ROM, DAT, SCR, SEM snapshot emulation formats.

For now pressing F2 saves Z80 snapshots at /tmp.

Kempston Joystick ALT + cursor keys

KNOWN BUGs

- SHIFT 0-9 does not work due to a Qt feature, use CTRL 0-9 instead.

"Features"

Loading a TAP file introduces patches to the ROM. A ROM checksum will fail after loading/drag and dropping a TAP file.

TODO:

- Flash
- Debugger
- Save/Load Menu

For compiling:


You need to install the Qt5 development framework.

qmake

make

. Tested in MacOS Mojave and Debian 10.
