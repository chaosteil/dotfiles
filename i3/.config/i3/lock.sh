#!/usr/bin/env bash

icon=$HOME/.config/i3/lockicon.png
#tmpbg=$(mktemp /tmp/lockscreen.XXXXXXXXXX.png) || exit 1

#scrot "$tmpbg"
#convert "$tmpbg" -scale 10% -scale 1000% "$tmpbg"
#convert "$tmpbg" "$icon" -gravity SouthWest -geometry +100+100 -composite "$tmpbg"
betterlockscreen --lock dimblur
#rm "$tmpbg"
