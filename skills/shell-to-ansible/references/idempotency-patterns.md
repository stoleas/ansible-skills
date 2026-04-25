# Idempotency Patterns for Shell-to-Ansible Conversion

When converting shell scripts to Ansible, ensuring idempotency is critical. This guide covers patterns to make converted playbooks idempotent.

## Pattern 1: Use Declarative Modules

**Shell (Not Idempotent):**
```bash
yum install -y httpd
systemctl start httpd
```

**Ansible (Idempotent):**
```yaml
- name: Ensure Apache is installed
  ansible.builtin.package:
    name: httpd
    state: present

- name: Ensure Apache is running
  ansible.builtin.service:
    name: httpd
    state: started
    enabled: true
```

## Pattern 2: Use `creates` and `removes`

For scripts that should only run once or when specific files exist/don't exist.

**Shell:**
```bash
/usr/local/bin/initialize-database.sh
```

**Ansible with `creates`:**
```yaml
- name: Initialize database if not already done
  ansible.builtin.command: /usr/local/bin/initialize-database.sh
  args:
    creates: /var/lib/database/.initialized
```

**Shell:**
```bash
rm -rf /tmp/old_cache
```

**Ansible with `removes`:**
```yaml
- name: Remove old cache if it exists
  ansible.builtin.command: rm -rf /tmp/old_cache
  args:
    removes: /tmp/old_cache
```

## Pattern 3: Check-Then-Act

Check current state before taking action.

**Shell:**
```bash
if [ ! -f /opt/app/version.txt ] || [ "$(cat /opt/app/version.txt)" != "2.0" ]; then
  wget https://example.com/app-2.0.tar.gz
  tar -xzf app-2.0.tar.gz -C /opt/app
  echo "2.0" > /opt/app/version.txt
fi
```

**Ansible:**
```yaml
- name: Check current application version
  ansible.builtin.slurp:
    path: /opt/app/version.txt
  register: current_version
  ignore_errors: true

- name: Download and install application if needed
  ansible.builtin.unarchive:
    src: https://example.com/app-2.0.tar.gz
    dest: /opt/app
    remote_src: true
  when: >-
    current_version is failed or
    (current_version.content | b64decode | trim) != "2.0"

- name: Update version file
  ansible.builtin.copy:
    content: "2.0"
    dest: /opt/app/version.txt
  when: >-
    current_version is failed or
    (current_version.content | b64decode | trim) != "2.0"
```

## Pattern 4: Use `changed_when` for Info Commands

Commands that gather information don't change the system.

**Shell:**
```bash
if ! apachectl configtest; then
  echo "Configuration invalid"
  exit 1
fi
```

**Ansible:**
```yaml
- name: Validate Apache configuration
  ansible.builtin.command: apachectl configtest
  changed_when: false
  register: config_test
  failed_when: config_test.rc != 0
```

## Pattern 5: File Content Comparison

Replace file operations that always rewrite files with content-aware modules.

**Shell (Always rewrites):**
```bash
cat > /etc/app/config <<EOF
setting1=value1
setting2=value2
EOF
```

**Ansible (Only changes if content differs):**
```yaml
- name: Deploy configuration
  ansible.builtin.copy:
    content: |
      setting1=value1
      setting2=value2
    dest: /etc/app/config
    owner: root
    group: root
    mode: '0644'
```

## Pattern 6: Line-in-File Operations

Instead of always appending or using sed.

**Shell:**
```bash
if ! grep -q "^MaxClients 150" /etc/httpd/conf/httpd.conf; then
  sed -i 's/^MaxClients.*/MaxClients 150/' /etc/httpd/conf/httpd.conf
fi
```

**Ansible:**
```yaml
- name: Configure MaxClients
  ansible.builtin.lineinfile:
    path: /etc/httpd/conf/httpd.conf
    regexp: '^MaxClients'
    line: 'MaxClients 150'
    state: present
```

## Pattern 7: Marker Files

Use marker files to track one-time operations.

**Shell:**
```bash
if [ ! -f /var/lib/app/.migration_v2_complete ]; then
  /usr/local/bin/migrate-database.sh
  touch /var/lib/app/.migration_v2_complete
fi
```

