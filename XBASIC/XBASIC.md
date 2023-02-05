XBASIC -  Model I Level II + Extensions
=======================================

Version: 0.0.1-alpha




Statements
----------

### New Statements


#### `MOVE src, dest, len`

Move a block of `len` bytes from `src` to `dest`. Performs an `LDIR` or an `LDDR` depending on the move direction.


#### `CALL addr`

Do a system call at `addr`.


#### `DOKE addr, word`

Store a 2-byte `word` at `addr`. 


#### `RENEW`

Recover a program after a `NEW` command.


#### `LINE start, incr`

Renumber a program starting at line number `start` with increment `incr`.


#### `STORE addr, hexbytes$`

Store at `addr`consecutive bytes represented as hex values in `hexbytes$`.

Example:
```basic
10 STORE &H3FFE,"2A2A"
```


#### `EXEC tokens$`

Execute a tokenized BASIC statement. See also `COMP$(text$)`.

Example:
```basic
10 LINE INPUT ">";A$
20 EXEC COMP$(A$)
30 GOTO 10
```


#### `DRAW x1, y1, x2, y2, color`

Draw a block graphics line from point (`x1`,`y1`) to (`x2`,`y2`) in color `color`.
Color is 1 for white and 0 for black.


#### `INVERSE`

Reverse the color of block graphics characters on the screen.


#### `ZAP`

Generate a 'zap' or 'fire phasers' sound.


#### `BEEP cycles, pitch`

Generate a beep with the given `pitch` during `cycles` cycles.


#### `NOISE loops, pitch`

Generate a noise with the given `pitch` during `cycles` cycles.


#### `PLAY music$`

Play a duophonic music string.

The music string is a sequence of single or dual notes with a number indicating their duration.

Format: `{l1}[#][l2[#]]{n}[.]` for notes, and `<{n}[.]` for silences.

- `{l1}` 1st letter = 1st note;
- `#` add a sharp to the preceding note;
- `<` silence;
- `[l2]` optional 2nd letter = 2nd note;
- `{n}` note duration;
- `{.}` beamed duration.


|   Note   | 1st octave | 2nd octave | 3rd octave | 4th octave |
|:--------:|:----------:|:----------:|:----------:|:----------:|
|  C - Do  |      A     |      H     |      O     |      W     |
|  D - Re  |      B     |      I     |      P     |            |
|  E - Mi  |      C     |      J     |      Q     |            |
|  F - Fa  |      D     |      K     |      R     |            |
|  G - Sol |      E     |      L     |      S     |            |
|  A - La  |      F     |      M     |      U     |            |
|  B - Si  |      G     |      N     |      V     |            |

| Duration | Digit |
|:--------:|:-----:|
| Whole    |   1   |
| Half     |   2   |
| Quarter  |   3   |
| Eight    |   4   |
| Sixth    |   5   |

