# My Blog.

## Install Homebrew

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
    test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
    echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile

## Install Hugo

    brew install hugo

## Clone repository

    git clone --recurse-submodules -j8 https://github.com/dodowhat/blog.git

## Fetch Hugo theme Submodules

If you clone this repo without `--recurse-submodules` flag, run

    cd blog
    git submodule update --init --recursive

To update submodules, run

    git submodule update --recursive --remote

or

    git pull --recurse-submodules

## Running

    hugo server -b localhost
