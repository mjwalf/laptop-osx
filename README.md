# laptop-osx

Bootstrap and maintain a developer macOS install — Homebrew packages, dotfiles,
and macOS System Settings — driven by an Ansible playbook.

Tested on:

- macOS 14 Sonoma → 26 (Apple Silicon and Intel)
- Ansible ≥ 2.16 (`community.general` ≥ 9)

## Bootstrapping a new Mac

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mjwalf/laptop-osx/master/bootstrap.sh)"
```

The script will:

1. Install Xcode Command Line Tools (an Apple installer pops up the first time).
2. Install Homebrew (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel).
3. Install Ansible via Homebrew.
4. Clone this repo to `~/Developer/config/src/github.com/mjwalf/laptop-osx`.
5. Install required Ansible collections.
6. Run the playbook (you'll be prompted for your sudo password once).

To bootstrap from a branch other than `master`:

```bash
LAPTOP_OSX_BRANCH=my-branch /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mjwalf/laptop-osx/my-branch/bootstrap.sh)"
```

## Day-to-day usage

Add this function to your dotfiles (e.g. `~/.dotfiles/zsh/zshrc`):

```bash
function laptop-osx() {
  local repo="${HOME}/Developer/config/src/github.com/mjwalf/laptop-osx"
  if [[ -z "$1" ]]; then
    ansible-playbook \
      "${repo}/ansible/playbook.yml" \
      -i "${repo}/ansible/hosts" \
      -e "install_user=${USER}" \
      -K
  else
    ansible-playbook \
      "${repo}/ansible/playbook.yml" \
      -i "${repo}/ansible/hosts" \
      -e "install_user=${USER}" \
      -K \
      --tags "$1"
  fi
}
```

Then:

| Command                     | What it does                                              |
| --------------------------- | --------------------------------------------------------- |
| `laptop-osx`                | Run the entire playbook.                                  |
| `laptop-osx homebrew`       | Install/sync brew formulae and casks.                     |
| `laptop-osx update`         | `brew update` only.                                       |
| `laptop-osx upgrade`        | Upgrade all installed brew packages.                      |
| `laptop-osx casks`          | Re-run only the cask install task.                        |
| `laptop-osx dotfiles`       | Re-clone/relink dotfiles + oh-my-zsh.                     |
| `laptop-osx macos`          | Apply all enabled macOS System Settings.                  |
| `laptop-osx finder`         | Apply only Finder settings (any sub-tag from `macos`).    |

## Adding or removing packages

Edit `ansible/roles/homebrew/defaults/main.yml`:

```yaml
homebrew:
  taps:
    - aws/tap
  formulae:
    - git
    - jq
    - ...
  casks:
    - 1password
    - firefox
    - ...
```

Then run `laptop-osx homebrew`.

## macOS System Settings

Defaults live in `ansible/vars/macos.yml`. Each section has an `_Enabled`
flag — flip to `true` to apply. Tasks live under
`ansible/roles/macos/tasks/` (one file per System Settings pane).

Notes / caveats on modern macOS:

- Dashboard, Bluetooth menuExtras, iCloud document defaults, and the legacy
  desktop-picture sqlite poke have been removed — Apple killed those features
  or moved them into Control Center / TCC-protected stores.
- Many Safari preferences are SIP-protected and silently ignored even if
  `defaults` accepts the write. The Safari section is therefore disabled by
  default; flip `Safari_Enabled: true` only if you've granted Full Disk Access
  to your terminal (and accept that some of it won't take effect).

## Repository layout

```
.
├── bootstrap.sh                 # Entry-point for new Macs
├── ansible/
│   ├── playbook.yml             # Top-level play
│   ├── hosts                    # Inventory (just `localhost`)
│   ├── requirements.yml         # Ansible collections
│   ├── vars/macos.yml           # Toggles + values for the macos role
│   └── roles/
│       ├── homebrew/            # Taps + formulae + casks
│       ├── dotfiles/            # mjwalf/dotfiles + oh-my-zsh
│       └── macos/               # System Settings tweaks
```

## Credits

- [mjwalf](https://twitter.com/mjwalf)
- [sthulb](https://twitter.com/sthulb) — original concept
- [lafarer](https://github.com/lafarer/ansible-role-osx-defaults) — macOS defaults role
