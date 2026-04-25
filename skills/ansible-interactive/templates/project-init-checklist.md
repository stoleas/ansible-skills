# Ansible Project Initialization Checklist

Use this checklist to ensure proper project setup.

## Phase 1: Environment Validation

- [ ] Ansible installed (`ansible --version`)
- [ ] Python 3.x available (`python3 --version`)
- [ ] SSH client available (`ssh -V`)
- [ ] Target hosts accessible via ping
- [ ] SSH keys configured or password available
- [ ] Sudo/privilege escalation configured on targets

## Phase 2: Project Structure

- [ ] Project directory created
- [ ] Standard subdirectories exist:
  - [ ] `inventory/`
  - [ ] `group_vars/`
  - [ ] `host_vars/`
  - [ ] `roles/`
  - [ ] `playbooks/`
  - [ ] `files/`
  - [ ] `templates/`
- [ ] `ansible.cfg` created and configured
- [ ] Git repository initialized
- [ ] `.gitignore` created (exclude sensitive files)

## Phase 3: Inventory Setup

- [ ] Inventory file created (`inventory/hosts.yml`)
- [ ] All hosts defined with `ansible_host`
- [ ] Host groups organized logically
- [ ] Connection variables set (`ansible_user`, etc.)
- [ ] Inventory validated (`ansible-inventory --list`)

## Phase 4: Connectivity Testing

- [ ] Ping test successful (`ansible all -m ping`)
- [ ] Facts gathering works (`ansible all -m setup`)
- [ ] Privilege escalation tested (`ansible all -m shell -a "whoami" --become`)
- [ ] All hosts responsive
- [ ] Connection errors resolved

## Phase 5: First Playbook

- [ ] Simple test playbook created
- [ ] Syntax validated (`--syntax-check`)
- [ ] Check mode tested (`--check`)
- [ ] Playbook executes successfully
- [ ] Output reviewed for warnings

## Phase 6: Configuration Management

- [ ] Templates created in `templates/`
- [ ] Variables defined in `group_vars/`
- [ ] Playbook uses templates
- [ ] Configuration validated on target
- [ ] Handlers work correctly

## Phase 7: Role Development

- [ ] Role structure created (`ansible-galaxy role init`)
- [ ] Tasks moved from playbook to role
- [ ] Variables moved to `defaults/main.yml`
- [ ] Templates moved to role
- [ ] Role README documented

## Phase 8: Testing

- [ ] ansible-lint installed
- [ ] All playbooks lint-clean
- [ ] Molecule installed (for roles)
- [ ] Molecule tests pass
- [ ] Idempotency verified

## Phase 9: Documentation

- [ ] Project README created
- [ ] Role README files complete
- [ ] Usage examples provided
- [ ] Variable documentation complete
- [ ] Inline comments added where needed

## Phase 10: Production Readiness

- [ ] All tests passing
- [ ] Staging environment validated
- [ ] Rollback plan documented
- [ ] Deployment runbook created
- [ ] Team trained on playbooks
- [ ] Version control up to date

## Notes

Record any issues or deviations from standard setup:

```
Date: ___________
Issue: 
Resolution:

Date: ___________
Issue: 
Resolution:
```
