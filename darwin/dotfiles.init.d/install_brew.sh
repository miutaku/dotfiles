echo 'Run `brew bundle --global`'

BREW_PATH="$(which brew || echo '')"
if [[ -z "${BREW_PATH}" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

softwareupdate --install-rosetta --agree-to-license
brew bundle cleanup
brew bundle --global

echo >> /Users/${whoami}/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/${whoami}/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