**Ansible:**
```yaml
- name: Check if migration v2 is complete
  ansible.builtin.stat:
    path: /var/lib/app/.migration_v2_complete
  register: migration_status

- name: Run database migration v2
  ansible.builtin.command: /usr/local/bin/migrate-database.sh
  when: not migration_status.stat.exists
  register: migration_result

- name: Create migration marker
  ansible.builtin.file:
    path: /var/lib/app/.migration_v2_complete
    state: touch
    mode: '0644'
  when: migration_result is changed
```

## Pattern 8: Handlers for Service Restarts

Only restart services when configuration changes.

**Shell (Always restarts):**
```bash
cp /source/httpd.conf /etc/httpd/conf/httpd.conf
systemctl restart httpd
```

**Ansible (Only restarts if config changed):**
```yaml
- name: Deploy Apache configuration
  ansible.builtin.copy:
    src: httpd.conf
    dest: /etc/httpd/conf/httpd.conf
    owner: root
    group: root
    mode: '0644'
  notify: Restart Apache

# In handlers/main.yml:
# - name: Restart Apache
#   ansible.builtin.service:
#     name: httpd
#     state: restarted
```

## Pattern 9: Conditional Execution Based on Facts

Use gathered facts to make decisions.

**Shell:**
```bash
if [ -f /etc/redhat-release ]; then
  yum install -y httpd
elif [ -f /etc/debian_version ]; then
  apt-get install -y apache2
fi
```

**Ansible:**
```yaml
- name: Install Apache (platform-agnostic)
  ansible.builtin.package:
    name: "{{ __rolename_package_name }}"
    state: present

# Define __rolename_package_name in vars/RedHat.yml and vars/Debian.yml
```

## Pattern 10: Download with Checksum

Prevent unnecessary downloads.

**Shell:**
```bash
wget https://example.com/app.tar.gz -O /tmp/app.tar.gz
```

**Ansible:**
```yaml
- name: Download application with checksum
  ansible.builtin.get_url:
    url: https://example.com/app.tar.gz
    dest: /tmp/app.tar.gz
    checksum: "sha256:abc123def456..."
# Only downloads if checksum doesn't match

# Or use force: false to never re-download
- name: Download application once
  ansible.builtin.get_url:
    url: https://example.com/app.tar.gz
    dest: /tmp/app.tar.gz
    force: false
```

## Common Anti-Patterns

### Anti-Pattern 1: Wrapping Shell Script in Ansible

**Bad:**
```yaml
- name: Run installation script
  ansible.builtin.shell: |
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
```

**Good:**
```yaml
- name: Install Apache
  ansible.builtin.package:
    name: httpd
    state: present

- name: Enable and start Apache
  ansible.builtin.service:
    name: httpd
    state: started
    enabled: true
```

### Anti-Pattern 2: Always Running Commands

**Bad:**
```yaml
- name: Configure system
  ansible.builtin.command: /usr/local/bin/setup.sh
# Runs every time
```

**Good:**
```yaml
- name: Configure system if needed
  ansible.builtin.command: /usr/local/bin/setup.sh
  args:
    creates: /var/lib/system/.configured
```

### Anti-Pattern 3: Ignoring Module Parameters

**Bad:**
```yaml
- name: Create directory
  ansible.builtin.command: mkdir -p /opt/app
  ignore_errors: true
```

**Good:**
```yaml
- name: Create directory
  ansible.builtin.file:
    path: /opt/app
    state: directory
    owner: root
    group: root
    mode: '0755'
```

## Testing Idempotency

After conversion, always test:

```bash
# Run playbook twice
ansible-playbook playbook.yml
ansible-playbook playbook.yml

# Second run should show:
# - changed=0 (no changes)
# - Same number of ok tasks
# - No failures
```

Or use Molecule:

```bash
molecule converge
molecule idempotence  # Should report 0 changes
```

## Quick Checklist

- [ ] Use declarative modules (package, service, file, copy, template)
- [ ] Add `creates`/`removes` to commands that should run conditionally
- [ ] Use `changed_when: false` for information-gathering tasks
- [ ] Replace direct file writes with copy/template modules
- [ ] Use lineinfile/blockinfile for configuration snippets
- [ ] Move service restarts to handlers
- [ ] Use fact-based conditionals instead of shell if/then
- [ ] Add marker files for one-time operations
- [ ] Use checksum or force: false for downloads
- [ ] Test by running playbook twice - second run should show no changes
