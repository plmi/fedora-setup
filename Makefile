SHELL := /bin/bash

INVENTORY ?= inventories/lab/hosts.yml
ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE_GALAXY ?= ansible-galaxy
EXTRA_ARGS ?=

.PHONY: help deps doctor apply workstation pentest validate

help:
	@echo "Targets:"
	@echo "  make deps         Install Ansible collections from requirements.yml"
	@echo "  make doctor       Run preflight checks (tools, inventory, SSH, target facts)"
	@echo "  make apply        Run full setup (playbooks/site.yml)"
	@echo "  make workstation  Run workstation setup only"
	@echo "  make pentest      Run pentest + vpn roles only"
	@echo "  make validate     Run validation checks"
	@echo ""
	@echo "Optional overrides:"
	@echo "  INVENTORY=<path>  Inventory file (default: $(INVENTORY))"
	@echo "  EXTRA_ARGS='...'  Extra ansible-playbook flags"

deps:
	$(ANSIBLE_GALAXY) collection install -r requirements.yml

doctor:
	@echo "[1/5] Checking required local tools..."
	@command -v $(ANSIBLE_PLAYBOOK) >/dev/null || (echo "Missing: $(ANSIBLE_PLAYBOOK)"; exit 1)
	@command -v $(ANSIBLE_GALAXY) >/dev/null || (echo "Missing: $(ANSIBLE_GALAXY)"; exit 1)
	@command -v ssh >/dev/null || (echo "Missing: ssh"; exit 1)
	@command -v ansible >/dev/null || (echo "Missing: ansible"; exit 1)
	@command -v ansible-inventory >/dev/null || (echo "Missing: ansible-inventory"; exit 1)
	@echo "[2/5] Checking inventory file..."
	@test -f $(INVENTORY) || (echo "Missing inventory: $(INVENTORY)"; exit 1)
	@echo "[3/5] Validating inventory parse..."
	@ansible-inventory -i $(INVENTORY) --list >/dev/null
	@echo "[4/5] Checking SSH connectivity via Ansible ping..."
	@ansible -i $(INVENTORY) fedora43-utm -m ping -o $(EXTRA_ARGS)
	@echo "[5/5] Checking target OS and architecture..."
	@ansible -i $(INVENTORY) fedora43-utm -m setup -a 'filter=ansible_distribution*' -o $(EXTRA_ARGS)
	@ansible -i $(INVENTORY) fedora43-utm -m setup -a 'filter=ansible_architecture' -o $(EXTRA_ARGS)
	@echo "Doctor checks passed."

apply:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/site.yml $(EXTRA_ARGS)

workstation:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/workstation.yml $(EXTRA_ARGS)

pentest:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/pentest.yml $(EXTRA_ARGS)

validate:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/validate.yml $(EXTRA_ARGS)
