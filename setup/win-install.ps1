Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Set-ExecutionPolicy unrestricted

choco install -y git
choco install -y vim
choco install -y dotnetcoresdk
choco install -y dotnet
choco install -y brave
choco install -y discord
choco install -y betterdiscord
choco install -y element-desktop
choco install -y vscode
choco install -y rainmeter
choco install -y steam
choco install -y amd-ryzen-chipset
choco install -y speccy
choco install -y notepadplusplus.install
choco install -y winrar
choco install -y vlc
choco install -y docker-desktop
choco install -y powershell-core
choco install -y icue
choco install -y lens
choco install -y openvpn-connect
choco install -y cura-new
choco install -y razer-synapse-3
choco install -y powertoys
choco install -y nextcloud-client
choco install -y ds4windows
choco install -y cheatengine
choco install -y postman
choco install -y vortex

echo "Install apps from the windows store, look at your library and re-install what's needed."

echo "Install WSL and Ubuntu"

echo "Install the following due to lack of choco support"

echo "https://1password.com/downloads/windows/"

echo "AVerMedia GC573 Live Gamer 4K: https://www.avermedia.com/support/download"

echo "https://winaerotweaker.com/"

echo "Audio Driver: https://www.msi.com/Motherboard/MPG-X570-GAMING-EDGE-WIFI/support"

echo "https://nzxt.com/software/cam"

echo "https://www.pgadmin.org/download/pgadmin-4-windows/"

echo "https://flipperzero.one/update"

echo "https://www.oculus.com/Setup/"

echo "https://download.battle.net/en-us/?product=bnetdesk"

echo "https://github.com/HunterPie/HunterPie"

echo "https://townshiptale.com/download"

echo "https://account.elderscrollsonline.com/en-us/users/account"

echo "https://freetrial.finalfantasyxiv.com/na/download"

echo "https://airspy.com/download/"

echo "https://github.com/Ryochan7/FakerInput/releases"


echo "If getting wallpaper engine crashes, install mpeg-2 from store?"
echo "https://apps.microsoft.com/store/detail/mpeg2-video-extension/9N95Q1ZZPMH4?hl=en-us&gl=us&rtc=1"

echo "https://github.com/powerline/fonts"
echo "cd ~; git clone https://github.com/powerline/fonts.git --depth=1; cd fonts; ./install.ps1; cd ~; rm -R -Force .\fonts\"
