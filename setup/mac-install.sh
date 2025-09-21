#!/bin/zsh

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

PATH="$PATH:/opt/homebrew/bin"
eval "$(/opt/homebrew/bin/brew shellenv)"

sudo xcodebuild -license accept

mkdir -p ~/.ssh ~/.kube

brew install brave-browser
brew install --cask 1password
brew install --cask iterm2
brew install --cask nextcloud
brew install --cask docker
brew install --cask discord
brew install --cask spotify
brew install --cask vlc
brew install --cask rectangle
brew install --cask steam 
brew install --cask obsidian
brew install lens
brew install visual-studio-code
brew install python3
brew install binwalk
brew install wget
brew install gpg
brew install certutil
brew install libusb
brew install cmake
brew install nmake
brew install rar
brew install utm
brew install cabextract
brew install jq
brew install yq

# These require password auth, post install
brew install --cask openvpn-connect
#brew install --cask tunnelblick
brew install --cask wireshark

curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -

curl -sSL https://get.rvm.io | bash -s stable --ruby

git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py

python3 get-pip.py

rm get-pip.py

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Install Downlink, Microsoft To-Do and Amphetamine from the App Store"

#Commented items are for sec testing
# Consider controlling these installs from a flag
#brew install --cask burp-suite
#brew install --cask ghidra
#brew install --cask arduino
#brew install --cask virtualbox
#brew install --cask ghidra
#brew install gobuster
#brew install hydra
#brew install hashcat
#brew install spoof-mac
#brew install aircrack-ng
#brew install nmap
#brew install irssi
#brew install macchanger
