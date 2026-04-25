# Idempotency Guide - Red Hat CoP Standards

Idempotency is a fundamental requirement for all Ansible roles. This guide explains what it means and how to achieve it.

## What is Idempotency?

**Idempotent:** An operation that produces the same result whether executed once or multiple times.

In Ansible terms: Running a playbook/role multiple times on the same system should produce the same end state without making unnecessary changes after the first run.

## Why Idempotency Matters

1. **Safety:** Re-running automation won't break working systems
2. **Reliability:** Predictable behavior regardless of current system state
3. **Efficiency:** Only changes what needs changing
4. **Debugging:** Can safely re-run to verify fixes
5. **CI/CD:** Can be part of continuous deployment pipelines

## Testing Idempotency

Use Molecule to verify idempotency:

```bash
# Run role once
molecule converge

# Run again - should report ZERO changes
molecule idempotence

# Expected output:
# PLAY RECAP *********************************************************************
# instance                   : ok=10   changed=0    unreachable=0    failed=0
```

**If `changed` is not 0 on the second run, the role is NOT idempotent.**

## Achieving Idempotency

### 1. Use Declarative Modules

Declarative modules describe desired state, not steps to achieve it.

```yaml
# Good - declarative, naturally idempotent
- name: Ensure Apache is installed
  ansible.builtin.package:
    name: httpd
    state: present
  # First run: installs httpd, reports changed
  # Second run: httpd already present, reports ok

- name: Ensure configuration file is present
  ansible.builtin.copy:
    src: httpd.conf
    dest: /etc/httpd/conf/httpd.conf
    mode: '0644'
  # Only reports changed if file differs or doesn't exist

# Bad - imperative, always reports changed
- name: Install Apache
  ansible.builtin.shell: yum install -y httpd
  # Always executes, always reports changed, even if already installed
```

### Commonly Used Idempotent Modules

- `ansible.builtin.package` - Package management
- `ansible.builtin.service` - Service management
- `ansible.builtin.copy` - File copying
- `ansible.builtin.template` - Template rendering
- `ansible.builtin.file` - File/directory/symlink management
- `ansible.builtin.lineinfile` - Line-in-file editing
- `ansible.builtin.blockinfile` - Block-in-file editing
- `ansible.builtin.user` - User account management
- `ansible.builtin.group` - Group management
- `ansible.builtin.yum`/`apt` - Platform-specific package management

### 2. Control `changed` Status with `changed_when`

Some commands are idempotent in effect but always report "changed" in Ansible.

```yaml
# Example: Configuration validation
- name: Validate Apache configuration
  ansible.builtin.command: apachectl configtest
  changed_when: false  # Checking doesn't change anything
  register: config_validation
  failed_when: config_validation.rc != 0

# Example: Information gathering
- name: Get current Apache version
  ansible.builtin.command: httpd -v
  register: apache_version
  changed_when: false  # Reading version doesn't change system

# Example: Conditional changed status
- name: Reload systemd daemon if needed
  ansible.builtin.command: systemctl daemon-reload
  register: systemd_reload
  changed_when: systemd_reload.rc == 0
  failed_when: systemd_reload.rc != 0
```

### 3. Use `creates` and `removes` Parameters

For `command` and `shell` modules, use `creates` or `removes` to make them idempotent.

```yaml
# Good - only runs if marker file doesn't exist
- name: Initialize database
  ansible.builtin.shell: /usr/local/bin/init-database.sh
  args:
    creates: /var/lib/database/.initialized
  # First run: runs script, creates marker file
  # Subsequent runs: skipped because marker exists

# Good - only runs if directory exists
- name: Clean up temporary directory
  ansible.builtin.command: rm -rf /tmp/install_temp
  args:
    removes: /tmp/install_temp
  # Only runs if directory exists

# Bad - always runs
- name: Initialize database
  ansible.builtin.shell: /usr/local/bin/init-database.sh
  # Runs every time, may cause errors or duplicate data
```

### 4. Fact-Based Guards

Check current state before making changes:

```yaml
# Gather current state
- name: Check if application is already installed
  ansible.builtin.stat:
    path: /opt/myapp/bin/myapp
  register: __rolename_app_check

- name: Check application version
  ansible.builtin.command: /opt/myapp/bin/myapp --version
  register: __rolename_app_version
  changed_when: false
  when: __rolename_app_check.stat.exists

# Make decisions based on current state
- name: Download and install application
  ansible.builtin.get_url:
    url: "{{ rolename_app_url }}"
    dest: /opt/myapp/bin/myapp
    mode: '0755'
  when: >-
    not __rolename_app_check.stat.exists or
    rolename_app_version not in __rolename_app_version.stdout

# Only performs action if needed
```

