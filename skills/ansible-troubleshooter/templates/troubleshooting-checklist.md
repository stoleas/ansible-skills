# Ansible Troubleshooting Checklist

Use this checklist to systematically debug Ansible playbooks and roles.

## Pre-Execution Checks

- [ ] **Syntax validation**
  ```bash
  ansible-playbook --syntax-check playbook.yml
  ```

- [ ] **Lint validation**
  ```bash
  ansible-lint --profile moderate playbook.yml
  ```

- [ ] **Inventory verification**
  ```bash
  ansible-inventory -i inventory --list
  ansible-inventory -i inventory --graph
  ```

- [ ] **Connectivity test**
  ```bash
  ansible all -i inventory -m ping
  ```

- [ ] **Ansible version check**
  ```bash
  ansible --version  # Ensure compatible version
  ```

## Execution Issues

### Connection Problems

- [ ] **Test SSH manually**
  ```bash
  ssh -i ~/.ssh/key user@host
  ```

- [ ] **Check SSH agent**
  ```bash
  ssh-agent bash
  ssh-add ~/.ssh/id_rsa
  ssh-add -l  # List loaded keys
  ```

- [ ] **Verify host in inventory**
  ```bash
  ansible-inventory -i inventory --host hostname
  ```

- [ ] **Check firewall rules**
  ```bash
  nc -zv hostname 22  # Test SSH port
  ```

- [ ] **Run with connection debugging**
  ```bash
  ansible-playbook -vvv playbook.yml
  ```

### Permission Issues

- [ ] **Provide sudo password**
  ```bash
  ansible-playbook -K playbook.yml
  ```

- [ ] **Check become settings**
  ```yaml
  become: true
  become_method: sudo
  become_user: root
  ```

- [ ] **Verify sudo access on target**
  ```bash
  ssh user@host sudo -l
  ```

- [ ] **Configure passwordless sudo** (if appropriate)
  ```bash
  echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/user
  ```

### Variable Issues

- [ ] **Debug variable value**
  ```yaml
  - name: Show variable
    ansible.builtin.debug:
      var: variable_name
  ```

- [ ] **Check variable precedence**
  - defaults/main.yml (lowest)
  - inventory vars
  - vars/main.yml
  - extra vars -e (highest)

- [ ] **Use default filter**
  ```yaml
  "{{ variable_name | default('fallback') }}"
  ```

- [ ] **View all host variables**
  ```bash
  ansible-inventory --host hostname --yaml
  ```

### Module Failures

- [ ] **Check module documentation**
  ```bash
  ansible-doc module_name
  ```

- [ ] **Verify required executable exists**
  ```yaml
  - ansible.builtin.command: which required_command
    register: cmd_check
    changed_when: false
  ```

- [ ] **Use platform-agnostic modules**
  ```yaml
  # Use package instead of yum/apt
  ansible.builtin.package:
    name: package_name
  ```

- [ ] **Add conditional execution**
  ```yaml
  when: ansible_os_family == "RedHat"
  ```

## Debugging Strategies

### Increase Verbosity

- [ ] **Basic verbosity (-v)**
  ```bash
  ansible-playbook -v playbook.yml
  ```

- [ ] **Show input parameters (-vv)**
  ```bash
  ansible-playbook -vv playbook.yml
  ```

- [ ] **Connection debugging (-vvv)**
  ```bash
  ansible-playbook -vvv playbook.yml
  ```

- [ ] **Maximum verbosity (-vvvv)**
  ```bash
  ansible-playbook -vvvv playbook.yml
  ```

### Isolation and Testing

- [ ] **Check mode (dry run)**
  ```bash
  ansible-playbook --check --diff playbook.yml
  ```

- [ ] **Limit to single host**
  ```bash
  ansible-playbook --limit hostname playbook.yml
  ```

- [ ] **Start at specific task**
  ```bash
  ansible-playbook --start-at-task="Task Name" playbook.yml
  ```

- [ ] **Run specific tags only**
  ```bash
  ansible-playbook --tags install playbook.yml
  ```

- [ ] **Step through playbook**
  ```bash
  ansible-playbook --step playbook.yml
  ```

### Add Debug Tasks

- [ ] **Debug variable values**
  ```yaml
  - name: Debug variables
    ansible.builtin.debug:
      var: item
    loop:
      - variable1
      - variable2
  ```

- [ ] **Register and debug command output**
  ```yaml
  - name: Run command
    ansible.builtin.command: /command
    register: result

  - name: Show output
    ansible.builtin.debug:
      var: result.stdout_lines
  ```

- [ ] **Conditional debug (verbose mode only)**
  ```yaml
  - name: Debug in verbose mode
    ansible.builtin.debug:
      msg: "Debug info"
    when: ansible_verbosity >= 1
  ```

## Idempotence Issues

