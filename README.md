# Fedora 43 Hyprland OSCP Lab (Ansible)

A reproducible Fedora 43 pentest workstation for UTM/VM use.
No click-ops. No mystery state. Just `make apply`.

## What You Get
- Minimal Hyprland desktop tuned for operator workflow
- `foot` + `zsh` + `tmux` + `neovim`
- OSCP-oriented tooling with Kali-like paths where it matters
- Screenshot + annotation flow for report evidence (`grim` + `slurp` + `swappy`)

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