### 5. Configuration File Management

Use templates with proper comparison:

```yaml
# Good - template module compares content
- name: Deploy Apache configuration
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf
    owner: root
    group: root
    mode: '0644'
  notify: Reload Apache
  # Only reports changed if file content differs

# Good - copy module with backup
- name: Deploy static configuration
  ansible.builtin.copy:
    src: httpd.conf
    dest: /etc/httpd/conf/httpd.conf
    owner: root
    group: root
    mode: '0644'
    backup: true
  notify: Reload Apache
  # Creates backup only when making changes
```

### 6. Line-in-File Operations

Use `lineinfile` and `blockinfile` for configuration snippets:

```yaml
# Good - idempotent line management
- name: Ensure MaxClients is configured
  ansible.builtin.lineinfile:
    path: /etc/httpd/conf/httpd.conf
    regexp: '^MaxClients'
    line: 'MaxClients {{ apache_install_max_clients }}'
    state: present
  # Only changes if line differs or missing

# Good - idempotent block management
- name: Add custom configuration block
  ansible.builtin.blockinfile:
    path: /etc/httpd/conf.d/custom.conf
    block: |
      <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
      </Directory>
    marker: "# {mark} ANSIBLE MANAGED BLOCK"
    create: true
  # Only changes if block differs or missing
```

## Common Idempotency Pitfalls

### 1. Always-Changing Shell Commands

**Problem:**
```yaml
# Bad - always reports changed
- name: Configure system
  ansible.builtin.shell: |
    echo "Configuring..." >> /var/log/install.log
    /usr/local/bin/setup.sh
```

**Solution:**
```yaml
# Good - use creates/removes or changed_when
- name: Run setup if not completed
  ansible.builtin.shell: /usr/local/bin/setup.sh
  args:
    creates: /var/lib/app/.setup_complete
  register: setup_result

- name: Log setup completion
  ansible.builtin.lineinfile:
    path: /var/log/install.log
    line: "Setup completed: {{ ansible_date_time.iso8601 }}"
    create: true
  when: setup_result is changed
```

### 2. Timestamp-Based Changes

**Problem:**
```yaml
# Bad - always reports changed due to timestamp
- name: Deploy config with timestamp
  ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config
  # Template contains: "Generated: {{ ansible_date_time.iso8601 }}"
```

**Solution:**
```yaml
# Good - remove dynamic timestamps from config content
- name: Deploy config without timestamp
  ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config
  # Template contains: "Generated: {{ ansible_managed }}"
  # ansible_managed is set in ansible.cfg, consistent across runs
```

### 3. Incorrect File Permissions

**Problem:**
```yaml
# Bad - file module without explicit permissions
- name: Create directory
  ansible.builtin.file:
    path: /opt/app
    state: directory
  # Permissions may vary based on umask
```

**Solution:**
```yaml
# Good - explicit permissions
- name: Create directory
  ansible.builtin.file:
    path: /opt/app
    state: directory
    owner: root
    group: root
    mode: '0755'
  # Consistent permissions every time
```

### 4. Downloading Without Checksum

**Problem:**
```yaml
# Bad - always re-downloads
- name: Download application
  ansible.builtin.get_url:
    url: https://example.com/app.tar.gz
    dest: /tmp/app.tar.gz
  # May re-download even if file hasn't changed
```

**Solution:**
```yaml
# Good - use checksum
- name: Download application
  ansible.builtin.get_url:
    url: https://example.com/app.tar.gz
    dest: /tmp/app.tar.gz
    checksum: "sha256:abc123..."
  # Only downloads if checksum differs

# Or use force: false
- name: Download application once
  ansible.builtin.get_url:
    url: https://example.com/app.tar.gz
    dest: /tmp/app.tar.gz
    force: false
  # Never re-downloads if file exists
```

### 5. Service Restart Loops

**Problem:**
```yaml
# Bad - always restarts service
- name: Deploy config
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf

- name: Restart service
  ansible.builtin.service:
    name: app
    state: restarted
  # Always restarts, even if config didn't change
```

**Solution:**
```yaml
# Good - use handlers
- name: Deploy config
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf
  notify: Restart app service

# In handlers/main.yml:
# - name: Restart app service
#   ansible.builtin.service:
#     name: app
#     state: restarted
# Only restarts if config actually changed
```

