#!/usr/bin/env bash
#
# backup-secrets.sh -- bundle SSH keys, AWS / Kube / GPG / cloud creds and
# other things that aren't tracked in any git repo into a single directory
# you can drop on an external drive before wiping your Mac.
#
# Usage:
#   ./backup-secrets.sh                       # writes to ~/Desktop/laptop-secrets-<ts>
#   ./backup-secrets.sh /Volumes/Backup       # writes a timestamped dir under there
#   ./backup-secrets.sh /Volumes/Backup/foo   # writes directly to that path
#
# This is read-only; it never modifies the source files.

# Deliberately NOT using `set -e` -- we want every backup section to attempt
# independently and report partial failures, rather than abort the whole run
# if (e.g.) gpg can't reach its agent for the armored export.
set -uo pipefail

# ----------------------------------------------------------------------------
# Pick destination
# ----------------------------------------------------------------------------

TS="$(date +%Y%m%d-%H%M%S)"
DEFAULT_DEST="${HOME}/Desktop/laptop-secrets-${TS}"

if [[ $# -eq 0 ]]; then
  DEST="$DEFAULT_DEST"
elif [[ -d "$1" ]]; then
  DEST="$1/laptop-secrets-${TS}"
else
  DEST="$1"
fi

mkdir -p "$DEST"

# ----------------------------------------------------------------------------
# Pretty printing
# ----------------------------------------------------------------------------

if [[ -t 1 ]]; then
  C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[0;32m'; C_DIM=$'\033[2m'
  C_YELLOW=$'\033[1;33m'; C_RED=$'\033[0;31m'; C_RESET=$'\033[0m'
else
  C_BLUE=""; C_GREEN=""; C_DIM=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

ohai()  { printf "%s==>%s %s\n" "$C_BLUE" "$C_RESET" "$*"; }
ok()    { printf "  %s✓%s %s\n"  "$C_GREEN" "$C_RESET" "$*"; }
skip()  { printf "  %s-%s %s%s%s\n" "$C_DIM" "$C_RESET" "$C_DIM" "$*" "$C_RESET"; }
warn()  { printf "  %s!%s %s\n"  "$C_YELLOW" "$C_RESET" "$*"; }

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

# copy_if SRC LABEL [DEST_NAME]
# Copies a file/dir if it exists. DEST_NAME defaults to basename of SRC.
# Uses rsync so sockets / devices / broken symlinks don't abort the copy.
copy_if() {
  local src="$1" label="$2" dest_name="${3:-$(basename "$1")}"
  if [[ ! -e "$src" ]]; then
    skip "${label}  (not present)"
    return 0
  fi

  local target="${DEST}/${dest_name}"
  local rc=0
  if [[ -d "$src" ]]; then
    mkdir -p "$target"
    # Trailing slash on source = copy contents into target.
    # Excludes cover gpg-agent sockets, ssh agent sockets, and Linux-style .sock files.
    rsync -a --safe-links \
      --exclude='S.gpg-agent*' --exclude='S.scdaemon' \
      --exclude='agent/'       --exclude='*.sock' \
      "$src/" "$target/" 2>/dev/null || rc=$?
  else
    cp -p "$src" "$target" 2>/dev/null || rc=$?
  fi

  local size; size="$(du -sh "$target" 2>/dev/null | awk '{print $1}')"
  if [[ $rc -eq 0 ]]; then
    ok "${label}  (${size})"
  else
    warn "${label}  (rsync rc=$rc; copy may be partial -- ${size})"
  fi
}

# ----------------------------------------------------------------------------
# Run
# ----------------------------------------------------------------------------

ohai "Backing up secrets to ${C_BLUE}${DEST}${C_RESET}"
echo

ohai "SSH"
copy_if "${HOME}/.ssh"        "~/.ssh"

echo
ohai "AWS"
copy_if "${HOME}/.aws"        "~/.aws"
copy_if "${HOME}/.aws-vault"  "~/.aws-vault"

echo
ohai "Kubernetes"
copy_if "${HOME}/.kube"       "~/.kube"

echo
ohai "Git"
copy_if "${HOME}/.localsecrets" "~/.localsecrets"
copy_if "${HOME}/.gitcookies"   "~/.gitcookies"

echo
ohai "Cloud SDKs"
copy_if "${HOME}/.config/gcloud" "gcloud config"  "gcloud"
copy_if "${HOME}/.azure"         "~/.azure"

echo
ohai "Other dev tools (auth tokens / credentials)"
copy_if "${HOME}/.docker/config.json"            "~/.docker/config.json (auths)"  "docker-config.json"
copy_if "${HOME}/.docker/contexts"               "~/.docker/contexts"             "docker-contexts"
copy_if "${HOME}/.npmrc"                         "~/.npmrc"
copy_if "${HOME}/.yarnrc"                        "~/.yarnrc"
copy_if "${HOME}/.terraformrc"                   "~/.terraformrc"
copy_if "${HOME}/.terraform.d/credentials.tfrc.json" "~/.terraform.d/credentials.tfrc.json" "terraform-credentials.tfrc.json"
copy_if "${HOME}/.netrc"                         "~/.netrc"
copy_if "${HOME}/.config/gh/hosts.yml"           "GitHub CLI hosts.yml"  "gh-hosts.yml"
copy_if "${HOME}/.saml2aws"                      "~/.saml2aws"

# ----------------------------------------------------------------------------
# Manifest
# ----------------------------------------------------------------------------

echo
ohai "Generating manifest + restore script"

cat > "${DEST}/MANIFEST.txt" <<EOF
laptop-secrets backup
=====================
Created : $(date)
Hostname: $(hostname)
User    : $(whoami)
macOS   : $(sw_vers -productVersion)
Arch    : $(uname -m)

Contents:
EOF
( cd "${DEST}" && find . -type f -not -name MANIFEST.txt -not -name restore.sh \
    -exec stat -f "  %z bytes  %N" {} \; | sort >> "${DEST}/MANIFEST.txt" )

# ----------------------------------------------------------------------------
# Restore script written into the bundle
# ----------------------------------------------------------------------------

cat > "${DEST}/restore.sh" <<'RESTORE'
#!/usr/bin/env bash
#
# restore.sh -- restore the contents of this backup onto a fresh Mac.
#
# Run from inside the backup directory:
#   cd /Volumes/Backup/laptop-secrets-YYYYMMDD-HHMMSS
#   ./restore.sh

set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "Restoring secrets from: $HERE"

restore_if() {
  local src="$1" dest="$2"
  if [[ -e "$src" ]]; then
    if [[ -e "$dest" ]]; then
      echo "  ! $dest already exists; skipping (move it aside if you want to restore)"
      return
    fi
    cp -R "$src" "$dest"
    echo "  ✓ $dest"
  fi
}

# Files / dirs that go straight back into $HOME
restore_if "$HERE/.ssh"          "$HOME/.ssh"
restore_if "$HERE/.aws"          "$HOME/.aws"
restore_if "$HERE/.aws-vault"    "$HOME/.aws-vault"
restore_if "$HERE/.kube"         "$HOME/.kube"
restore_if "$HERE/.localsecrets" "$HOME/.localsecrets"
restore_if "$HERE/.gitcookies"   "$HOME/.gitcookies"
restore_if "$HERE/.azure"        "$HOME/.azure"
restore_if "$HERE/.npmrc"        "$HOME/.npmrc"
restore_if "$HERE/.yarnrc"       "$HOME/.yarnrc"
restore_if "$HERE/.terraformrc"  "$HOME/.terraformrc"
restore_if "$HERE/.netrc"        "$HOME/.netrc"
restore_if "$HERE/.saml2aws"     "$HOME/.saml2aws"

# Files that need to land in non-default paths
mkdir -p "$HOME/.docker" "$HOME/.config/gcloud" "$HOME/.config/gh" "$HOME/.terraform.d"
restore_if "$HERE/docker-config.json"             "$HOME/.docker/config.json"
restore_if "$HERE/docker-contexts"                "$HOME/.docker/contexts"
restore_if "$HERE/gcloud"                         "$HOME/.config/gcloud"
restore_if "$HERE/gh-hosts.yml"                   "$HOME/.config/gh/hosts.yml"
restore_if "$HERE/terraform-credentials.tfrc.json" "$HOME/.terraform.d/credentials.tfrc.json"

# Lock down permissions
[[ -d "$HOME/.ssh"  ]] && chmod 700 "$HOME/.ssh"  && chmod -R go-rwx "$HOME/.ssh"
[[ -d "$HOME/.aws"  ]] && chmod -R go-rwx "$HOME/.aws"
[[ -d "$HOME/.kube" ]] && chmod -R go-rwx "$HOME/.kube"

echo ""
echo "Done. Verify with:"
echo "  ssh-add -l                                 # SSH keys loaded"
echo "  aws sts get-caller-identity                # AWS profile works"
echo "  kubectl config get-contexts                # k8s contexts present"
RESTORE

chmod +x "${DEST}/restore.sh"
ok "MANIFEST.txt and restore.sh"

# ----------------------------------------------------------------------------
# Lock down permissions on the bundle
# ----------------------------------------------------------------------------

chmod 700 "${DEST}"
find "${DEST}" -type d -exec chmod 700 {} \;
find "${DEST}" -type f -exec chmod 600 {} \;
chmod +x "${DEST}/restore.sh"

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

echo
ohai "Done"
echo "  Bundle:  ${C_BLUE}${DEST}${C_RESET}"
echo "  Size:    $(du -sh "${DEST}" | awk '{print $1}')"
echo "  Files:   $(find "${DEST}" -type f | wc -l | tr -d ' ')"
echo
warn "This bundle contains UNENCRYPTED private keys and credentials."
warn "Move it to your offline backup drive ASAP and don't sync it to cloud storage."
echo
echo "Optional: encrypt as a single file before moving:"
echo "  ${C_DIM}tar -czf - -C \"$(dirname "$DEST")\" \"$(basename "$DEST")\" | gpg -c > \"${DEST}.tar.gz.gpg\"${C_RESET}"
echo "  ${C_DIM}rm -rf \"$DEST\"${C_RESET}"
echo
echo "To restore on the new Mac:"
echo "  ${C_DIM}cd ${DEST}${C_RESET}"
echo "  ${C_DIM}./restore.sh${C_RESET}"
