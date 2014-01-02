# Node Version Manager for fish

## Important Note

nvm-fish is a port of [nvm](https://github.com/creationix/nvm) for fish shell.
Although it is fully functional, it should be considered very beta, so you use it on your own risk!
Please report any bugs you encounter.

## Installation

First you'll need to make sure your system has a c++ compiler.  For OSX, XCode will work, for Ubuntu, the build-essential and libssl-dev packages work.

### Install script

To install you could use the [install script](https://github.com/Alex7Kom/nvm-fish/blob/master/install.fish) (requires Git) using cURL:

    curl https://raw.github.com/Alex7Kom/nvm-fish/master/install.fish | fish

or Wget:

    wget -qO- https://raw.github.com/Alex7Kom/nvm-fish/master/install.fish | fish

<sub>The script clones the nvm repository to `~/.nvm-fish` and adds the source line to your config (`~/.config/fish/config.fish`).</sub>


### Manual install

For manual install create a folder somewhere in your filesystem with the `nvm.fish` file inside it.  I put mine in a folder called `nvm-fish`.

Or if you have `git` installed, then just clone it:

    git clone https://github.com/Alex7Kom/nvm-fish.git ~/.nvm-fish

To activate nvm, you need to source it from your shell:

    source ~/.nvm-fish/nvm.fish

I always add this line to my `~/.config/fish/config.fish` file to have it automatically sourced upon login.
Often I also put in a line to use a specific version of node.

## Usage

To download, compile, and install the latest v0.10.x release of node, do this:

    nvm install 0.10

And then in any new shell just use the installed version:

    nvm use 0.10

You can create an `.nvmrc` file containing version number in the project root folder; run the following command to switch versions:

    nvm use

Or you can just run it:

    nvm run 0.10

If you want to see what versions are installed:

    nvm ls

If you want to see what versions are available to install:

    nvm ls-remote

To restore your PATH, you can deactivate it.

    nvm deactivate

To set a default Node version to be used in any new shell, use the alias 'default':

    nvm alias default 0.10

## License

nvm-fish is released under the MIT license.


Copyright (C) 2010-2014 Tim Caswell, Alexey Komarov

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Problems

If you try to install a node version and the installation fails, be sure to delete the node downloads from src (~/.nvm-fish/src/) or you might get an error when trying to reinstall them again or you might get an error like the following:

    curl: (33) HTTP server doesn't seem to support byte ranges. Cannot resume.

Where's my 'sudo node'? Checkout this link:

https://github.com/creationix/nvm/issues/43

on Arch Linux and other systems using python3 by default, before running *install* you need to

    set PYTHON python2

After the v0.8.6 release of node, nvm tries to install from binary packages. But in some systems, the official binary packages don't work due to incompatibility of shared libs. In such cases, use `-s` option to force install from source:

    nvm install -s 0.8.6

