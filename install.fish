#!/bin/fish

function has
    type $argv[1] > /dev/null 2>&1
    return $status
end

if not test -d "$NVM_SOURCE"
    set NVM_SOURCE "https://github.com/Alex7Kom/nvm-fish.git"
end

if not test -d "$NVM_DIR"
    set NVM_DIR "$HOME/.nvm-fish"
end

if not has git
	echo >&2 "You need to install git - visit http://git-scm.com/downloads"
	exit 1
end

if test -d "$NVM_DIR"
	echo "=> NVM is already installed in $NVM_DIR, trying to update"
	echo -e "\r=> \c"
	cd "$NVM_DIR"; and git pull
else
	# Cloning to $NVM_DIR
	mkdir -p "$NVM_DIR"
	git clone "$NVM_SOURCE" "$NVM_DIR"
end

echo

set -l PROFILE
if test (count $argv) -gt 0; and not test -z "$argv[1]"
	set PROFILE "$argv[1]"
else
	if test -f "$HOME/.config/fish/config.fish"
		set PROFILE "$HOME/.config/fish/config.fish"
	end
end

set SOURCE_STR "test -s \$NVM_DIR/nvm.fish; and source \$NVM_DIR/nvm.fish"

if test -z "$PROFILE"; or not test -f "$PROFILE"
	if test -z "$PROFILE"
		echo "=> Config not found. Tried ~/.config/fish/config.fish"
		echo "=> Create it and run this script again"
	else
		echo "=> Config $PROFILE not found"
		echo "=> Create it and run this script again"
	end
	echo "=> Run this script again after running the following:"
	echo
	echo "	 touch $HOME/.config/fish/config.fish"
	echo
	echo "   OR"
	echo
	echo "=> Append the following line to the correct file yourself"
	echo
	echo "	$SOURCE_STR"
	echo
	echo "=> Close and reopen your terminal afterwards to start using NVM"
	exit
else
	if not grep -qc 'nvm.fish' "$PROFILE"
		echo "=> Appending source string to $PROFILE"
		echo "" >> "$PROFILE"
		echo $SOURCE_STR >> "$PROFILE"
	else
		echo "=> Source string already in $PROFILE"
	end
end

echo "=> Close and reopen your terminal to start using NVM"