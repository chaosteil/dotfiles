#!/usr/bin/env bash

tmpbg=`mktemp /tmp/lockscreen.XXXXXXXXXX.png` || exit 1

scrot "$tmpbg"
convert "$tmpbg" -scale 10% -scale 1000% "$tmpbg"
i3lock -u -i "$tmpbg"
rm "$tmpbg"
