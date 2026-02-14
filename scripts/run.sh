#!/usr/bin/env bash
set -euo pipefail

ansible-playbook playbooks/site.yml "$@"
