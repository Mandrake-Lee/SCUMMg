

# SCUMMg - A GNU SCUMM Compiler

## ->THIS PROJECT IS NOT FUNCTIONAL FOR NOW

## I. What is SCUMMg ?
SCUMMg is an attempt to recreate a compiler for the SCUMM engine *using the original language* and can be seen as a make-up of the fantastic scummC.

The goal behind this project is to use the original Lucasarts syntax and manuals that were not available at the moment of the development of scummC.

These are the main sources:
* http://tandell.com/misc/SCUMM-Tutorial-0.1.pdf
* https://web.archive.org/web/20170225190343/http://wilmunder.com/Arics_World/Games_files/The%20SCUMM%20Manual.pdf
* https://web.archive.org/web/20160412081654/http://wilmunder.com/Arics_World/Games_files/The%20SCUMM%20Manual%20-%20Glossary.pdf


**WHAT FOLLOWS NOW IS THE DESCRIPTION OF ScummC**

ScummC is a set of tools allowing to create SCUMM games from scratch.
It is capable to create games for SCUMM version 6 (used by Day Of
The Tentacle, aka dott) and somewhat support version 7 (used by Full
Throttle).


## II. This release

In this release you will find:

  * scc      : the compiler
  * sld      : the linker
  * boxedit  : a room box editor
  * cost     : a costume compiler
  * char     : a charset converter
  * costview : a costume viewer/editor prototype
  * soun     : a simple soun resources builder
  * midi     : a tool to hack MIDI files

Some utilities that might (or might not) be useful with SCUMM related
hacking.

  * zpnn2bmp : convert ZPnn blocks to bmp
  * imgsplit : split a bmp (it conserve the palette)
  * imgremap : exchange two colors (both palette and data)
  * palcat   : combine bmp palettes.
  * raw2voc  : read some raw 8bit unsigned samples and pack them in a voc.
  * scvm     : a VM prototype that should become a debugger some day.


## III. Compiling it

Requirements:

  * GNU make >= 3.80
  * bison >= 2.7
  * GTK >= 2.4 (for boxedit and costview)

Optional libraries:

  * Freetype (to build charsets from ttf fonts)
  * SDL (for scvm)
  * xsltproc (for the man pages and help messages)

To compile just run configure and then make (or gmake). If you want to
also compile the extra utilities run make all. To see all available
targets run make help.

The code is now continuously tested with Travis CI and AppVeyor,
the following platforms are currently known to work:

  * GNU/Linux x86
  * Mingw64 x86 (native and cross compiled from GNU/Linux)
  * OSX x86

Past versions have been known to build on NetBSD, FreeBSD, OpenBSD,
Solaris, OS2 and AmigaOS.


## IV. What can i do with that ?

Already quite a lot ;) All major features from the engine are usable,
and a full game can be built from scratch. SCUMM version 6 is the default
target, but version 7 is also partially supported.


## V. Getting started

An example is provided. Just cd into one of the example directory and
run make. If all went well it should produce 3 files: scummc6.000,
scummc6.001 and scummc6.sou.

To run ScummC games with ScummVM their is two ways. The recommended
way is to patch ScummVM to have it recognise ScummC games and run them
without any game specific hack. Otherwise you can run the game as Day
of the tentacle, this is not recommended because a few hacks might
kick in. However that shouldn't be a problem with small test games.

To patch ScummVM cd in your ScummVM source directory and run:
 `patch -p1 < ~/scummc-X.X/patches/scummvm-Y.Y.Y-scummc.diff`

Alternatively you can use the original LEC interpreter, but be warned
that a few things (namely save/load) are currently not working with it.
Not that you really need to save in the example game ;)

Note that to run the game as Day of the Tentacle with ScummVM or with the
LEC interpreter you must give the following extra options to sld:
`-o tentacle -key 0x69`. For the LEC interpreter you must also rename
tentacle.sou to monster.sou. The example games can be built as Day of
the Tentacle by running `make tentacle`.

Documentation is currently limited, the two most useful sources are:

  * https://github.com/AlbanBedel/scummc/wiki

    For all ScummC specific documentation and some technical stuff
    about SCUMM internals.

  * http://wiki.scummvm.org/index.php/SCUMM_Technical_Reference

    More techinal documentation. If you are new to SCUMM you should at least
    read http://wiki.scummvm.org/index.php/SCUMM_Virtual_Machine which give
    a nice overview of the VM.

  * The man pages

    The man directory contain man pages for the various tools. Just open
    the XML files with any XSLT capable browser (like firefox).


## VI. The box editor

This tool allow you to define the boxes in your room in a graphical
manner and to name them for easy reffering in the scripts.
Be warned that the interface is perhaps a bit unusual. The 2 open and save
buttons should be self-explicit. But both have an alternative action if
clicked with a shift key pressed. Namely open a background image and
save as. On the view you have following actions:

 * left button        : add point to the selection
 * right button       : remove point from the selection

 * shift+left button  : add box to the selection
 * shift+right button : remove box from the selection

 * ctrl+left button   : select other point (a point need to be selected first)
 * ctrl+right button  : select other box (a box need to be selected first)

 * left button drag   : move the selection
 * middle button drag : move the view

There are also the following keys:

 * b         : create a new box
 * d / suppr   : delete the selection
 * esc       : clear selection
 * u / q       : undo
 * r / o       : redo
 * > / +       : zoom in
 * < / -       : zoom out
 * s         : save
 * S         : save as

I'm using a Dvorak layout so the o/q are well placed, i put u/r as
alternative because they are easy to remember. However i would be glad
to add some qzerty friendly bindings.

On the command line you can specify a box filename and/or a background image
with the -img parameter.


## VII. Warning and other legal stuff

Be warned this is still beta, some features are still missing. Use at your
own risk. All the code has been written by myself and is under GPL.
Some bit of code have been stolen (ie. copy/pasted and c-ifier) from scummvm.
I don't have time for legal stuff at the moment so just play fair ;)


## VIII. Thanks

Big thanks to all ScummVM coders and contributors. All this would
have never been possible without you !!!!

Big thanks to David Given, http://www.cowlark.com/scumm was a very
useful source.

Big thanks to sourceforge.net for the compile farm that allowed making
this software portable on 10 different platforms.

Big thanks to Jesse McGrew and James Urquhart for their contributions.

Big thanks to Gerrit Karius for OpenQuest and generally making this
project move forward.

And last but not least, thanks to the few people who at least tried to
compile and perhaps even used a bit one of those early versions.


## IX. Contact

ScummC is hosted on github: https://github.com/AlbanBedel/scummc
There you can find the wiki, bug tracker, etc

For anything relevant to ScummC and SCUMM games developement use
the github bug tracker at https://github.com/AlbanBedel/scummc/issues,
for anything else I can be reached at albeu@free.fr.

Patches and suggestions of all kinds are always welcome!
