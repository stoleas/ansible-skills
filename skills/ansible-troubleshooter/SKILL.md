---
name: ansible-troubleshooter
description: >
  Debug, troubleshoot, and validate Ansible playbooks and roles using ansible-lint, Molecule,
  and debugging best practices. Use this skill when the user asks to: "debug ansible",
  "troubleshoot playbook", "ansible not working", "fix ansible error", "ansible failing",
  "why is ansible", "ansible error", "playbook error", "role failing", "test ansible",
  "ansible lint", "molecule test", "validate playbook", or encounters Ansible errors.
  Always invoke this skill for Ansible debugging and troubleshooting tasks.
version: 1.0.0
allowed-tools: [Read, Bash, Grep, Glob]
---

# Ansible Troubleshooter Skill

Debug, troubleshoot, and validate Ansible playbooks and roles using Red Hat CoP best practices, ansible-lint, and Molecule.

## Troubleshooting Workflow

1. **Identify the issue** - Understand what's failing and where
2. **Gather information** - Use verbosity, logs, debug module
3. **Isolate the problem** - Test specific tasks, use check mode
4. **Apply the fix** - Make targeted changes
5. **Validate** - Ensure fix works and doesn't break other things
6. **Test idempotence** - Verify playbook can run multiple times

## Ansible Verbosity Levels

Use `-v` flags to get more information about execution:

### `-v` (Basic Verbosity)
Shows task results and return values.

```bash
ansible-playbook -v playbook.yml
```

**When to use:**
- See what tasks are doing
- View task return values
- Understand task outcomes

**Output includes:**
- Task results (ok/changed/failed)
- Return values from modules
- Basic execution flow

### `-vv` (More Verbosity)
Shows task input parameters.

```bash
ansible-playbook -vv playbook.yml
```

**When to use:**
- See what parameters are being passed to tasks
- Debug variable interpolation issues
- Understand why a task behaves unexpectedly

**Output includes:**
- All `-v` output
- Task input parameters
- Variable values being used

### `-vvv` (Connection Debug)
Shows connection debugging information.

```bash
ansible-playbook -vvv playbook.yml
```

**When to use:**
- Debug SSH connection issues
- Investigate authentication problems
- Troubleshoot privilege escalation (become)
- See what's happening at the transport layer

**Output includes:**
- All `-vv` output
- SSH connection details
- Authentication attempts
- File transfers
- become/sudo operations

### `-vvvv` (Maximum Verbosity)
Shows SSH protocol details and internal Ansible workings.

```bash
ansible-playbook -vvvv playbook.yml
```

**When to use:**
- Deep protocol debugging
- Understanding Ansible internals
- Reporting bugs to Ansible developers
- Last resort for complex issues

**Output includes:**
- All `-vvv` output
- SSH protocol-level details
- Ansible internal state
- Low-level debugging information

**Warning:** Extremely verbose, use only when needed.

## Common Issues and Solutions

### Issue 1: "Unreachable" Error

**Symptom:**
```
fatal: [host]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh", "unreachable": true}
```

**Causes and Solutions:**

1. **SSH connectivity:**
   ```bash
   # Test SSH manually
   ssh user@host
   
   # Check SSH key
   ssh-agent bash
   ssh-add ~/.ssh/id_rsa
   ```

2. **Incorrect inventory:**
   ```yaml
   # Check inventory file
   [webservers]
   server1 ansible_host=192.168.1.10 ansible_user=admin
   ```

3. **Firewall blocking:**
   ```bash
   # Check if port 22 is open
   telnet host 22
   nc -zv host 22
   ```

4. **Host key verification:**
   ```ini
   # In ansible.cfg
   [defaults]
   host_key_checking = False
   ```

### Issue 2: Permission Denied

**Symptom:**
```
fatal: [host]: FAILED! => {"msg": "Incorrect sudo password"}
```

**Solutions:**

1. **Become password:**
   ```bash
   ansible-playbook -K playbook.yml  # Prompt for sudo password
   ```

2. **Configure passwordless sudo:**
   ```bash
   # On target host
   echo "ansible_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ansible
   ```

3. **Specify become method:**
   ```yaml
   - name: Task requiring privileges
     become: true
     become_method: sudo
     become_user: root
   ```

