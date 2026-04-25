# Interactive Troubleshooting Guide

Step-by-step troubleshooting for common Ansible issues during interactive development.

## Connectivity Issues

### Issue: "Host unreachable" or timeout errors

**Symptoms:**
```
fatal: [server01]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh", "unreachable": true}
```

**Interactive Diagnosis:**

**Q: Can you ping the host?**
```bash
ping -c 3 server01
```
- ✅ Yes → Network is fine, SSH issue
- ❌ No → Network/DNS problem

**Q: Can you resolve the hostname?**
```bash
nslookup server01
# Or
getent hosts server01
```
- ❌ Fails → Add to /etc/hosts or use IP address

**Q: Is SSH service running?**
```bash
# From another terminal
ssh -v user@server01
```
Look for connection errors in verbose output

**Solutions:**
1. **Use IP address instead of hostname**
   ```yaml
   # inventory/hosts.yml
   server01:
     ansible_host: 192.168.1.10  # Use IP instead of hostname
   ```

2. **Check SSH port**
   ```yaml
   server01:
     ansible_host: 192.168.1.10
     ansible_port: 2222  # Non-standard SSH port
   ```

3. **Verify firewall**
   ```bash
   # On target host
   sudo ufw status
   sudo firewall-cmd --list-all
   ```

---

### Issue: "Permission denied (publickey)"

**Symptoms:**
```
fatal: [server01]: UNREACHABLE! => {"msg": "Failed to connect to the host via ssh: Permission denied (publickey,password)."}
```

**Interactive Diagnosis:**

**Q: Do you have an SSH key?**
```bash
ls -la ~/.ssh/id_*
```
- ❌ No keys → Generate one: `ssh-keygen -t ed25519`

**Q: Is the key added to ssh-agent?**
```bash
ssh-add -l
```
- ❌ Not listed → Add it: `ssh-add ~/.ssh/id_ed25519`

**Q: Is the key on the remote host?**
```bash
ssh user@server01 "cat ~/.ssh/authorized_keys"
```
- ❌ Your key not listed → Copy it: `ssh-copy-id user@server01`

**Solutions:**
1. **Use password authentication temporarily**
   ```yaml
   # inventory/hosts.yml
   server01:
     ansible_host: 192.168.1.10
     ansible_user: ubuntu
     ansible_ssh_pass: "{{ lookup('env', 'ANSIBLE_SSH_PASSWORD') }}"
   ```
   
   Run with: `ANSIBLE_SSH_PASSWORD=password ansible-playbook ...`

2. **Specify SSH key explicitly**
   ```yaml
   server01:
     ansible_host: 192.168.1.10
     ansible_user: ubuntu
     ansible_ssh_private_key_file: ~/.ssh/custom_key
   ```

---

## Privilege Escalation Issues

### Issue: "Missing sudo password"

**Symptoms:**
```
fatal: [server01]: FAILED! => {"msg": "Missing sudo password"}
```

**Interactive Diagnosis:**

**Q: Does your user have sudo access?**
```bash
ssh user@server01 "sudo -l"
```

**Q: Is passwordless sudo configured?**
```bash
ssh user@server01 "sudo -n true && echo 'Passwordless sudo OK'"
```

**Solutions:**
1. **Provide sudo password**
   ```yaml
   # inventory/hosts.yml
   all:
     vars:
       ansible_become_password: "{{ lookup('env', 'ANSIBLE_BECOME_PASSWORD') }}"
   ```
   
   Run with: `ANSIBLE_BECOME_PASSWORD=password ansible-playbook ...`

2. **Configure passwordless sudo on target**
   ```bash
   # On target host as root
   echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
   ```

3. **Use become_method**
   ```yaml
   # If sudo requires password but su doesn't
   all:
     vars:
       ansible_become_method: su
   ```

---

## Playbook Execution Issues

### Issue: "Syntax error in playbook"

**Symptoms:**
```
ERROR! Syntax Error while loading YAML.
```

**Interactive Diagnosis:**

**Q: Is the YAML valid?**
```bash
# Check with Python
python3 -c "import yaml; yaml.safe_load(open('playbook.yml'))"
```

**Q: Are indentations correct?**
- Use 2 spaces (not tabs)
- Lists and dicts must be properly indented

**Common mistakes:**
```yaml
# WRONG - task at same level as name
- name: My playbook
  hosts: all
- name: Task  # Wrong indent

# CORRECT
- name: My playbook
  hosts: all
  tasks:
    - name: Task  # Correct indent
```

**Solution:**
```bash
# Use ansible-lint to find issues
pip install ansible-lint
ansible-lint playbook.yml
```

---

### Issue: "Module not found"

**Symptoms:**
```
fatal: [server01]: FAILED! => {"msg": "The module ansible.builtin.something was not found"}
```

**Interactive Diagnosis:**

**Q: Is the module name correct?**
```bash
# List all available modules
ansible-doc -l | grep module_name
```

**Q: Is it in a collection?**
- Many modules moved to collections in Ansible 2.10+
- Use FQCN (Fully Qualified Collection Name)

**Solutions:**
```yaml
# WRONG - short name
tasks:
  - name: Copy file
    copy:  # May not work in newer Ansible

# CORRECT - FQCN
tasks:
  - name: Copy file
    ansible.builtin.copy:  # Always works
```

---

