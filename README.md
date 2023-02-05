# XBASIC

XBASIC - Extended BASIC Level II for TRS-80 Model I Cassette

Version: 0.0.1-alpha


## Description

This is an extension for the TRS-80 Model I ROM BASIC Level II, I wrote in the mid 80's, using Microsoft Editor/Assembler Plus.

I recently recovered the source code from cassette, from six separate files, and merged them into one single big .ASM file. 
This file can be assembled to a 500 baud .CAS file using [George Phillips's ZMAC assembler](http://48k.ca/zmac.html).

This extension adds some features to Level II:
- some graphical statements: `DRAW`, `INVERSE`;
- some audio/music statements: `BEEP`, `NOISE`, `ZAP`, `PLAY`;
- some Disk BASIC statements and functions (witn extensions): `LINE INPUT`, `DEF FN`, `DEF USRn`, `FN`, `USRn`, `INSTR`, `&H`, `&O`, `&B`;
- some conversion functions: `HEX$(n)`, `BIN$(n)`, `CAPS$(str$)`, `COMP$(text$)`, `EXT$(tokens$)`;
- dynamic statement execution: `EXEC tokens`, `BASFN(tokens$)`;
- some memory management statements and functions: `DEEK(a)`, `DOKE a,w`, `STORE a,hex$`, `MOVE s,d,l`, `CALL a`, `RENEW`, `LOC(a,str)`;
- labels for GOTO, GOSUB, RESUME;
- computed GOTO, GOSUB, RESUME;
- formatted print to string variable (useful with USING, like C's sfprint()): `PRINT #a$, ...`;
- LINE INPUT with limited length and protected edit area: `LINE INPUT [#len,]["prompt";]!a$`;
- arcsine, arccosine: `ASN(x)`, `ACS(x)`;
- RESTORE with optional line number: `RESTORE [line]`;
- multi-byte mode for POKE: `POKE a,d1,d2,...`;
- program lines renumbering: `LINE [start[,inc]]`;
- lower-case driver with blinking cursor, auto-repeat keys and caps lock;
- extended program editor with new hotkeys;
- long error messages.

More details [here](XBASIC/XBASIC.md).


## Disclaimer

This project is purely for sharing my early work on the Z80... 
There are certainly bugs, defects, missing comments and a lack of error checking, but I don't intend to make that code evolve.
