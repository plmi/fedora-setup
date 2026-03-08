# OSCP Lab (Ansible)

Reproducible pentest workstation setup for **Fedora 43** and **Kali Linux**.
No click-ops. No mystery state. Just `make apply`.

## Supported Hosts

| Host | OS | VM Platform | User | Desktop |
|---|---|---|---|---|
| `fedora43` | Fedora 43 | UTM | `michael` | Hyprland (Wayland) |
| `kali` | Kali Linux Rolling | Parallels Desktop | `parallels` | Hyprland (Wayland) |
| `kali-i3` | Kali Linux Rolling | Parallels Desktop | `michael` | i3 (X11) |

## What You Get

**All hosts:**
- `zsh` + `tmux` + `neovim` + `eza` + `pyenv`
- OSCP-oriented tooling with Kali-like paths where it matters
- Dotfiles from `https://github.com/plmi/dotfiles`
- Brave Browser, Obsidian via Flatpak

**Hyprland hosts (`fedora43`, `kali`):**
- Minimal Hyprland desktop tuned for operator workflow
- `foot` terminal, `wofi` launcher, `waybar` with VPN/target/public-IP visibility
- Screenshot + annotation flow (`grim` + `slurp` + `swappy`)

**i3 host (`kali-i3`):**
- i3 window manager (X11) with `i3blocks` status bar
- `alacritty` terminal, `rofi` launcher, `picom` compositor
- `feh` wallpaper, `dunst` notifications, `i3lock` screen lock

## Fast Start

```bash
make deps
make doctor
make apply          # all hosts
make fedora         # fedora43 only
make kali           # kali (Hyprland) only
make kali-i3        # kali-i3 (i3) only
make validate
```

## Install Ansible (Control Machine)

### macOS
```bash
brew install ansible
ansible --version
```

### Linux
Fedora:
```bash
sudo dnf install -y ansible-core
```

Debian/Kali:
```bash
sudo apt update && sudo apt install -y ansible
```

## Required VM Prep

Confirm SSH and set up key auth for each host:

```bash
ssh-copy-id michael@192.168.64.6    # fedora43
ssh-copy-id parallels@10.211.55.28  # kali
ssh-copy-id michael@10.211.55.30    # kali-i3
```

Password auth fallback:
```bash
make doctor EXTRA_ARGS='--ask-pass --ask-become-pass'
make apply  EXTRA_ARGS='--ask-pass --ask-become-pass'
```

## Inventory

```
inventories/lab/
├── hosts.yml               # host IPs and users
├── group_vars/
│   ├── all.yml             # shared defaults (timezone, primary_user, etc.)
│   ├── workstation.yml     # dotfiles repo URL, Obsidian toggle
│   ├── hyprland.yml        # Hyprland/COPR vars, monitor scale
│   ├── pentest.yml         # pentest tool flags and URLs
│   └── vpn_clients.yml     # VPN group (NM integration)
└── host_vars/
    ├── fedora43.yml        # Fedora-specific overrides
    ├── kali.yml            # Kali Hyprland overrides (skips pre-installed tools, scale=1)
    └── kali-i3.yml         # Kali i3 overrides (skips pre-installed tools)
```

## Playbooks

| Playbook | What it runs |
|---|---|
| `playbooks/site.yml` | Full setup (workstation + pentest) |
| `playbooks/workstation.yml` | Base OS + user + shell + desktop (Hyprland or i3) + dotfiles |
| `playbooks/pentest.yml` | Pentest tools + VPN |
| `playbooks/validate.yml` | Post-install checks |

## Make Targets

| Target | Description |
|---|---|
| `make deps` | Install Ansible collections from `requirements.yml` |
| `make doctor` | Preflight checks (tools, inventory, SSH, target facts) |
| `make apply` | Run full setup on all hosts |
| `make workstation` | Run workstation stack only |
| `make pentest` | Run pentest stack only |
| `make validate` | Run validation checks (all hosts) |
| `make fedora` | Run `site.yml` limited to `fedora43` |
| `make kali` | Run `site.yml` limited to `kali` |
| `make kali-i3` | Run `site.yml` limited to `kali-i3` |
| `make validate-kali` | Run `validate.yml` limited to `kali` |

## Tool Matrix

