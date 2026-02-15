# Fedora 43 Hyprland OSCP Lab (Ansible)

A reproducible Fedora 43 pentest workstation for UTM/VM use.
No click-ops. No mystery state. Just `make apply`.

## What You Get
- Minimal Hyprland desktop tuned for operator workflow
- `foot` + `zsh` + `tmux` + `neovim`
- OSCP-oriented tooling with Kali-like paths where it matters
- Screenshot + annotation flow for report evidence (`grim` + `slurp` + `swappy`)
- OSCP-focused Waybar with VPN/target/public-IP visibility

## Fast Start
```bash
make deps
make doctor
make apply
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
ansible --version
```

Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y ansible
ansible --version
```

## Required VM Prep
Confirm SSH first:
```bash
ssh michael@192.168.64.6
```

Recommended (key auth):
```bash
ssh-copy-id michael@192.168.64.6
make apply
```

Password auth fallback:
```bash
make doctor EXTRA_ARGS='--ask-pass --ask-become-pass'
make apply EXTRA_ARGS='--ask-pass --ask-become-pass'
```

## Playbooks
- `playbooks/workstation.yml`: base OS + user + shell + Hyprland
- `playbooks/pentest.yml`: pentest tools + VPN tooling
- `playbooks/site.yml`: full setup (workstation + pentest)
- `playbooks/validate.yml`: post-install checks

## Make Targets
- `make deps`: install required Ansible collections
- `make doctor`: preflight checks (tools, inventory, SSH, target facts)
- `make apply`: run full setup
- `make workstation`: run workstation stack only
- `make pentest`: run pentest stack only
- `make validate`: run validation checks

## Tool Install Sources
### DNF/COPR
- Hyprland via COPR `solopasha/hyprland`
- Core packages: `curl`, `wget`, `nmap`, `gobuster`, `hydra`, etc.

### GitHub / Source / Wrappers
- `eza`: latest GitHub binary (`aarch64` Linux asset)
- `feroxbuster`: latest GitHub binary (`aarch64` Linux asset)
- `nikto`: latest release zip to `/opt/nikto/<tag>` + wrapper at `/usr/local/bin/nikto`
- `sqlmap`: git clone to `/opt/sqlmap/current` + wrapper at `/usr/local/bin/sqlmap`
- `searchsploit`: git clone to `/opt/exploit-database` + symlink `/usr/local/bin/searchsploit`

### Language/Runtime Managers
- `impacket`: `python3 -m pipx install impacket`
- `wpscan`: `gem install wpscan --no-document`
- `metasploit`: `snap install metasploit-framework`

### Flatpak
- Obsidian: `md.obsidian.Obsidian` (via Flathub)

### Burp + Wordlists
- Burp Community jar -> `/opt/burp/burpsuite_community.jar` + wrapper `/usr/local/bin/burp`
- Kali-like wordlist paths:
  - `/usr/share/seclists`
  - `/usr/share/wordlists/rockyou.txt`

## Without Make
```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventories/lab/hosts.yml playbooks/site.yml
ansible-playbook -i inventories/lab/hosts.yml playbooks/workstation.yml
ansible-playbook -i inventories/lab/hosts.yml playbooks/pentest.yml
ansible-playbook -i inventories/lab/hosts.yml playbooks/validate.yml
```

## Notes
- Use only on systems/networks you own or are explicitly authorized to test.
- Store secrets with Ansible Vault.
- Disable Hyprland COPR if needed via `hyprland_enable_copr: false` in `inventories/lab/group_vars/hyprland.yml`.
- `ansible.cfg` uses `ssh_connection.usetty=False` to avoid OSC 3008 escape-sequence noise in module JSON output.

## VPN Profile Import (nmcli)
- The OSCP launcher VPN toggle (`SUPER+R` -> `VPN: toggle connection`) uses NetworkManager profiles from `nmcli`, not raw config files.
- Import each config once, then select it from the launcher list.

OpenVPN (`.ovpn`):
```bash
nmcli connection import type openvpn file /path/to/lab.ovpn
```

WireGuard (`.conf`):
```bash
nmcli connection import type wireguard file /path/to/lab.conf
```

Useful commands:
```bash
nmcli -t -f NAME,TYPE connection show | grep -E ':(vpn|wireguard)$'
nmcli connection show --active
nmcli connection up id "<profile-name>"
nmcli connection down id "<profile-name>"
```

## Waybar Behavior
- Config files:
  - `~/.config/waybar/config.jsonc`
  - `~/.config/waybar/style.css`
- Custom module scripts:
  - `~/.config/waybar/scripts/vpn-status.sh`
  - `~/.config/waybar/scripts/target-status.sh`
  - `~/.config/waybar/scripts/public-ip.sh`
- Layout:
  - Left: `hyprland/workspaces`, `hyprland/window`
  - Center: `clock`
  - Right: VPN, target, public IP, network, audio, CPU, RAM, temperature, battery, tray
- Target module behavior:
  - Shows `Target <value>` when `~/.target` first line is set and not `unset`
  - Shows `No Target` when missing/empty/`unset`
  - Click opens `~/.target` in `nvim` (`foot`)
- VPN module behavior:
  - Detects active `tun/tap/wg/ppp` interfaces
  - Shows connected/disconnected state with color cues
  - Click disconnects active VPN, or opens a `wofi` picker to connect a saved `nmcli` VPN/WireGuard profile
- Public IP module behavior:
  - Polls egress IP every 5 minutes
  - Click shows a one-shot IP check in `foot`
- Clock behavior:
  - No click action configured

## Hyprland Keybindings (Non-default)
- Modifier: `SUPER` (`$mainMod`)
- `SUPER+RETURN`: open terminal (`foot`)
- `SUPER+P`: app launcher (`wofi --show drun`)
- `SUPER+D`: app launcher (`wofi --show drun`)
- `SUPER+R`: OSCP launcher (`~/.local/bin/wofi-oscp`)
- `SUPER+TAB`: switch to previous workspace
- `SUPER+SPACE`: toggle special workspace (`magic`)
- `SUPER+SHIFT+SPACE`: move active window to special workspace (`magic`)
- `SUPER+SHIFT+S`: region screenshot to `swappy` flow (`grim` + `slurp`)
- `SUPER+SHIFT+W`: cycle wallpapers (every image in `~/.local/share/wallpapers`, sorted by filename -> repeat)
- `SUPER+B`: toggle Waybar visibility (`pkill -USR1 waybar`)
- `SUPER+Q`: close active window
- `SUPER+SHIFT+E`: exit Hyprland session
- `SUPER+F`: toggle fullscreen
- `SUPER+V`: toggle floating mode for active window
- `SUPER+L`: lock screen (`hyprlock`) and also mapped to focus-right (conflicting bind in current config)
- `SUPER+1..9`: switch to workspace 1..9
- `SUPER+SHIFT+1..9`: move active window to workspace 1..9
- `SUPER+H`: move focus left
- `SUPER+L`: move focus right (conflicts with lock bind above)
- `SUPER+K`: move focus up
- `SUPER+J`: move focus down
- `SUPER+Left Mouse`: move window (drag)
- `SUPER+Right Mouse`: resize window (drag)