Example (converted from Y. Lempereur's game 'RUNNER'):
```basic
10 DATA L4M5L4
20 DATA M#A5A4M#C5C4M#E5E4M#F5F4M#H5H4I#F5F4JE5E4EB5E4
30 DATA M#A5A4MC5C4LE5E4JF5F4M#H5H4I#F5F4JE5E4CA5C4
40 DATA P#D5D4PF5F4OH5H4MI5I4P#K5K4PI5I4OH5H4I#F5F4
50 DATA JA5A4CA5A4CE5A4FD5A4F#E5A4FD5A4EC5A4B#5C4
60 DATA NE5E4M#G5G4NI5I4M#J5J4NK5K4MJ5J4LI5I4I#G5G4
70 DATA HC5LG4K#F#5LG4L#H5MH#4M#I5NI#4 OJ5<4I#D#3JE2
80 DATA $
90 CLEAR 1000
100 READ A$
110 IF A$="$" THEN 140
120 PLAY A$
130 GOTO 100
140 END
```


#### `"label" [instruction : ...]`

Define a label for GOTO, GOSUB and RESUME statements. The labels are case-sensitive.

Example:
```basic
10 GOSUB "MYSUB"
20 REM next instructions
...
100 "MYSUB" REM My Subroutine
110 REM subroutine's instructions
190 RETURN
```


### Extended Statements


#### `[L]PRINT #var$, [USING "...";] ...`

Print to a string variable. This is useful to format strings with the USING clause.


#### `LPRINT`, `LLIST` if no printer connected

Those statements don't hang if no printer is connected.


#### `LPRINT TAB(1..255), ...`

The TAB clause range for LPRINT is extended to 255.


#### `LINE INPUT [#len,] ["prompt";] [!]var$`

This is the Disk BASIC `LINE INPUT` statement with the following extensions:
- the input string length can be limited using the `#len` clause;
- the input area can be protected against line feeds, clear, etc. by inserting a `!` before the variable name.
This is useful for input forms in database applications.


#### `[ON ...] GOTO|GOSUB (expr)|"label" [,(expr)|"label" ...]`

Computed GOTO. The line number can be computed from an expression (enclosed in parenthesis) or can be a label or a variable (number or string).

Example:
```basic
100 PRINT menu$
110 A$=INKEY$
120 IF A$<"0" OR A$>"2" THEN 120
130 GOSUB (1000+100*VAL(A$))
140 GOTO 100
1000 REM option choice "0"
1010 ...
1090 RETURN
1100 REM option choice "1"
1110 ...
1190 RETURN
1200 REM option choice "2"
1210 ...
1290 RETURN
```


#### `RESUME (expr)|"label"`

See `GOTO`.


#### `LIST (expr)|"label"`

See `GOTO`.


#### `POKE addr, byte [, byte ...]`

Allow a single POKE instruction to poke consecutive bytes in memory.


#### `NEW [addr]`

Delete the program from memory and optionally set a new origin address (ATTENTION: no check on the origin address is made!).


#### `RESTORE [line]`

Restore the DATA pointer, with an optional line number.


#### `CLEAR [stringpool [, himem] ]`

Clear the memory, optionally resize the string pool and optionally set a new HIMEM (ATTENTION: no check on the himem address is made!)



### Level III Basic (L3 Disk Basic) Statements


#### `LINE INPUT [#len,] ["prompt",]`[!] var$

(See in Extended Statements.)


#### `DEF FN name([args, ...]) = expr`


#### `DEF USR[0..9] = addr`




Functions
---------

### New Functions


#### `DEEK(addr)`


#### `ASN(angle)`


#### `ACS(angle)`


#### `HEX$(num)`


#### `BIN$(num)`


#### `CAPS$(text$)`


#### `LOC([addr,] str$)`


#### `&[H]nnnn`, `&Onnnnnn`, `&Bnnnnnnn`


#### `BASFN(tokens$)`

Evaluate a tokenized BASIC expression. See also `COMP$(text$)`.

Example:
```basic
10 LINE INPUT "=";A$
20 PRINT BASFN(COMP$(A$))
30 GOTO 10
```


#### `COMP$(text$)`

Tokenize a BASIC statement or expression.
To expand a tokenized string, use `EXT$(tokens$)`.
To execute a tokenized statement, use `EXEC tokens$`.
To evaluate a tokenized expression, use `BASFN(tokens$)`.

See `EXEC(tokens$)` in New Statements for an example.



#### `EXT$(tokens$)`

Expand a tokenized BASIC back to readable form.



### Level III Basic (L3 Disk Basic) Functions


#### `FN name([args, s...])`


#### `USR[0..9]([args, ...])`


#### `INSTR([pos,] str1$, str2$)`




Other features
--------------

### Lower-case driver with blinking cursor, auto-repeat keys and caps lock

To toggle caps lock, press Shift-0.


### Extended program editor with new hotkeys

The editor hotkeys available while in Direct Mode are:

| HotKey       | Function                                                                      |
| :----------: | ----------------------------------------------------------------------------- |
| `.`          | list the current line                                                         |
| `,`          | edit the current line                                                         |
| `up-arrow`   | list the previous line                                                        |
| `down-arrow` | list the next line                                                            |
| `:`          | list the program up to the current line                                       |
| `@`          | list the program starting from the current line                               |
| `Break`      | list the line where an error occurred                                         |
| `/`          | enter the AUTO mode starting from the current line plus the current increment |


### Long error messages

Long error messages will be printed when an error is raised.

The long error messages are:
```
01: NF - NEXT without FOR
02: SN - Syntax Error
03: RG - RETURN without GOSUB
04: OD - Out of DATA
05: FC - Illegal Function Call
06: OV - Overflow
07: OM - Out of Memory
08: UL - Undefined Line
09: BS - Subscript Out of Range
0A: DD - Redimensioned Array
0B: /0 - Division by Zero
0C: ID - Illegal Direct
0D: TM - Type Mismatch
0E: OS - Out of String Space
0F: LS - String too Long
10: ST - String Formula too Complex
11: CN - Can't CONTinue
12: NR - No RESUME
13: RW - RESUME without ERROR
14: UE - Unprintable ERROR
15: MO - Missing Operand
16: FD - Bad File Data
17: L3 - Function Not Available
18: UE - Undefined Function
```
