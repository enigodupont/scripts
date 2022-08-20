#!/bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
brew install --cask iterm2
brew install visual-studio-code
brew install brave-browser
brew install --cask docker
brew install python3
brew install --cask burp-suite
brew install --cask ghidra
brew install --cask arduino
brew install binwalk
brew install wget
brew install gobuster
brew install hydra
brew install hashcat
brew install macchanger
brew install spoof-mac
brew install --cask wireshark
brew install aircrack-ng
brew install --cask virtualbox
brew install nmap
brew install irssi
brew install --cask discord
brew install gpg
brew install certutil
brew install libusb
brew install cmake
brew install nmake
brew install --cask ghidra

gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

curl -sSL https://get.rvm.io | bash -s stable --ruby

git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

python3 get-pip.py