- [ ] **Run playbook twice**
  ```bash
  ansible-playbook playbook.yml
  ansible-playbook playbook.yml  # Should show changed=0
  ```

- [ ] **Use Molecule idempotence test**
  ```bash
  molecule idempotence
  ```

- [ ] **Check for always-changing tasks**
  - Commands without `changed_when`
  - Shell scripts that always run
  - Timestamp-based operations

- [ ] **Fix non-idempotent tasks**
  - Use declarative modules
  - Add `creates`/`removes` to commands
  - Use `changed_when: false` for checks
  - Replace shell with proper modules

## ansible-lint Issues

- [ ] **Run ansible-lint**
  ```bash
  ansible-lint --profile moderate playbook.yml
  ```

- [ ] **Fix critical errors first**
  - Syntax errors
  - Security issues
  - Deprecated modules

- [ ] **Address warnings**
  - Best practice violations
  - Style issues
  - Optimization opportunities

- [ ] **Configure exceptions (if needed)**
  ```yaml
  # .ansible-lint
  skip_list:
    - yaml[line-length]  # Only if legitimate
  ```

## Role Testing with Molecule

- [ ] **Create test instances**
  ```bash
  molecule create
  ```

- [ ] **Run role**
  ```bash
  molecule converge
  ```

- [ ] **Verify results**
  ```bash
  molecule verify
  ```

- [ ] **Test idempotence**
  ```bash
  molecule idempotence
  ```

- [ ] **Full test suite**
  ```bash
  molecule test
  ```

- [ ] **Clean up**
  ```bash
  molecule destroy
  ```

## Template Issues

- [ ] **Check template syntax**
  - Use `{{ variable | default('value') }}`
  - Check `{% if %}`/`{% endif %}` blocks
  - Verify loop syntax

- [ ] **Test template rendering**
  ```yaml
  - name: Debug template
    ansible.builtin.template:
      src: template.j2
      dest: /tmp/debug_output
    check_mode: yes
    diff: yes
  ```

- [ ] **Verify variables are defined**
  ```jinja2
  {% if variable is defined %}
    {{ variable }}
  {% endif %}
  ```

## Performance Issues

- [ ] **Enable profiling**
  ```ini
  # ansible.cfg
  [defaults]
  callbacks_enabled = ansible.posix.profile_tasks
  ```

- [ ] **Reduce fact gathering**
  ```yaml
  gather_facts: false
  # Or gather only needed facts
  gather_subset:
    - '!all'
    - '!min'
    - network
  ```

- [ ] **Use async for long-running tasks**
  ```yaml
  - name: Long running task
    ansible.builtin.command: /long/command
    async: 3600
    poll: 10
  ```

- [ ] **Parallelize with forks**
  ```bash
  ansible-playbook -f 20 playbook.yml  # 20 parallel forks
  ```

## Validation After Fixes

- [ ] **Syntax check passes**
  ```bash
  ansible-playbook --syntax-check playbook.yml
  ```

- [ ] **ansible-lint passes**
  ```bash
  ansible-lint --profile moderate playbook.yml
  ```

- [ ] **Check mode shows expected changes**
  ```bash
  ansible-playbook --check --diff playbook.yml
  ```

- [ ] **Runs successfully on test host**
  ```bash
  ansible-playbook --limit test_host playbook.yml
  ```

- [ ] **Idempotence test passes**
  ```bash
  # Run twice, second should show changed=0
  ansible-playbook playbook.yml && ansible-playbook playbook.yml
  ```

- [ ] **Full deployment succeeds**
  ```bash
  ansible-playbook playbook.yml
  ```

## Common Error Patterns

### "UNREACHABLE"
- SSH connection failed
- Host not in inventory
- Firewall blocking connection
- Wrong credentials

### "Permission denied"
- Wrong SSH key
- Incorrect sudo password
- User lacks sudo privileges
- File permissions incorrect

### "Undefined variable"
- Variable not defined anywhere
- Typo in variable name
- Wrong variable scope
- Missing defaults

### "Module not found"
- Collection not installed
- Wrong module name (FQCN required)
- Python dependencies missing

### "changed=X" on second run
- Task not idempotent
- Missing `changed_when`
- Timestamp in template
- Always-running command

### "Failed to find required executable"
- Package not installed
- Wrong OS family
- Missing PATH entry
- Platform-specific tool

## Quick Reference Commands

```bash
# Syntax check
ansible-playbook --syntax-check playbook.yml

# Lint check
ansible-lint playbook.yml

# Dry run
ansible-playbook --check playbook.yml

# Test connectivity
ansible all -m ping

# View inventory
ansible-inventory --list

# Check variable
ansible-playbook -e "var_name=value" --tags debug playbook.yml

# List tasks
ansible-playbook --list-tasks playbook.yml

# List tags
ansible-playbook --list-tags playbook.yml

# Gather facts
ansible hostname -m setup

# Check version
ansible --version
```
