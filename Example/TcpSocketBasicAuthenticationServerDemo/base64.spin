'':::::::[ On-the-fly Binary-to-Base64 Data Converter ]:::::::::::::::::::::::::::
 
{{{
┌───────────────────────────────────────┐
│      Binary-to-Base64 Converter       │
│(c) Copyright 2011 Bueno Systems, Inc. │
│   See end of file for terms of use.   │
└───────────────────────────────────────┘

This program converts incoming byte streams to Base64, returning one line
at a time.

Version History
───────────────

2011.04.20: Initial release.
2011.09.23: Commented the end of line in the Line method.
2011.10.02: Removed the image logic.  Using these methods for
            basic web authentication in my W5200 project.  I'm
            not expecting a username/password to be larger
            than 64+7

}}

''=======[ Constants ]============================================================

CON

   LINE_LENGTH    = 64          'Sets the Base64 line size. Must be a multiple of 4.
   CR             = 13          'ASCII carriage return.
   LF             = 10          'ASCII linefeed.
   QU             = 34          'ASCII double quote character.  

''=======[ Hub Variables ]========================================================

VAR

  long  triplet                 'Current 8-bit triplet being converted to 6-bit quadruplet.
  word  buf_ptr                 'Index into line buffer.
  byte  buffer[LINE_LENGTH + 7], nbytes  'Line buffer and number of bytes currently in triplet.

''=======[ Public Methods... ]=====================================================

PUB out(octet) | i

  {{ Output the next byte to convert to base64. Returns a base64-encoded line
     once the line is full; otherwise, returns an empty string.
  ''
  ''     `octet: The byte to convert.
  ''
  '' `Example: sio.str(b64.out(image[i])
  ''
  ''     Send base64-encoded data to serial output after encoding ith byte of image.
  }}

  result := @empty
  triplet := triplet << 8 | octet
  if (++nbytes == 3)
    repeat i from 18 to 0 step 6
      buffer[buf_ptr++] := base64(triplet >> i)      
    nbytes~
    if (buf_ptr => LINE_LENGTH)
      result := line      

PUB end

  {{ Output the remaining base64 characters. Append the end of the img tag if
     img was called to start.
  ''
  '' `Example: sio.str(b64.end)
  ''
  ''     Send the rest of the base64-encoded data to serial output.
  }}

  case nbytes~
    1:
      buffer[buf_ptr++] := base64(triplet >> 2)
      buffer[buf_ptr++] := base64(triplet << 4)
      buffer[buf_ptr++] := "="
      buffer[buf_ptr++] := "="
    2:
      buffer[buf_ptr++] := base64(triplet >> 10)
      buffer[buf_ptr++] := base64(triplet >> 4)
      buffer[buf_ptr++] := base64(triplet << 2)
      buffer[buf_ptr++] := "="
  return line          

PUB base64(sextet)

  {{ Encode the six LSBs of sextet as a base64 character.
  ''
  '' `sextet: The six-bit data to convert.
  ''
  '' `Example: base64_char := b64.base64($6789)
  ''
  ''     Convert $6789 & $3f == $09 to base64 and assign to base64_char.
  }}

  return lookupz(sextet & $3f : "A" .. "Z", "a" .. "z", "0" .. "9", "+", "/")

''=======[ Private Methods... ]===================================================

PRI line

  {{ Eet buffer[0] to 0.
     Return a pointer to buffer.
  }}

  if (buf_ptr)
    buf_ptr~
  else
    buffer~
  return @buffer
 
''=======[ Constant Strings ]=====================================================

DAT

endline       byte      CR,LF   'CRLF line ender.
empty         byte      0       'Empty string.

''=======[ License ]===========================================================
{{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                            TERMS OF USE: MIT License                                 │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │
│                                                                                      │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  │
│OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}