---
name: shell-to-ansible
description: >
  Convert shell scripts to idempotent Ansible playbooks using declarative patterns and Red Hat CoP
  best practices. Use this skill when the user asks to: "convert shell script", "bash to ansible",
  "shell to playbook", "translate script", "migrate script to ansible", "rewrite script in ansible",
  "turn this script into ansible", "ansible version of this script", or wants to transform existing
  shell automation into Ansible. Always invoke this skill for shell-to-Ansible conversion tasks.
version: 1.0.0
allowed-tools: [Read, Write, Edit, Bash, Grep]
---

# Shell-to-Ansible Conversion Skill

Convert procedural shell scripts into declarative, idempotent Ansible playbooks following Red Hat Communities of Practice standards.

## Mindset Shift: Procedural vs. Declarative

### Shell Scripts (Procedural)
- **How to do it**: Step-by-step instructions
- **Imperative**: "Install package, then configure it, then start service"
- **State unaware**: Runs all commands every time
- **Error-prone**: Partial failures leave inconsistent state

### Ansible (Declarative)
- **What should exist**: Desired end state
- **Declarative**: "Package should be installed, configured correctly, service running"
- **State aware**: Only makes necessary changes
- **Idempotent**: Safe to run repeatedly

## Conversion Process

### Step 1: Analyze the Shell Script

Identify what the script accomplishes:
1. **Packages to install**
2. **Files to create/modify**
3. **Services to manage**
4. **Users/groups to create**
5. **Permissions to set**
6. **Conditional logic**
7. **Loops and iterations**

### Step 2: Map to Ansible Modules

Replace shell commands with appropriate Ansible modules (see Module Mapping reference).

### Step 3: Make it Idempotent

Ensure the playbook can run multiple times safely:
- Use declarative modules (package, service, file)
- Add `creates`/`removes` to commands
- Use `changed_when: false` for checks
- Leverage fact-based guards

### Step 4: Add Error Handling

Replace `|| exit 1` with proper Ansible error handling:
- `failed_when` conditions
- `ignore_errors` where appropriate
- Assertions for validation

### Step 5: Organize into Roles

For complex scripts, organize into proper role structure following Red Hat CoP.

## Module Mapping

### Package Management

```bash
# Shell
yum install -y httpd
apt-get install -y apache2

# Ansible
- name: Install Apache
  ansible.builtin.package:
    name: "{{ __rolename_package_name }}"
    state: present
```

```bash
# Shell
yum update -y
apt-get update && apt-get upgrade -y

# Ansible
- name: Update all packages
  ansible.builtin.package:
    name: '*'
    state: latest
  when: rolename_update_all_packages | default(false) | bool
```

### Service Management

```bash
# Shell
systemctl enable httpd
systemctl start httpd
systemctl restart httpd

# Ansible
- name: Enable and start Apache
  ansible.builtin.service:
    name: "{{ __rolename_service_name }}"
    state: started
    enabled: true

- name: Restart Apache
  ansible.builtin.service:
    name: "{{ __rolename_service_name }}"
    state: restarted
```

### File Operations

```bash
# Shell
cp /source/file.conf /etc/app/file.conf
chmod 644 /etc/app/file.conf
chown root:root /etc/app/file.conf

# Ansible
- name: Deploy configuration file
  ansible.builtin.copy:
    src: file.conf
    dest: /etc/app/file.conf
    owner: root
    group: root
    mode: '0644'
```

```bash
# Shell
cat > /etc/app/config.conf <<EOF
setting1=value1
setting2=value2
EOF

# Ansible
- name: Create configuration file
  ansible.builtin.copy:
    content: |
      setting1=value1
      setting2=value2
    dest: /etc/app/config.conf
    owner: root
    group: root
    mode: '0644'

# Or better - use template
- name: Deploy configuration from template
  ansible.builtin.template:
    src: config.conf.j2
    dest: /etc/app/config.conf
    owner: root
    group: root
    mode: '0644'
```

```bash
# Shell
sed -i 's/^MaxClients.*/MaxClients 150/' /etc/httpd/conf/httpd.conf

# Ansible
- name: Configure MaxClients
  ansible.builtin.lineinfile:
    path: /etc/httpd/conf/httpd.conf
    regexp: '^MaxClients'
    line: 'MaxClients 150'
    state: present
```

```bash
# Shell
mkdir -p /opt/app/data
chmod 755 /opt/app/data

# Ansible
- name: Create application data directory
  ansible.builtin.file:
    path: /opt/app/data
    state: directory
    owner: root
    group: root
    mode: '0755'
```

### User and Group Management

```bash
# Shell
groupadd -r appgroup
useradd -r -g appgroup -s /sbin/nologin appuser

# Ansible
- name: Create application group
  ansible.builtin.group:
    name: appgroup
    system: true
    state: present

- name: Create application user
  ansible.builtin.user:
    name: appuser
    group: appgroup
    system: true
    shell: /sbin/nologin
    createhome: false
    state: present
```

### Downloads and Archives

