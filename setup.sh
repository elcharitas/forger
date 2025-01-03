# Get sudo
#sudo -v

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Enable brew
(
  echo
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
) >>/Users/mrf/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install packages and casks with brew
echo "Installing programs with homebrew"
brew update
brew upgrade

brew install --cask bitwarden zen-browser discord orbstack raycast shottr zed jetbrains-toolbox

brew install corepack dockutil fnm gh git iperf3

# create LaunchAgents dir
mkdir -p ~/Library/LaunchAgents

# enable automatic updates every 12 hours
echo "Enabling autoupdate for homebrew packages..."
brew tap homebrew/autoupdate
brew autoupdate start 43200 --upgrade # 12 hours

# Set up dock icons
echo "Setting up dock"
dockutil --remove all --no-restart
dockutil --add "/Applications/Zen Browser.app" --no-restart
dockutil --add "/Applications/Zed.app" --no-restart
dockutil --add "/System/Applications/Utilities/Terminal.app" --no-restart
dockutil --add "/Applications/Discord.app" --no-restart
dockutil --add "/Applications/Bitwarden.app" --no-restart

# Folders to add to the dock
dockutil --add '~/Workspace' --view list --display folder --no-restart

# xcode command line tools
xcode-select --install

# git config
echo "Setting up git"

git config --global user.name "Jonathan Irhodia"
git config --global user.email "jonathanirhodia@gmail.com"
git config --global core.editor "zed --wait"
git config --global push.default upstream

# login to services
echo "Logging into services"
gh auth login

echo "Logging into Bitwarden"
bw login jonathanirhodia@gmail.com

if [ $? -eq 0 ]; then
  echo "Successfully logged into Bitwarden"
  while true; do
    read -p "Do you want to add another Bitwarden account? (y/n) " yn
    case $yn in
      [Yy]* )
        read -p "Enter email: " email
        read -sp "Enter password: " password
        echo
        read -p "Enter server URL (optional): " server_url
        if [ -z "$server_url" ]; then
          bw login $email --password $password
        else
          bw login $email --password $password --server $server_url
        fi
        ;;
      [Nn]* ) break ;;
      * ) echo "Please answer yes or no." ;;
    esac
  done
else
  echo "Failed to log into Bitwarden"
fi

# Ensure we're on the first Bitwarden account, switch to it if not
bw config current > /dev/null
if [ $? -ne 0 ]; then
  bw config set current
fi

# git aliases
git config --global alias.undo "reset --soft HEAD^"
git config --global alias.st "status"
git config --global alias.sac '!git add -A && git commit -m'

# set up ssh keys
echo "Setting up SSH keys"
mkdir -p ~/.ssh
bw get notes "SSH Keys/Github SSH Key" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_ed25519

# Set up dock hiding
printf "\nsetting up dock hiding."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
killall Dock

echo "Updating macOS settings"

# Avoid the creation of .DS_Store files on network volumes or USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Enable three-finger drag
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool false
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# Dock tweaks
defaults write com.apple.dock orientation -string left # Move dock to left side of screen
defaults write com.apple.dock show-recents -bool FALSE # Disable "Show recent applications in dock"
defaults write com.apple.Dock showhidden -bool TRUE    # Show hidden applications as translucent
killall Dock

# Finder tweaks
defaults write NSGlobalDomain AppleShowAllExtensions -bool true            # Show all filename extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Disable warning when changing a file extension
defaults write com.apple.finder FXPreferredViewStyle Clmv                  # Use column view
defaults write com.apple.finder ShowPathbar -bool true                     # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true                   # Show status bar
killall Finder

# Disable "the disk was not ejected properly" messages
defaults write /Library/Preferences/SystemConfiguration/com.apple.DiskArbitration.diskarbitrationd.plist DADisableEjectNotification -bool YES
killall diskarbitrationd


echo "Starting services"
open "/Applications/Shottr.app"

echo "Removing config programs"
brew remove dockutil

# oh-my-zsh (must be last)
sh -c "$(curl -# -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# install zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# add ssh-agent plugin
sed -i -e 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' ~/.zshrc

# change preferred editor
sed -i -e 's/# export EDITOR="nano"/export EDITOR="zed --wait"/' ~/.zshrc

# finish
source ~/.zshrc
