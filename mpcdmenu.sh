#!/bin/bash
mpc play $(export num=0;OLDIFS=$IFS;export IFS=$'\n';>/tmp/play;for i in `mpc playlist`;do let num+=1; export IFS=$OLDIFS; echo "$num:$i">>/tmp/play;export IFS=$'\n'; done;export IFS=$OLDIFS;cat /tmp/play|dmenu -i|awk -F: '{print $1}')