```bash
# Shell
wget https://example.com/app.tar.gz -O /tmp/app.tar.gz
tar -xzf /tmp/app.tar.gz -C /opt/

# Ansible
- name: Download and extract application
  ansible.builtin.unarchive:
    src: https://example.com/app.tar.gz
    dest: /opt/
    remote_src: true
    creates: /opt/app/bin/app
```

```bash
# Shell
curl -o /usr/local/bin/app https://example.com/app
chmod +x /usr/local/bin/app

# Ansible
- name: Download application binary
  ansible.builtin.get_url:
    url: https://example.com/app
    dest: /usr/local/bin/app
    mode: '0755'
    owner: root
    group: root
```

### Conditionals

```bash
# Shell
if [ -f /etc/redhat-release ]; then
  yum install -y httpd
elif [ -f /etc/debian_version ]; then
  apt-get install -y apache2
fi

# Ansible
- name: Install Apache on RedHat
  ansible.builtin.yum:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"

- name: Install Apache on Debian
  ansible.builtin.apt:
    name: apache2
    state: present
  when: ansible_os_family == "Debian"

# Or use the generic module
- name: Install Apache (platform-agnostic)
  ansible.builtin.package:
    name: "{{ __rolename_package_name }}"
    state: present
  # Set __rolename_package_name in vars/RedHat.yml and vars/Debian.yml
```

```bash
# Shell
if [ ! -f /opt/app/.initialized ]; then
  /usr/local/bin/init-app.sh
  touch /opt/app/.initialized
fi

# Ansible
- name: Initialize application
  ansible.builtin.command: /usr/local/bin/init-app.sh
  args:
    creates: /opt/app/.initialized
```

### Loops

```bash
# Shell
for module in ssl rewrite headers; do
  a2enmod $module
done

# Ansible
- name: Enable Apache modules
  ansible.builtin.command: "a2enmod {{ item }}"
  loop:
    - ssl
    - rewrite
    - headers
  args:
    creates: "/etc/apache2/mods-enabled/{{ item }}.load"
```

```bash
# Shell
for user in alice bob charlie; do
  useradd $user
done

# Ansible
- name: Create users
  ansible.builtin.user:
    name: "{{ item }}"
    state: present
  loop:
    - alice
    - bob
    - charlie
```

### Environment Variables

```bash
# Shell
export APP_ENV=production
export APP_PORT=8080

# Ansible
- name: Run application with environment
  ansible.builtin.command: /usr/local/bin/app
  environment:
    APP_ENV: production
    APP_PORT: 8080
```

### Command Execution with Checks

```bash
# Shell
if ! httpd -t; then
  echo "Configuration test failed"
  exit 1
fi

# Ansible
- name: Validate Apache configuration
  ansible.builtin.command: httpd -t
  changed_when: false
  register: config_test
  failed_when: config_test.rc != 0
```

## Idempotency Patterns

### Pattern 1: Use Declarative Modules

```bash
# Shell (Not idempotent)
yum install -y httpd

# Ansible (Idempotent)
- name: Ensure Apache is installed
  ansible.builtin.package:
    name: httpd
    state: present
```

### Pattern 2: Use `creates` Parameter

```bash
# Shell
wget https://example.com/app.tar.gz
tar -xzf app.tar.gz

# Ansible
- name: Download and extract application
  ansible.builtin.unarchive:
    src: https://example.com/app.tar.gz
    dest: /opt/
    remote_src: true
    creates: /opt/app/bin/app  # Only runs if this doesn't exist
```

### Pattern 3: Check Before Acting

```bash
# Shell
/usr/local/bin/setup.sh

# Ansible
- name: Check if setup is needed
  ansible.builtin.stat:
    path: /var/lib/app/.setup_complete
  register: setup_status

- name: Run setup if needed
  ansible.builtin.command: /usr/local/bin/setup.sh
  when: not setup_status.stat.exists

- name: Mark setup as complete
  ansible.builtin.file:
    path: /var/lib/app/.setup_complete
    state: touch
  when: not setup_status.stat.exists
```

### Pattern 4: Use `changed_when`

```bash
# Shell (checks always report as changed)
grep -q "setting" /etc/app.conf || echo "setting=value" >> /etc/app.conf

# Ansible (proper change detection)
- name: Ensure setting is present
  ansible.builtin.lineinfile:
    path: /etc/app.conf
    line: "setting=value"
    state: present
  # Automatically only changes if line is missing
```

## Complex Conversion Example

### Before: Shell Script

```bash
#!/bin/bash
# install-web-server.sh

set -e

# Update packages
yum update -y

# Install Apache
yum install -y httpd mod_ssl

# Create application user
if ! id -u webadmin > /dev/null 2>&1; then
  useradd -r -s /sbin/nologin webadmin
fi

# Create directories
mkdir -p /var/www/myapp
chown webadmin:webadmin /var/www/myapp
chmod 755 /var/www/myapp

# Deploy configuration
cat > /etc/httpd/conf.d/myapp.conf <<EOF
<VirtualHost *:80>
  ServerName myapp.example.com
  DocumentRoot /var/www/myapp
  <Directory /var/www/myapp>
    AllowOverride All
  </Directory>
</VirtualHost>
EOF

# Enable and start services
systemctl enable httpd
systemctl start httpd

# Configure firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

echo "Installation complete"
```

