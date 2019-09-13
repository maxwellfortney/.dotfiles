#/usr/bin/env bash

i3-msg 'workspace 3; exec --no-startup-id urxvt, exec --no-startup-id pcmanfm'
sleep 1
i3-msg 'workspace 2; exec urxvt -e sh -c "echo '1208' | sudo -S code"'
sleep 2
i3-msg 'workspace 4; exec --no-startup-id spotify'
sleep 3
i3-msg 'workspace 1; exec --no-startup-id chromium'