### Issue 3: Variable Not Defined

**Symptom:**
```
fatal: [host]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'apache_port' is undefined"}
```

**Solutions:**

1. **Check variable definition:**
   ```bash
   # See all variables for a host
   ansible-inventory -i inventory --host server1 --yaml
   ```

2. **Use default filter:**
   ```yaml
   - name: Use variable with default
     ansible.builtin.debug:
       msg: "Port: {{ apache_port | default(80) }}"
   ```

3. **Check variable precedence:**
   - defaults/main.yml (lowest)
   - inventory variables
   - vars/main.yml
   - extra vars -e (highest)

4. **Debug variable value:**
   ```yaml
   - name: Show variable
     ansible.builtin.debug:
       var: apache_port
   ```

### Issue 4: Module Failures

**Symptom:**
```
fatal: [host]: FAILED! => {"changed": false, "msg": "Failed to find required executable apt-get"}
```

**Solutions:**

1. **Check if module/executable exists:**
   ```yaml
   - name: Check if command exists
     ansible.builtin.command: which apt-get
     register: cmd_check
     changed_when: false
     failed_when: false
   ```

2. **Use platform-agnostic modules:**
   ```yaml
   # Instead of apt/yum
   - name: Install package
     ansible.builtin.package:
       name: httpd
       state: present
   ```

3. **Conditional execution:**
   ```yaml
   - name: Install on Debian
     ansible.builtin.apt:
       name: apache2
     when: ansible_os_family == "Debian"
   ```

### Issue 5: Idempotence Failures

**Symptom:**
Running the playbook twice shows "changed" on second run.

**Solutions:**

1. **Use declarative modules:**
   ```yaml
   # Bad - always reports changed
   - ansible.builtin.command: yum install -y httpd
   
   # Good - idempotent
   - ansible.builtin.package:
       name: httpd
       state: present
   ```

2. **Add `changed_when` for commands:**
   ```yaml
   - name: Validate configuration
     ansible.builtin.command: httpd -t
     changed_when: false
   ```

3. **Use `creates`/`removes`:**
   ```yaml
   - name: Initialize database
     ansible.builtin.command: /usr/local/bin/init-db.sh
     args:
       creates: /var/lib/db/.initialized
   ```

### Issue 6: Template Rendering Errors

**Symptom:**
```
AnsibleUndefinedVariable: 'variable_name' is undefined
```

**Solutions:**

1. **Check template syntax:**
   ```jinja2
   # Use default filter
   Port {{ apache_port | default(80) }}
   
   # Check if variable is defined
   {% if apache_ssl_enabled is defined and apache_ssl_enabled %}
   SSLEngine on
   {% endif %}
   ```

2. **Debug template variables:**
   ```yaml
   - name: Show all variables available
     ansible.builtin.template:
       src: config.j2
       dest: /tmp/debug_config
     check_mode: yes
     diff: yes
   ```

## Debugging Strategies

### 1. Use the Debug Module

```yaml
- name: Debug variable value
  ansible.builtin.debug:
    var: my_variable

- name: Debug with message
  ansible.builtin.debug:
    msg: "The value is {{ my_variable }}"

- name: Debug multiple variables
  ansible.builtin.debug:
    msg: |
      Variable 1: {{ var1 }}
      Variable 2: {{ var2 }}
      Variable 3: {{ var3 }}

- name: Conditional debugging
  ansible.builtin.debug:
    msg: "This only shows in verbose mode"
  when: ansible_verbosity >= 1
```

### 2. Register and Debug Pattern

```yaml
- name: Run command
  ansible.builtin.command: /usr/bin/some-command
  register: command_result

- name: Show command output
  ansible.builtin.debug:
    var: command_result

- name: Show just stdout
  ansible.builtin.debug:
    var: command_result.stdout_lines
```

### 3. Use Check Mode (Dry Run)

```bash
# Run in check mode - no changes made
ansible-playbook --check playbook.yml

# See diff of what would change
ansible-playbook --check --diff playbook.yml
```

