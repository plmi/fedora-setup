# Tool Matrix

| Tool | Source | Method |
|---|---|---|
| hyprland | COPR `solopasha/hyprland` | dnf |
| foot | Fedora repos | dnf |
| neovim | Fedora repos | dnf |
| tmux | Fedora repos | dnf |
| eza | GitHub `eza-community/eza` latest | binary tarball install |
| nmap | Fedora repos | dnf |
| ffuf | Fedora repos | dnf |
| feroxbuster | GitHub `epi052/feroxbuster` latest | binary zip install |
| nikto | GitHub `sullo/nikto` latest | source zip + wrapper install |
| sqlmap | GitHub `sqlmapproject/sqlmap` | git clone + wrapper install |
| impacket | PyPI | pipx install |
| metasploit | Snap Store | snap install metasploit-framework |
| burp community | PortSwigger CDN | download jar + wrapper |
| wpscan | RubyGems | gem install |
| searchsploit | GitLab `exploitdb` repo | git clone + symlink + rc path rewrite |
| seclists | GitHub `danielmiessler/SecLists` | master.zip extract to /usr/share/seclists |
| rockyou.txt | SecLists (or fallback URL) | copy/download to /usr/share/wordlists/rockyou.txt |
| john | Fedora repos | dnf |
| hashcat | Fedora repos | dnf |
| openvpn | Fedora repos | dnf |
| wireguard-tools | Fedora repos | dnf |
