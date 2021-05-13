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

    git clone https://github.com/dodowhat/blog.git

    git clone https://github.com/qqhann/hugo-primer.git themes/hugo-primer

## Running

    hugo server -b localhost
