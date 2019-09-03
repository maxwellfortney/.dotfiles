Maxwell Fortney's Arch i3 Dotfiles

# Prerequisites

1.) Stuff you will need 

`sudo pacman -S polybar i3-gaps rofi `


# Installing

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
