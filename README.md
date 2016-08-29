gbc2Tga - conversion tool from GBC tiles and palettes to .tga file.
=========
 
Tool was written for GBC [Crystalis](http://chief-net.ru/index.php?option=com_content&task=view&id=138&Itemid=37) translation project. Crystalis uses Hicolour technique for it's title and game over screens. This tool can convert plain (uncompressed) tiles and palettes set to one .tga file for further editing and pasting into ROM (or creating your own Hicolour demo). For reverse conversion, please use "TGA2GBC" tool by Jeff Frohwein.

Palettes manipulation is the core of Hicolour technique. It uses GBC's hardware ability to access palettes memory during HBlank, which theoretically means that every scanline can have it's own set out of 8 palettes. Practically, Z80 is too slow for that, but each 2 scanlines can have totally new 8 palettes. There's also an GBC interleaving factor comes in, which shift palettes sets between left and right parts of screen. 

Each color is 16 bits, so 0x800 colors. each scanline is written 4 palettes, 4 colors each (10 colors), (0x80 scanlines total)
Screen is divided on 16x2 blocks, which share one palette, whole screen contains (128*128)/(16*2) = 512 of such blocks, each pal stored as 8 bytes, so all palettes are stored in 512*8 = 0x1000 bytes
and 0x10 tiles in height (i.e. 0x80 scanlines) 
 
Please check my [notes](https://romhack.github.io/doc) for more information.

```
Usage: gbc2Tga [-v]| NAME
  NAME is a name for both NAME.gfx (binary tiles) and NAME.pal (binary palettes), 
       which should be available in application's directory
  -v      show version number
```

Source can be compiled with [Haskell stack](http://docs.haskellstack.org/en/stable/install_and_upgrade/). 

Griever (romhack.github.io)