### Issue: "Task shows 'changed' but shouldn't"

**Symptoms:**
Task reports changes on every run (not idempotent)

**Interactive Diagnosis:**

**Q: What type of module is it?**
- `command`, `shell`, `raw` always report changed
- Other modules should be idempotent

**Q: Is there a better module?**
```yaml
# WRONG - always shows changed
- name: Create directory
  shell: mkdir -p /opt/myapp

# CORRECT - idempotent
- name: Create directory
  file:
    path: /opt/myapp
    state: directory
```

**Solutions:**
1. **Use changed_when for shell/command**
   ```yaml
   - name: Check if file exists
     command: test -f /path/to/file
     register: file_check
     failed_when: false
     changed_when: false  # Never report as changed
   ```

2. **Use creates parameter**
   ```yaml
   - name: Extract archive
     command: tar -xzf app.tar.gz
     args:
       chdir: /opt
       creates: /opt/app  # Only run if this doesn't exist
   ```

---

## Variable Issues

### Issue: "Variable is undefined"

**Symptoms:**
```
fatal: [server01]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'my_variable' is undefined"}
```

**Interactive Diagnosis:**

**Q: Where is the variable defined?**
Check in order of precedence:
1. Extra vars (`-e` flag)
2. Task vars
3. Host vars
4. Group vars
5. Role defaults

**Q: Is the variable name spelled correctly?**
```bash
# Show all variables for a host
ansible server01 -m debug -a "var=hostvars[inventory_hostname]"
```

**Solutions:**
1. **Define in group_vars**
   ```yaml
   # group_vars/all.yml
   my_variable: value
   ```

2. **Provide default value**
   ```yaml
   tasks:
     - name: Use variable
       debug:
         msg: "{{ my_variable | default('default_value') }}"
   ```

3. **Pass as extra var**
   ```bash
   ansible-playbook playbook.yml -e "my_variable=value"
   ```

---

## Performance Issues

### Issue: "Playbook runs very slowly"

**Interactive Diagnosis:**

**Q: How many hosts are you managing?**
```bash
ansible all --list-hosts | wc -l
```

**Q: Are you using serial execution?**
```yaml
# Check if serial is set
- hosts: all
  serial: 1  # Processes one host at a time (slow)
```

**Q: Is pipelining enabled?**
```bash
# Check ansible.cfg
grep pipelining ansible.cfg
```

**Solutions:**
1. **Increase forks**
   ```ini
   # ansible.cfg
   [defaults]
   forks = 50  # Default is 5
   ```

2. **Enable pipelining**
   ```ini
   [ssh_connection]
   pipelining = True
   ```

3. **Use strategy: free**
   ```yaml
   - hosts: all
     strategy: free  # Don't wait for all hosts to complete each task
   ```

4. **Disable fact gathering if not needed**
   ```yaml
   - hosts: all
     gather_facts: no
   ```

---

## Debugging Workflow

### Step-by-Step Debugging Process

**1. Increase verbosity**
```bash
ansible-playbook playbook.yml -v    # Basic
ansible-playbook playbook.yml -vv   # More
ansible-playbook playbook.yml -vvv  # Even more
ansible-playbook playbook.yml -vvvv # Everything (includes SSH debugging)
```

**2. Isolate the problem**
```bash
# Run on single host
ansible-playbook playbook.yml --limit problem_host

# Run single tag
ansible-playbook playbook.yml --tags problem_task

# Start at specific task
ansible-playbook playbook.yml --start-at-task="Problem Task"
```

**3. Add debug tasks**
```yaml
- name: Debug variable
  debug:
    var: my_variable

- name: Debug complex expression
  debug:
    msg: "Value is {{ my_variable | to_json }}"
```

**4. Test manually**
```bash
# Run the equivalent command directly
ansible problem_host -m shell -a "the-command-that-fails" -vvv
```

**5. Check logs**
```bash
# Ansible log (if configured)
tail -f /var/log/ansible.log

# Target host logs
ansible all -m shell -a "tail -50 /var/log/syslog" --become
```

---

## Quick Troubleshooting Commands

```bash
# Test connectivity
ansible all -m ping

# Check Python version on targets
ansible all -m setup -a "filter=ansible_python_version"

# Verify sudo works
ansible all -m shell -a "whoami" --become

# List all facts
ansible hostname -m setup

# Check specific fact
ansible hostname -m setup -a "filter=ansible_distribution*"

# Test command on all hosts
ansible all -m shell -a "your-command"

# Show inventory
ansible-inventory --graph

# Validate playbook syntax
ansible-playbook playbook.yml --syntax-check

# Dry run playbook
ansible-playbook playbook.yml --check

# Show diff of changes
ansible-playbook playbook.yml --check --diff

# Step through playbook interactively
ansible-playbook playbook.yml --step
```

---

## Getting Help

**1. Check module documentation**
```bash
ansible-doc module_name
ansible-doc -l  # List all modules
```

**2. Search for examples**
```bash
ansible-doc -s module_name  # Show snippet/example
```

**3. Enable debug logging**
```ini
# ansible.cfg
[defaults]
log_path = /var/log/ansible.log
```

**4. Community resources**
- Ansible docs: https://docs.ansible.com
- Ansible forums: https://forum.ansible.com
- Stack Overflow: [ansible] tag
- IRC: #ansible on Libera.Chat