### After: Ansible Playbook

```yaml
---
# install-web-server.yml

- name: Install and configure web server
  hosts: webservers
  become: true

  vars:
    app_user: webadmin
    app_document_root: /var/www/myapp
    app_server_name: myapp.example.com

  tasks:
    - name: Update all packages
      ansible.builtin.yum:
        name: '*'
        state: latest
      when: update_packages | default(false) | bool
      tags: ['packages']

    - name: Install Apache and mod_ssl
      ansible.builtin.package:
        name:
          - httpd
          - mod_ssl
        state: present
      tags: ['packages']

    - name: Create application user
      ansible.builtin.user:
        name: "{{ app_user }}"
        system: true
        shell: /sbin/nologin
        createhome: false
        state: present
      tags: ['users']

    - name: Create application directory
      ansible.builtin.file:
        path: "{{ app_document_root }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'
      tags: ['filesystem']

    - name: Deploy virtual host configuration
      ansible.builtin.copy:
        content: |
          <VirtualHost *:80>
            ServerName {{ app_server_name }}
            DocumentRoot {{ app_document_root }}
            <Directory {{ app_document_root }}>
              AllowOverride All
            </Directory>
          </VirtualHost>
        dest: /etc/httpd/conf.d/myapp.conf
        owner: root
        group: root
        mode: '0644'
      notify: Reload Apache
      tags: ['configuration']

    - name: Enable and start Apache service
      ansible.builtin.service:
        name: httpd
        state: started
        enabled: true
      tags: ['services']

    - name: Configure firewall for HTTP/HTTPS
      ansible.posix.firewalld:
        service: "{{ item }}"
        permanent: true
        state: enabled
        immediate: true
      loop:
        - http
        - https
      tags: ['firewall']

  handlers:
    - name: Reload Apache
      ansible.builtin.service:
        name: httpd
        state: reloaded
```

## Better: Convert to Role

For production use, organize as a role:

```yaml
# playbook.yml
---
- name: Install web application
  hosts: webservers
  become: true

  roles:
    - role: company.web.myapp_install
      myapp_install_server_name: myapp.example.com
      myapp_install_document_root: /var/www/myapp
```

## Conversion Checklist

When converting a shell script to Ansible:

- [ ] Identify all operations (install, configure, deploy, manage)
- [ ] Map shell commands to Ansible modules
- [ ] Replace all `yum`/`apt` with `package` module
- [ ] Replace all `systemctl` with `service` module
- [ ] Replace file operations with `copy`, `template`, `lineinfile`, `file`
- [ ] Convert loops to Ansible `loop` or `with_items`
- [ ] Convert conditionals to `when` clauses
- [ ] Add `creates` to commands that should run once
- [ ] Use `changed_when: false` for check/validation commands
- [ ] Move service restarts to handlers
- [ ] Add proper error handling with `failed_when`
- [ ] Make all operations idempotent
- [ ] Test by running twice - second run should show no changes
- [ ] Add tags for selective execution
- [ ] Document variables if creating a role
- [ ] Run ansible-lint for validation

## Common Pitfalls

### 1. Directly Using `shell` Module

```yaml
# Bad - just wraps shell script in Ansible
- name: Install Apache
  ansible.builtin.shell: |
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd

# Good - uses proper modules
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

### 2. Hardcoding Platform-Specific Commands

```yaml
# Bad - only works on RedHat
- name: Install package
  ansible.builtin.command: yum install -y httpd

# Good - platform-agnostic
- name: Install Apache
  ansible.builtin.package:
    name: "{{ __rolename_package_name }}"
    state: present
# Set __rolename_package_name in vars/RedHat.yml (httpd) and vars/Debian.yml (apache2)
```

### 3. Not Using Handlers

```yaml
# Bad - always restarts
- name: Deploy config
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf

- name: Restart Apache
  ansible.builtin.service:
    name: httpd
    state: restarted

# Good - only restarts if config changed
- name: Deploy config
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf
  notify: Restart Apache

# In handlers/main.yml:
# - name: Restart Apache
#   ansible.builtin.service:
#     name: httpd
#     state: restarted
```

## Validation

After conversion, validate the playbook:

```bash
# Syntax check
ansible-playbook --syntax-check playbook.yml

# Lint
ansible-lint --profile moderate playbook.yml

# Dry run
ansible-playbook --check playbook.yml

# Run once
ansible-playbook playbook.yml

# Run again - should show no changes (idempotence test)
ansible-playbook playbook.yml
```

When asked to convert a shell script to Ansible, analyze the script operations, map to appropriate Ansible modules, ensure idempotency, and produce a well-structured playbook or role following Red Hat CoP standards.