```yaml
# Skip tasks in check mode
- name: This task will be skipped in check mode
  ansible.builtin.command: /dangerous/command
  check_mode: false

# Always run in check mode
- name: This task always runs in check mode
  ansible.builtin.stat:
    path: /some/file
  check_mode: true
```

### 4. Limit to Specific Hosts

```bash
# Test on single host first
ansible-playbook --limit server1 playbook.yml

# Test on subset
ansible-playbook --limit 'webservers:&production' playbook.yml
```

### 5. Start at Specific Task

```bash
# Start from specific task
ansible-playbook --start-at-task="Install Apache" playbook.yml

# Use tags to run specific tasks
ansible-playbook --tags "install,configure" playbook.yml

# Skip specific tags
ansible-playbook --skip-tags "deploy" playbook.yml
```

### 6. Step Through Playbook

```bash
# Confirm each task before running
ansible-playbook --step playbook.yml
```

## ansible-lint Best Practices

ansible-lint validates playbooks against best practices and Red Hat CoP standards.

### Running ansible-lint

```bash
# Lint a playbook
ansible-lint playbook.yml

# Lint a role
ansible-lint roles/my_role/

# Lint with specific profile
ansible-lint --profile moderate playbook.yml

# Lint with rules list
ansible-lint --list-rules

# Show all violations (including warnings)
ansible-lint -p playbook.yml
```

### Profiles

Red Hat CoP recommends the **moderate** profile:

```yaml
# .ansible-lint
---
profile: moderate
```

**Profiles hierarchy:**
- `min` - Minimal rules (basic syntax)
- `basic` - Basic best practices
- `moderate` - Red Hat CoP recommended (default)
- `safety` - Safety-critical rules
- `shared` - For shared/reusable content
- `production` - Production-ready standards

### Common ansible-lint Rules

#### name[missing] - Tasks should have names

**Bad:**
```yaml
- ansible.builtin.package:
    name: httpd
```

**Good:**
```yaml
- name: Install Apache
  ansible.builtin.package:
    name: httpd
```

#### yaml[line-length] - Lines too long

**Bad:**
```yaml
- name: Very long task name that goes on and on and on and exceeds the recommended line length of 160 characters which makes it hard to read
```

**Good:**
```yaml
- name: Configure application with recommended settings
```

#### fqcn[action-core] - Use FQCN for modules

**Bad:**
```yaml
- name: Install package
  package:
    name: httpd
```

**Good:**
```yaml
- name: Install package
  ansible.builtin.package:
    name: httpd
```

#### no-changed-when - Commands should have changed_when

**Bad:**
```yaml
- name: Check config
  ansible.builtin.command: httpd -t
```

**Good:**
```yaml
- name: Check config
  ansible.builtin.command: httpd -t
  changed_when: false
```

### Fixing ansible-lint Violations

1. **Auto-fix where possible:**
   ```bash
   # Not yet available in ansible-lint, but planned
   # ansible-lint --fix playbook.yml
   ```

2. **Skip specific rules (use sparingly):**
   ```yaml
   - name: Special case task
     ansible.builtin.command: /special/command
     tags:
       - skip_ansible_lint
   ```

3. **Configure in .ansible-lint:**
   ```yaml
   skip_list:
     - yaml[line-length]  # If you have legitimate long lines
   ```

## Molecule Testing

Molecule provides comprehensive role testing.

### Molecule Test Sequence

```bash
# Full test (destroy, create, converge, verify)
molecule test

# Individual steps
molecule create      # Create test instances
molecule converge    # Apply the role
molecule verify      # Run verification tests
molecule idempotence # Check idempotence
molecule destroy     # Clean up

# Development workflow
molecule converge    # Apply changes
molecule verify      # Test the result
# Make fixes
molecule converge    # Reapply
molecule verify      # Verify again
molecule destroy     # Clean up when done
```

### Idempotence Testing

Molecule's idempotence test runs the role twice and fails if changes are reported on the second run:

```bash
molecule idempotence
```

**Expected output:**
```
Idempotence completed successfully.
```

**If it fails:**
```
CRITICAL Idempotence test failed because of the following tasks:
* [instance] => Task: Install package
```

This means the task is not idempotent - fix it before proceeding.

### Molecule Verify Stage