| Category | Tool | Source | Method |
|---|---|---|---|
| Desktop | hyprland | COPR `solopasha/hyprland` | dnf |
| Desktop | i3 | OS repos | apt |
| Desktop | i3blocks | OS repos | apt |
| Desktop | i3lock | OS repos | apt |
| Desktop | rofi | OS repos | apt |
| Desktop | alacritty | OS repos | apt |
| Desktop | picom | OS repos | apt |
| Desktop | feh | OS repos | apt |
| Desktop | dunst | OS repos | apt |
| Desktop | arandr | OS repos | apt |
| Desktop | autorandr | OS repos | apt |
| Desktop | brave-browser | Brave RPM/APT repo | dnf / apt |
| Desktop | obsidian | Flathub | flatpak |
| Shell | zsh | OS repos | dnf / apt |
| Shell | foot | OS repos | dnf / apt |
| Shell | tmux | OS repos | dnf / apt |
| Shell | neovim | OS repos | dnf / apt |
| Shell | eza | GitHub `eza-community/eza` latest | binary tarball |
| Shell | fzf | OS repos | dnf / apt |
| Shell | bat | OS repos | dnf / apt |
| Shell | btop | OS repos | dnf / apt |
| Shell | zoxide | OS repos | dnf / apt |
| Shell | fastfetch | OS repos | dnf / apt |
| Shell | pyenv | GitHub `pyenv/pyenv` | git clone → `~/.pyenv` |
| Shell | pyenv-virtualenv | GitHub `pyenv/pyenv-virtualenv` | git clone → `~/.pyenv/plugins/` |
| Pentest | nmap | OS repos | dnf / apt |
| Pentest | netcat | OS repos | dnf / apt |
| Pentest | socat | OS repos | dnf / apt |
| Pentest | tcpdump | OS repos | dnf / apt |
| Pentest | wireshark | OS repos | dnf / apt |
| Pentest | ffuf | OS repos | dnf / apt |
| Pentest | gobuster | OS repos | dnf / apt |
| Pentest | hydra | OS repos | dnf / apt |
| Pentest | john | OS repos | dnf / apt |
| Pentest | hashcat | OS repos | dnf / apt |
| Pentest | feroxbuster | GitHub `epi052/feroxbuster` latest | binary zip |
| Pentest | nikto | GitHub `sullo/nikto` latest | source zip + wrapper |
| Pentest | sqlmap | GitHub `sqlmapproject/sqlmap` | git clone + wrapper |
| Pentest | impacket | PyPI | pipx |
| Pentest | metasploit | Snap Store / apt | snap (Fedora) / apt (Kali) |
| Pentest | wpscan | RubyGems | gem |
| Pentest | searchsploit | GitLab `exploitdb` | git clone + symlink |
| Wordlists | seclists | GitHub `danielmiessler/SecLists` | zip → `/usr/share/seclists` |
| Wordlists | rockyou.txt | SecLists / fallback URL | copy → `/usr/share/wordlists/rockyou.txt` |
| VPN | openvpn | OS repos | dnf / apt |
| VPN | wireguard-tools | OS repos | dnf / apt |

> Kali hosts (`kali`, `kali-i3`) skip most Pentest entries — Kali pre-installs them. Override via `pentest_install_*: false` in the respective `host_vars/` file.
> i3 Desktop entries apply to `kali-i3` only.

### Dotfiles
- Repo cloned to `~/dotfiles`, profile applied via `make <profile>` (e.g. `fedora-hyprland`, `kali-i3`)
- Hyprland hosts: post-stow patches fix hardcoded paths and adapt config:
  - `/home/<author>/bin/` → `/home/<primary_user>/.local/bin/`
  - `windowrulev2` → `windowrule` (Hyprland 0.41+ syntax)
  - Monitor scale set from `hyprland_monitor_scale` (default `2`, `kali` uses `1`)
  - `spice-vdagent` exec-once commented out on non-SPICE VMs
- i3 host: dotfiles applied as-is, no patches needed

## Without Make

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventories/lab/hosts.yml playbooks/site.yml
ansible-playbook -i inventories/lab/hosts.yml playbooks/site.yml --limit fedora43
ansible-playbook -i inventories/lab/hosts.yml playbooks/site.yml --limit kali
ansible-playbook -i inventories/lab/hosts.yml playbooks/site.yml --limit kali-i3
ansible-playbook -i inventories/lab/hosts.yml playbooks/validate.yml
```

## Notes
- Use only on systems/networks you own or are explicitly authorized to test.
- Store secrets with Ansible Vault.
- Firewall (`firewalld`/`ufw`) is **disabled by default** (`enable_firewalld: false`). Enable per-host in `host_vars/`.
- Dotfiles are the source of truth for user/system config (`~/.config/*`, shell, editor, WM, status bar).
- Ansible installs packages/services and applies dotfiles — it does not template overlapping dotfiles.
- `ansible.cfg` sets `ssh_connection.usetty=False` to avoid OSC 3008 escape-sequence noise.

## Manual Post-Install Steps

These steps cannot be automated and must be performed once per machine after running the playbooks.

### GPG Key

Import your private key and set trust level:

```bash
# On the control machine — export your key to a file
gpg --export-secret-keys --armor > private-key.asc

# Copy to the target host and import
scp private-key.asc user@host:~
ssh user@host
gpg --import ~/private-key.asc
rm ~/private-key.asc
```

Set ultimate trust for the imported key:

```bash
gpg --edit-key <KEY_ID>
# Inside the gpg prompt:
trust
5
y
quit
```

### Password Store

Clone your existing `pass` store:

```bash
git clone <your-pass-store-repo> ~/.password-store
```

Or initialize a new one:

```bash
pass init <GPG_KEY_ID>
```

### Browserpass

Browserpass is fully installed by Ansible (native host + Firefox extension). It works once the GPG key is imported and `~/.password-store` is populated. No additional setup needed.

## VPN Profile Import (nmcli)

Ansible installs `openvpn`, `wireguard-tools`, and the Network Manager plugins, and creates
`~/.config/vpn/openvpn/` and `~/.config/vpn/wireguard/` as drop locations for your profiles.

**Import a profile once** — NM manages it from there:

OpenVPN (`.ovpn`):
```bash
nmcli connection import type openvpn file ~/.config/vpn/openvpn/lab.ovpn
```

WireGuard (`.conf`):
```bash
nmcli connection import type wireguard file ~/.config/vpn/wireguard/lab.conf
```

**Connect / disconnect:**
```bash
nmcli connection up id "<profile-name>"
nmcli connection down id "<profile-name>"
```

**List VPN profiles:**
```bash
nmcli -t -f NAME,TYPE connection show | grep -E ':(vpn|wireguard)$'
```

**Typical OSCP workflow:**
1. Download your `.ovpn` from the HTB/OSCP portal
2. Drop it in `~/.config/vpn/openvpn/`
3. Import once: `nmcli connection import type openvpn file ~/.config/vpn/openvpn/lab.ovpn`
4. From then on: `nmcli connection up id "lab"`

On Hyprland hosts, Waybar shows your VPN/TUN IP live so you can confirm connectivity at a glance.
On `kali-i3`, wire up a TUN IP block in your i3blocks config via dotfiles.

