#!/usr/bin/env bash
set -euo pipefail

ansible-playbook playbooks/validate.yml "$@"