Write verification tests in `molecule/default/verify.yml`:

```yaml
---
- name: Verify
  hosts: all
  gather_facts: true
  tasks:
    - name: Verify package is installed
      ansible.builtin.package_facts:

    - name: Assert package is present
      ansible.builtin.assert:
        that:
          - "'httpd' in ansible_facts.packages"
        fail_msg: "Apache package not installed"

    - name: Verify service is running
      ansible.builtin.service_facts:

    - name: Assert service is active
      ansible.builtin.assert:
        that:
          - ansible_facts.services['httpd.service'].state == 'running'
        fail_msg: "Apache service not running"

    - name: Verify config file exists
      ansible.builtin.stat:
        path: /etc/httpd/conf/httpd.conf
      register: config_file

    - name: Assert config is present
      ansible.builtin.assert:
        that:
          - config_file.stat.exists
        fail_msg: "Apache config not found"
```

## Validation Workflow

Complete validation workflow for playbooks and roles:

### 1. Syntax Check

```bash
ansible-playbook --syntax-check playbook.yml
```

Catches basic YAML and Ansible syntax errors.

### 2. Lint Check

```bash
ansible-lint --profile moderate playbook.yml
```

Validates against best practices and Red Hat CoP standards.

### 3. Check Mode (Dry Run)

```bash
ansible-playbook --check --diff playbook.yml
```

Shows what would change without making changes.

### 4. Limited Execution

```bash
# Test on one host first
ansible-playbook --limit test_server playbook.yml
```

Validate on a subset before full deployment.

### 5. Full Execution with Verbosity

```bash
ansible-playbook -v playbook.yml
```

Run with appropriate verbosity level.

### 6. Idempotence Test

```bash
# Run twice, second run should show no changes
ansible-playbook playbook.yml
ansible-playbook playbook.yml | grep "changed=0"
```

Or use Molecule for roles:
```bash
molecule idempotence
```

## Quick Troubleshooting Commands

```bash
# Check inventory
ansible-inventory -i inventory --list
ansible-inventory -i inventory --host server1

# Test connectivity
ansible all -i inventory -m ping

# Gather facts from a host
ansible server1 -i inventory -m setup

# Check which Python Ansible is using
ansible --version

# See all variables for a host
ansible-playbook playbook.yml --limit server1 -e "ansible_verbosity=4" --tags never

# Validate variable files
python -c "import yaml; yaml.safe_load(open('vars/main.yml'))"

# Check role dependencies
ansible-galaxy role info namespace.role_name

# List all tasks in a playbook
ansible-playbook --list-tasks playbook.yml

# List all tags
ansible-playbook --list-tags playbook.yml
```

## Error Message Decoder

### "No hosts matched"
- Check inventory file
- Verify host pattern in playbook
- Use `ansible-inventory --list` to see available hosts

### "Could not match supplied host pattern"
- Check `hosts:` line in playbook
- Verify group names in inventory

### "Timeout waiting for privilege escalation password"
- Add `-K` flag to prompt for sudo password
- Configure passwordless sudo
- Check `become` settings

### "Permission denied (publickey)"
- Check SSH key: `ssh-add -l`
- Verify `ansible_user` in inventory
- Test SSH manually: `ssh user@host`

### "conflicting action statements"
- Module specified with wrong syntax
- Check module documentation: `ansible-doc module_name`

## Debugging Checklist

- [ ] Run with `-v` to see task results
- [ ] Use `--syntax-check` to validate YAML
- [ ] Run `ansible-lint` to check best practices
- [ ] Use `--check` mode for dry run
- [ ] Test on single host with `--limit`
- [ ] Add `debug` tasks to show variable values
- [ ] Use `register` to capture task output
- [ ] Check `ansible.log` if logging enabled
- [ ] Verify inventory with `ansible-inventory --list`
- [ ] Test connectivity with `ansible all -m ping`
- [ ] Run with `-vvv` for connection issues
- [ ] Check idempotence by running twice
- [ ] Use Molecule for comprehensive role testing

When troubleshooting Ansible issues, systematically identify the problem, gather information with appropriate verbosity, isolate the failing component, apply targeted fixes, and validate the solution using ansible-lint and idempotence testing.
