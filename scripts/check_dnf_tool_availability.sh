#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/check_dnf_tool_availability.sh [ssh_target]
# Example:
#   scripts/check_dnf_tool_availability.sh michael@192.168.64.6

SSH_TARGET="${1:-michael@192.168.64.6}"

if ! command -v ssh >/dev/null 2>&1; then
  echo "ERROR: ssh is required but not installed."
  exit 1
fi

echo "Checking package availability on ${SSH_TARGET} via dnf..."
echo

# Format: tool_label|ansible_group|candidate_pkg1,candidate_pkg2
TOOL_MAP="$(cat <<'EOF'
arp-scan|pentest_core|arp-scan
exiftool|pentest_core|perl-Image-ExifTool,exiftool
wsgidav|pentest_core|wsgidav,python3-wsgidav
rlwrap|pentest_core|rlwrap
metasploit|pentest_core|metasploit-framework,metasploit
wget|base|wget
curl|base|curl
gobuster|pentest_core|gobuster
burp-community|pentest_core|burpsuite,burp-suite
wpscan|pentest_core|wpscan
searchsploit|pentest_core|exploitdb,searchsploit
nc|pentest_core|netcat,nmap-ncat
ftp|pentest_core|ftp,lftp
rclone|pentest_core|rclone
hydra|pentest_core|hydra
proxychains|pentest_core|proxychains-ng,proxychains
dig|pentest_core|bind-utils
dnsenum|pentest_core|dnsenum
EOF
)"

remote_dnf_check() {
  local pkg="$1"
  ssh -n -o ConnectTimeout=8 -o BatchMode=yes "${SSH_TARGET}" \
    "dnf -q info '${pkg}' >/dev/null 2>&1"
}

available_base=()
available_pentest=()
missing_tools=()

while IFS='|' read -r tool group candidates; do
  [[ -z "${tool}" ]] && continue

  found_pkg=""
  IFS=',' read -r -a cand_array <<< "${candidates}"
  for pkg in "${cand_array[@]}"; do
    if remote_dnf_check "${pkg}"; then
      found_pkg="${pkg}"
      break
    fi
  done

  if [[ -n "${found_pkg}" ]]; then
    if [[ "${group}" == "base" ]]; then
      available_base+=("${tool}:${found_pkg}")
    else
      available_pentest+=("${tool}:${found_pkg}")
    fi
  else
    missing_tools+=("${tool}")
  fi
done <<< "${TOOL_MAP}"

echo "=== AVAILABLE (add these) ==="
echo
echo "base_packages:"
if ((${#available_base[@]} == 0)); then
  echo "  (none)"
else
  for entry in "${available_base[@]}"; do
    pkg="${entry#*:}"
    echo "  - ${pkg}"
  done | sort -u
fi

echo
echo "pentest_core_packages:"
if ((${#available_pentest[@]} == 0)); then
  echo "  (none)"
else
  for entry in "${available_pentest[@]}"; do
    pkg="${entry#*:}"
    echo "  - ${pkg}"
  done | sort -u
fi

echo
echo "=== NOT AVAILABLE VIA DNF ==="
if ((${#missing_tools[@]} == 0)); then
  echo "  (none)"
else
  for tool in "${missing_tools[@]}"; do
    echo "  - ${tool}"
  done
fi

echo
echo "Done."