## Idempotency Patterns

### Pattern 1: Check-Then-Act

```yaml
- name: Check current state
  ansible.builtin.stat:
    path: /opt/app/version.txt
  register: version_file

- name: Read current version
  ansible.builtin.slurp:
    path: /opt/app/version.txt
  register: current_version
  when: version_file.stat.exists

- name: Upgrade application
  ansible.builtin.unarchive:
    src: "{{ app_url }}"
    dest: /opt/app
    remote_src: true
  when: >-
    not version_file.stat.exists or
    (current_version.content | b64decode | trim) != app_version
```

### Pattern 2: Marker Files

```yaml
- name: Run one-time migration
  ansible.builtin.command: /usr/local/bin/migrate-database.sh
  args:
    creates: /var/lib/app/.migration_v2_complete

- name: Create migration marker
  ansible.builtin.file:
    path: /var/lib/app/.migration_v2_complete
    state: touch
    mode: '0644'
  when: migration is changed
```

### Pattern 3: Package Version Pinning

```yaml
# Good - specific version
- name: Install specific Apache version
  ansible.builtin.package:
    name: "httpd-{{ apache_install_version }}"
    state: present

# Also good - state: present is idempotent
- name: Ensure Apache is installed
  ansible.builtin.package:
    name: httpd
    state: present
  # Installs if missing, skips if present

# Be cautious with state: latest
- name: Keep Apache at latest version
  ansible.builtin.package:
    name: httpd
    state: latest
  # May upgrade unexpectedly, but is still idempotent
```

## Verifying Idempotency

### Manual Verification

```bash
# Run playbook twice
ansible-playbook -i inventory site.yml
ansible-playbook -i inventory site.yml

# Second run should show:
# - No "changed" tasks (except handlers if needed)
# - Same number of "ok" tasks
# - Zero "failed" tasks
```

### Molecule Verification

```bash
# Run full test including idempotence
molecule test

# Or just test idempotence
molecule converge
molecule idempotence

# Expected output from idempotence:
# Idempotence completed successfully.
```

### CI/CD Integration

```yaml
# .gitlab-ci.yml example
test_idempotence:
  script:
    - molecule create
    - molecule converge
    - molecule converge | tee /tmp/second_run.log
    - >
      grep -q 'changed=0' /tmp/second_run.log ||
      (echo "Role is not idempotent" && exit 1)
    - molecule destroy
```

## Exceptions to Idempotency

Some operations are inherently non-idempotent:

1. **Generating random values**
   ```yaml
   # Always generates new value
   - name: Generate random password
     ansible.builtin.set_fact:
       random_password: "{{ lookup('password', '/dev/null') }}"
   ```

2. **Timestamp-sensitive operations**
   ```yaml
   # Always reports current time
   - name: Record deployment time
     ansible.builtin.debug:
       msg: "Deployed at {{ ansible_date_time.iso8601 }}"
   ```

3. **Intentional forced updates**
   ```yaml
   # Intentionally always runs
   - name: Force cache update
     ansible.builtin.package:
       update_cache: true
     changed_when: false  # Mark as not changing to avoid confusion
   ```

**Document these exceptions** in role README under "Idempotency" section.

## Checklist

- [ ] All tasks use declarative modules when possible
- [ ] Commands use `creates`/`removes` where applicable
- [ ] Information-gathering tasks use `changed_when: false`
- [ ] File operations specify explicit permissions
- [ ] Templates don't include dynamic timestamps
- [ ] Service restarts use handlers, not direct tasks
- [ ] File downloads use checksums or `force: false`
- [ ] `molecule idempotence` passes with 0 changes
- [ ] Manual re-run shows no unnecessary changes
- [ ] Non-idempotent operations are documented

## Quick Reference

| Module | Idempotent by Default? | Notes |
|--------|------------------------|-------|
| `package` | Yes | Only installs if not present |
| `service` | Yes | Only changes if state differs |
| `copy` | Yes | Compares content |
| `template` | Yes | Compares rendered output |
| `file` | Yes | Checks current state |
| `lineinfile` | Yes | Checks if line exists/matches |
| `command` | No | Use `creates`/`removes` or `changed_when` |
| `shell` | No | Use `creates`/`removes` or `changed_when` |
| `get_url` | Partial | Use checksum or `force: false` |
| `unarchive` | Partial | Use `creates` or version checks |
