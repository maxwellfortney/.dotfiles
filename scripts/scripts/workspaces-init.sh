#!/usr/bin/env bash

sleep.5
i3-msg 'workspace 3; exec urxvt, exec pcmanfm'
sleep .5
i3-msg 'workspace 2; exec urxvt -e sh -c "sudo code"'
sleep .5
i3-msg 'workspace 1; exec google-chrome-stable'
sleep .5
