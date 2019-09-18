# Maxwell Fortney's Desktop Arch i3 Dotfiles Managed With GNU Stow

## Prerequisites

```bash
sudo pacman -S feh compton i3 rofi
```

## Installation

1.) Ensure you have downloaded [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) and [Git](https://git-scm.com/docs).

2.) Ensure you are in your home directory by typing `cd ~`

3.) Clone this branch of the repo using `git clone -b Desktop https://github.com/maxwellfortney/.dotfiles.git`

4.) Move into the downloaded directory `cd ~/.dotfile`

5.) Using `stow` select the packages you want to install, based on their respective directory names. Ex. `stow bash fans i3 polybar rofi scripts` 

6.) Done!