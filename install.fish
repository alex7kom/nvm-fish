#!/bin/fish

function has
    type $argv[1] > /dev/null 2>&1
    return $status
end

set NVM_DIR "$HOME/.nvm-fish"

if not has git
	echo >&2 "You need to install git - visit http://git-scm.com/downloads"
	exit 1
end

if test -d "$NVM_DIR"
	echo "=> NVM is already installed in $NVM_DIR, trying to update"
	echo -ne "\r=> "
	cd $NVM_DIR; and git pull
else
	# Cloning to $NVM_DIR
	git clone https://github.com/Alex7Kom/nvm-fish.git $NVM_DIR
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

set SOURCE_STR "test -s \$HOME/.nvm-fish/nvm.fish; and source \$HOME/.nvm-fish/nvm.fish"

if test -z "$PROFILE"; or not test -f "$PROFILE"
	if test -z "$PROFILE"
		echo "=> Config not found. Tried $HOME/.config/fish/config.fish"
	else
		echo "=> Config $PROFILE not found"
	end
	echo "=> Run this script again after running the following:"
	echo
	echo "	touch $HOME/.config/fish/config.fish"
	echo
	echo "-- OR --"
	echo
	echo "=> Append the following line to the correct file yourself"
	echo
	echo "	$SOURCE_STR"
	echo
	echo "=> Close and reopen your terminal afterwards to start using NVM"
	exit
end

if not grep -qc 'nvm.fish' "$PROFILE"
	echo "=> Appending source string to $PROFILE"
	echo "" >> "$PROFILE"
	echo $SOURCE_STR >> "$PROFILE"
else
	echo "=> Source string already in $PROFILE"
end

echo "=> Close and reopen your terminal to start using NVM"