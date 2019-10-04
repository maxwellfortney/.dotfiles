# Defined in - @ line 1
function dots --description 'alias dots=/usr/bin/git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME/.dotfiles/'
	/usr/bin/git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME/.dotfiles/ $argv;
end
