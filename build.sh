#!/bin/bash

acc source/weapon-menu.acs acs/weapon-menu.o \
&& \
rm -f weapon-menu.pk3 \
&& \
git log --pretty=format:"-%d %ai %s%n" > changelog.txt \
&& \
zip weapon-menu.pk3 \
    acs/weapon-menu.o \
    sounds/WMSWTCH1.wav \
    sounds/WMSWTCH2.wav \
    sounds/WMSWTCH3.wav \
    sounds/WMTHROW.lmp \
    source/data.acs \
    source/weapon-menu.acs \
    sprites/WDOTA0.png \
    sprites/WMPFC0.lmp \
    sprites/WMPFD0.lmp \
    MINIPLWK.lmp \
    MINIPL_W.lmp \
    MM2SFNTO.fon2 \
    README.md \
    WeaponMenuInterface.txt \
    autodetection.cfg \
    changelog.txt \
    cvarinfo.txt \
    keyconf.txt \
    loadacs.txt \
    menudef.txt \
    sndinfo.txt \
    textures.txt \
    zscript.txt \
&& \
cp weapon-menu.pk3 weapon-menu-$(git describe --abbrev=0 --tags).pk3 \
&& \
gzdoom -glversion 3 -file \
       weapon-menu.pk3 \
       ~/Programs/Games/wads/maps/DOOMTEST.wad \
       $1 \
       +map test \
       -nomonsters
