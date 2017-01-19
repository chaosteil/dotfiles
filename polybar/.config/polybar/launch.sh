#!/usr/bin/env sh

killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done
polybar primary &
if xrandr -q | grep -c "\*" | grep -q "2"
then
  polybar secondary &
fi
