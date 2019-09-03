# Maxwell Fortney's Arch i3 Dotfiles Managed With GNU Stow

## Prerequisites

1.) Stuff you will need 

`sudo pacman -S polybar i3-gaps rofi `


## Installing

1.) Install [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) and [Git](https://git-scm.com/docs)  
`sudo pacman -S stow git`

2.) Cd to your home directory  
`cd ~`

3.) Clone [this](https://github.com/maxwellfortney/.dotfiles) github repo  
`git clone https://github.com/maxwellfortney/.dotfiles.git`

4.) Cd into the downloaded directory  
`cd ~/.dotfile`

5.) Using `stow` select the packages you want to install. Ex.  
`stow bash fans i3 polybar rofi x pictures scripts` 

6.) Done!

## Optional but recommended font rendering
1.) Install fonts
`sudo pacman -S ttf-dejavu ttf-liberation noto-fonts`
2.) Symlink the fonts
` sudo ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
  sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
  sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d`
3.)Uncomment the bottom line in this file
`sudo nano /etc/profile.d/freetype2.sh`
4.)Create this file at 
`sudo nano /etc/fonts/local.conf`
and paste in this
`  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
      <match>
          <edit mode="prepend" name="family"><string>Noto Sans</string></edit>
      </match>
      <match target="pattern">
          <test qual="any" name="family"><string>serif</string></test>
          <edit name="family" mode="assign" binding="same"><string>Noto Serif</string></edit>
      </match>
      <match target="pattern">
          <test qual="any" name="family"><string>sans-serif</string></test>
          <edit name="family" mode="assign" binding="same"><string>Noto Sans</string></edit>
      </match>
      <match target="pattern">
          <test qual="any" name="family"><string>monospace</string></test>
          <edit name="family" mode="assign" binding="same"><string>Noto Mono</string></edit>
      </match>
  </fontconfig>
`
