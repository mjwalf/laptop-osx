#!/usr/bin/env bash
#
# Bootstrap a fresh macOS install for development work.
#
# Run with:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mjwalf/laptop-osx/master/bootstrap.sh)"
#
# Steps:
#   1. Install Xcode Command Line Tools (interactive on first run).
#   2. Install Homebrew (Apple Silicon -> /opt/homebrew, Intel -> /usr/local).
#   3. Install Ansible via brew.
#   4. Install required Ansible collections.
#   5. Clone this repo to ~/Developer/config/src/github.com/mjwalf/laptop-osx
#   6. Run the playbook (will prompt for sudo password).

set -euo pipefail

REPO_USER="mjwalf"
REPO_NAME="laptop-osx"
REPO_BRANCH="${LAPTOP_OSX_BRANCH:-master}"
INSTALL_DIR="${HOME}/Developer/config/src/github.com/${REPO_USER}/${REPO_NAME}"

# ----- pretty printing -----
if [[ -t 1 ]]; then
  C_BLUE=$'\033[1;34m'
  C_RED=$'\033[4;31m'
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
else
  C_BLUE=""
  C_RED=""
  C_RESET=""
  C_BOLD=""
fi

ohai()  { printf "%s==>%s %s%s%s\n" "${C_BLUE}" "${C_RESET}" "${C_BOLD}" "$*" "${C_RESET}"; }
warn()  { printf "%sWarning%s: %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; }
abort() { printf "%sError%s: %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; exit 1; }

# ----- preflight -----
[[ "$(uname)" == "Darwin" ]] || abort "This script only runs on macOS."

ohai "macOS $(sw_vers -productVersion) on $(uname -m)"

# Cache sudo credentials up front and keep them alive in the background while
# the script runs. Killed on exit via the trap below.
ohai "Requesting sudo (will only be used by the playbook)"
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true; sudo -k' EXIT

# ----- 1. Xcode Command Line Tools -----
if ! xcode-select -p >/dev/null 2>&1; then
  ohai "Installing Xcode Command Line Tools"
  xcode-select --install
  echo "A graphical installer for the Xcode Command Line Tools was launched."
  read -r -p "Press RETURN once it has finished installing... " _
  xcode-select -p >/dev/null 2>&1 || abort "Xcode Command Line Tools still not installed."
else
  ohai "Xcode Command Line Tools already installed"
fi

# ----- 2. Homebrew -----
if ! command -v brew >/dev/null 2>&1; then
  ohai "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available to this shell regardless of arch.
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX="/usr/local"
else
  abort "Homebrew install seems to have failed; brew not on PATH."
fi
eval "$("${BREW_PREFIX}/bin/brew" shellenv)"

ohai "Using Homebrew at ${BREW_PREFIX}"

# ----- 3. Ansible -----
if ! command -v ansible-playbook >/dev/null 2>&1; then
  ohai "Installing Ansible via Homebrew"
  brew install ansible
else
  ohai "Ansible already installed: $(ansible --version | head -1)"
fi

# ----- 4. Clone repo -----
mkdir -p "$(dirname "${INSTALL_DIR}")"
if [[ ! -d "${INSTALL_DIR}/.git" ]]; then
  ohai "Cloning ${REPO_USER}/${REPO_NAME} (${REPO_BRANCH}) to ${INSTALL_DIR}"
  git clone --branch "${REPO_BRANCH}" \
    "https://github.com/${REPO_USER}/${REPO_NAME}.git" "${INSTALL_DIR}"
else
  ohai "Repo already cloned; pulling latest on ${REPO_BRANCH}"
  git -C "${INSTALL_DIR}" fetch origin "${REPO_BRANCH}"
  git -C "${INSTALL_DIR}" checkout "${REPO_BRANCH}"
  git -C "${INSTALL_DIR}" pull --ff-only origin "${REPO_BRANCH}"
fi

# ----- 5. Ansible collections -----
ohai "Installing Ansible collections"
ansible-galaxy collection install -r "${INSTALL_DIR}/ansible/requirements.yml"

# ----- 6. Run playbook -----
ohai "Running playbook (you'll be prompted for the BECOME password)"
ansible-playbook \
  "${INSTALL_DIR}/ansible/playbook.yml" \
  -i "${INSTALL_DIR}/ansible/hosts" \
  -e "install_user=${USER}" \
  -K

ohai "Done. Restart your terminal (or run 'exec \$SHELL') to pick up new tools."
