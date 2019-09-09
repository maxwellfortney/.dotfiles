#/usr/bin/env bash

sleep.5
i3-msg 'workspace 3; exec urxvt, exec pcmanfm'
i3-msg 'workspace 2; exec urxvt -e sh -c "echo '1208' | sudo -S code"'
sleep 3
i3-msg 'workspace 1; exec google-chrome-stable'
sleep .5
wmctrl -r "pcmanfm" -b remove,demands_attention
wmctrl -r "urxvt" -b remove,demands_attention
