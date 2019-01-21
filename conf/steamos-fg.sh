#! /bin/bash

set -e

exec "$@" & # start game
sleep 5 # wait a bit for game window

# find window with size greater than 99x99 that is not a steam window
RESULT=$(xwininfo -display ":0" -root -tree | grep -E "[0-9]{3}x[0-9]{3}" | grep -v \"Steam\"\: | grep -v \"SteamOverlay\"\:)
WIN_ID=$(echo "$RESULT" | cut -d' ' -f 1)

# apply STEAM_GAME property to game window so steamos compositor shows game in foreground
xprop -display ":0" -id "$WIN_ID" -f STEAM_GAME 32c -set STEAM_GAME 470470

wait # wait for game exit

