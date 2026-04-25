---
name: ansible-interactive
description: >
  Interactive step-by-step guided Ansible development workflow from environment setup
  through playbook deployment. Use this skill when the user asks to: "guide me through ansible",
  "interactive ansible setup", "step by step ansible", "walk me through ansible development",
  "help me start with ansible", "ansible project setup", or wants hands-on guided assistance
  with Ansible development. Always invoke this skill for interactive, beginner-friendly
  Ansible workflows.
version: 1.0.0
allowed-tools: [Write, Read, Bash, Glob]
---

# Ansible Interactive Development Skill

Provide step-by-step guided Ansible development workflow, from initial environment setup through playbook deployment. This skill offers interactive assistance at every stage with validation and troubleshooting.

## What is Interactive Ansible Development?

**Interactive development** breaks complex Ansible projects into manageable steps with immediate feedback and validation at each stage.

**Key Benefits:**
- **Guided workflow** - Step-by-step progression with clear objectives
- **Immediate validation** - Test each step before moving forward
- **Error prevention** - Catch issues early in the development process
- **Learning-focused** - Understand concepts while building
- **Production-ready** - Follow Red Hat CoP standards throughout

**Who is this for?**
- Ansible beginners starting their first project
- Teams transitioning to Ansible from shell scripts
- Developers wanting guided best practices
- Anyone preferring incremental, validated development

## Interactive Development Workflow

### Phase 1: Environment Analysis

**Objective:** Understand current environment and requirements

**Steps:**

1. **Assess Current State**
   ```bash
   # Check Ansible installation
   ansible --version
   
   # Check Python version
   python3 --version
   
   # Check SSH availability
   ssh -V
   ```

2. **Define Requirements**
   - What systems will you manage? (servers, network devices, cloud)
   - What tasks need automation? (deployment, configuration, patching)
   - What's the target environment? (development, staging, production)
   - How many hosts? (affects inventory structure)
   - What credentials are needed? (SSH keys, passwords, API tokens)

3. **Validate Prerequisites**
   ```bash
   # Verify connectivity to target hosts
   ping -c 3 target-host
   
   # Test SSH access (without Ansible)
   ssh user@target-host "echo 'Connection successful'"
   
   # Check sudo/privilege escalation
   ssh user@target-host "sudo -n true && echo 'Passwordless sudo configured'"
   ```

**Interactive Questions:**
- "What are you trying to automate?"
- "How many hosts will you manage?"
- "Do you have SSH access to all target systems?"
- "Are you managing Linux, Windows, or network devices?"

**Validation:** All prerequisites met before proceeding.

---

### Phase 2: Project Initialization

**Objective:** Create well-structured Ansible project following Red Hat CoP

**Steps:**

1. **Create Project Structure**
   ```bash
   # Initialize project directory
   mkdir -p my-ansible-project
   cd my-ansible-project
   
   # Create standard structure
   mkdir -p {inventory,group_vars,host_vars,roles,playbooks,files,templates}
   
   # Create configuration file
   touch ansible.cfg
   
   # Initialize git repository
   git init
   ```

2. **Configure ansible.cfg**
   ```ini
   [defaults]
   inventory = inventory/hosts.yml
   roles_path = roles
   host_key_checking = False
   retry_files_enabled = False
   stdout_callback = yaml
   callbacks_enabled = ansible.posix.profile_tasks
   interpreter_python = auto_silent
   
   [privilege_escalation]
   become = False
   become_method = sudo
   
   [ssh_connection]
   pipelining = True
   ssh_args = -o ControlMaster=auto -o ControlPersist=60s
   ```

3. **Create Initial Inventory**
   ```yaml
   # inventory/hosts.yml
   ---
   all:
     children:
       development:
         hosts:
           dev-server-01:
             ansible_host: 192.168.1.10
             ansible_user: ansible
       
       production:
         hosts:
           prod-server-01:
             ansible_host: 192.168.1.20
             ansible_user: ansible
   ```

**Interactive Questions:**
- "What's your project name?"
- "Which hosts belong to which groups?"
- "What connection method will you use (SSH, WinRM, local)?"

**Validation:**
```bash
# Verify project structure
tree -L 2

# Validate ansible.cfg syntax
ansible-config dump --only-changed

# Test inventory parsing
ansible-inventory --list -i inventory/hosts.yml
```

---

### Phase 3: Connectivity Testing

**Objective:** Verify Ansible can connect to all managed hosts

**Steps:**

1. **Test Basic Connectivity**
   ```bash
   # Ping all hosts
   ansible all -m ping
   
   # Expected output:
   # dev-server-01 | SUCCESS => {
   #     "changed": false,
   #     "ping": "pong"
   # }
   ```

2. **Gather Facts**
   ```bash
   # Collect system information
   ansible all -m setup
   
   # Filter specific facts
   ansible all -m setup -a "filter=ansible_distribution*"
   ```

3. **Test Privilege Escalation**
   ```bash
   # Test sudo access
   ansible all -m shell -a "whoami" --become
   
   # Expected: root
   ```

4. **Validate Connectivity Report**
   ```bash
   # Create connectivity report
   ansible all -m setup --tree /tmp/facts
   
   # Review gathered facts
   cat /tmp/facts/dev-server-01
   ```

**Interactive Troubleshooting:**

**Issue: Connection refused**
```bash
# Check host is reachable
ping target-host

# Verify SSH port
nmap -p 22 target-host

# Test SSH directly
ssh -vvv user@target-host
```

**Issue: Authentication failed**
```bash
# Verify SSH key
ssh-add -l

# Test key-based auth
ssh -i ~/.ssh/id_rsa user@target-host

# Check authorized_keys
ssh user@target-host "cat ~/.ssh/authorized_keys"
```

**Issue: Sudo password required**
```yaml
# Update inventory with become password
all:
  vars:
    ansible_become_password: "{{ lookup('env', 'ANSIBLE_BECOME_PASSWORD') }}"
```

**Validation:** All hosts respond successfully to `ansible all -m ping`

---

### Phase 4: First Playbook (Simple Task)

**Objective:** Create and run a simple playbook to validate workflow

**Steps:**

1. **Create Simple Playbook**
   ```yaml
   # playbooks/test_connectivity.yml
   ---
   - name: Test connectivity and gather information
     hosts: all
     gather_facts: yes
     
     tasks:
       - name: Display hostname
         ansible.builtin.debug:
           msg: "Hostname: {{ ansible_hostname }}"
       
       - name: Display OS distribution
         ansible.builtin.debug:
           msg: "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
       
       - name: Check uptime
         ansible.builtin.command: uptime
         register: uptime_result
         changed_when: false
       
       - name: Display uptime
         ansible.builtin.debug:
           msg: "{{ uptime_result.stdout }}"
   ```

2. **Validate Syntax**
   ```bash
   # Check playbook syntax
   ansible-playbook playbooks/test_connectivity.yml --syntax-check
   ```

3. **Run in Check Mode**
   ```bash
   # Dry run (no changes)
   ansible-playbook playbooks/test_connectivity.yml --check
   ```

4. **Execute Playbook**
   ```bash
   # Run the playbook
   ansible-playbook playbooks/test_connectivity.yml
   ```

5. **Review Output**
   - All tasks completed successfully?
   - Any warnings or deprecation notices?
   - All hosts responded?

**Interactive Questions:**
- "Did all tasks complete successfully?"
- "Do you see any warnings that need addressing?"
- "Are the gathered facts what you expected?"

**Validation:** Playbook runs without errors on all hosts.

---

### Phase 5: Incremental Feature Addition

**Objective:** Add features incrementally with validation at each step

**Example: Package Installation**

1. **Single Task Playbook**
   ```yaml
   # playbooks/install_package.yml
   ---
   - name: Install package
     hosts: development
     become: yes
     
     tasks:
       - name: Install vim
         ansible.builtin.package:
           name: vim
           state: present
   ```

2. **Test and Validate**
   ```bash
   # Check mode first
   ansible-playbook playbooks/install_package.yml --check
   
   # Run on development only
   ansible-playbook playbooks/install_package.yml --limit development
   
   # Verify installation
   ansible development -m shell -a "which vim"
   ```

3. **Add Idempotency Test**
   ```bash
   # Run twice - should show no changes on second run
   ansible-playbook playbooks/install_package.yml
   ansible-playbook playbooks/install_package.yml  # Should show "ok" not "changed"
   ```

4. **Expand with Variables**
   ```yaml
   # playbooks/install_package.yml
   ---
   - name: Install package
     hosts: development
     become: yes
     
     vars:
       packages_to_install:
         - vim
         - git
         - curl
     
     tasks:
       - name: Install packages
         ansible.builtin.package:
           name: "{{ item }}"
           state: present
         loop: "{{ packages_to_install }}"
   ```

5. **Move Variables to Group Vars**
   ```yaml
   # group_vars/development.yml
   ---
   packages_to_install:
     - vim
     - git
     - curl
     - htop
   
   # group_vars/production.yml
   ---
   packages_to_install:
     - vim
     - git
   ```

**Interactive Questions:**
- "What package do you need to install?"
- "Should this apply to all hosts or specific groups?"
- "Do different environments need different packages?"

**Validation:** Package installed, idempotency verified, variables externalized.

---

### Phase 6: Configuration Management

**Objective:** Manage configuration files with templates

**Steps:**

1. **Create Configuration Template**
   ```jinja2
   {# templates/nginx.conf.j2 #}
   user {{ nginx_user }};
   worker_processes {{ nginx_worker_processes }};
   
   events {
       worker_connections {{ nginx_worker_connections }};
   }
   
   http {
       server {
           listen {{ nginx_port }};
           server_name {{ ansible_hostname }};
           
           location / {
               root {{ nginx_document_root }};
           }
       }
   }
   ```

2. **Define Variables**
   ```yaml
   # group_vars/all.yml
   ---
   nginx_user: nginx
   nginx_worker_processes: auto
   nginx_worker_connections: 1024
   nginx_port: 80
   nginx_document_root: /var/www/html
   ```

3. **Create Playbook**
   ```yaml
   # playbooks/configure_nginx.yml
   ---
   - name: Configure Nginx
     hosts: web_servers
     become: yes
     
     tasks:
       - name: Deploy Nginx configuration
         ansible.builtin.template:
           src: templates/nginx.conf.j2
           dest: /etc/nginx/nginx.conf
           owner: root
           group: root
           mode: '0644'
           validate: nginx -t -c %s
         notify: Reload nginx
     
     handlers:
       - name: Reload nginx
         ansible.builtin.service:
           name: nginx
           state: reloaded
   ```

4. **Test Configuration**
   ```bash
   # Check mode to preview changes
   ansible-playbook playbooks/configure_nginx.yml --check --diff
   
   # Review diff output
   # Apply changes
   ansible-playbook playbooks/configure_nginx.yml
   ```

**Interactive Questions:**
- "What configuration file needs management?"
- "What values should be configurable?"
- "Do different environments need different settings?"

**Validation:** Configuration deployed, syntax validated, service reloaded.

---

### Phase 7: Role Development

**Objective:** Convert playbook tasks into reusable roles

**Steps:**

1. **Create Role Structure**
   ```bash
   ansible-galaxy role init roles/nginx_install
   ```

2. **Move Tasks to Role**
   ```yaml
   # roles/nginx_install/tasks/main.yml
   ---
   - name: Install Nginx
     ansible.builtin.package:
       name: nginx
       state: present
   
   - name: Deploy configuration
     ansible.builtin.template:
       src: nginx.conf.j2
       dest: /etc/nginx/nginx.conf
       validate: nginx -t -c %s
     notify: Reload nginx
   
   - name: Ensure Nginx is running
     ansible.builtin.service:
       name: nginx
       state: started
       enabled: yes
   ```

3. **Move Variables to Defaults**
   ```yaml
   # roles/nginx_install/defaults/main.yml
   ---
   nginx_install_user: nginx
   nginx_install_worker_processes: auto
   nginx_install_port: 80
   ```

4. **Move Template to Role**
   ```bash
   mv templates/nginx.conf.j2 roles/nginx_install/templates/
   ```

5. **Create Type Playbook**
   ```yaml
   # playbooks/web_server.yml
   ---
   - name: Configure web server type
     hosts: web_servers
     become: yes
     
     roles:
       - role: nginx_install
         tags: ['nginx', 'web']
   ```

6. **Test Role**
   ```bash
   # Run the role
   ansible-playbook playbooks/web_server.yml
   
   # Test with tags
   ansible-playbook playbooks/web_server.yml --tags nginx
   ```

**Interactive Questions:**
- "What functionality should this role provide?"
- "What should be configurable vs. hardcoded?"
- "Will this role be reused across projects?"

**Validation:** Role structure correct, playbook uses role, all tests pass.

---

### Phase 8: Testing and Validation

**Objective:** Implement testing for reliability

**Steps:**

1. **Install Testing Tools**
   ```bash
   pip install ansible-lint molecule molecule-plugins[podman]
   ```

2. **Lint Playbooks**
   ```bash
   # Run ansible-lint
   ansible-lint playbooks/web_server.yml
   
   # Fix any issues
   # Re-run until clean
   ```

3. **Initialize Molecule**
   ```bash
   cd roles/nginx_install
   molecule init scenario
   ```

4. **Run Molecule Tests**
   ```bash
   # Test role in container
   molecule test
   
   # Step-by-step testing
   molecule create    # Create test instance
   molecule converge  # Run role
   molecule verify    # Run verification
   molecule destroy   # Clean up
   ```

5. **Test Idempotency**
   ```bash
   # Molecule includes idempotence test
   molecule test
   
   # Or manually
   ansible-playbook playbooks/web_server.yml
   ansible-playbook playbooks/web_server.yml | grep -q 'changed=0' && echo "Idempotent"
   ```

**Interactive Questions:**
- "Did ansible-lint report any issues?"
- "Are you seeing any failed tests?"
- "Is the role idempotent?"

**Validation:** All lint checks pass, Molecule tests succeed, idempotency verified.

---

### Phase 9: Documentation

**Objective:** Document project for team collaboration

**Steps:**

1. **Create Project README**
   ```markdown
   # My Ansible Project
   
   ## Overview
   This project manages our web server infrastructure.
   
   ## Prerequisites
   - Ansible 2.9+
   - SSH access to target hosts
   - Sudo privileges on managed hosts
   
   ## Inventory
   - `development` - Development servers
   - `production` - Production servers
   
   ## Playbooks
   - `web_server.yml` - Configure web servers with Nginx
   
   ## Usage
   ```bash
   # Deploy to development
   ansible-playbook playbooks/web_server.yml --limit development
   
   # Deploy to production
   ansible-playbook playbooks/web_server.yml --limit production
   ```
   
   ## Roles
   - `nginx_install` - Install and configure Nginx web server
   ```

2. **Document Roles**
   ```markdown
   # roles/nginx_install/README.md
   
   # Nginx Install Role
   
   Installs and configures Nginx web server.
   
   ## Requirements
   None
   
   ## Role Variables
   - `nginx_install_port` - Listen port (default: 80)
   - `nginx_install_user` - Nginx user (default: nginx)
   
   ## Example Playbook
   ```yaml
   - hosts: web_servers
     roles:
       - role: nginx_install
         nginx_install_port: 8080
   ```
   ```

3. **Add Inline Comments**
   ```yaml
   tasks:
     # Install Nginx package from distribution repositories
     - name: Install Nginx
       ansible.builtin.package:
         name: nginx
         state: present
   ```

**Validation:** README exists, roles documented, usage examples provided.

---

### Phase 10: Production Deployment

**Objective:** Deploy to production safely

**Steps:**

1. **Pre-Deployment Checklist**
   ```bash
   # Verify all tests pass
   ansible-lint playbooks/*.yml
   molecule test
   
   # Verify inventory is correct
   ansible-inventory --list --yaml -i inventory/hosts.yml
   
   # Confirm target hosts
   ansible production --list-hosts
   ```

2. **Deploy to Staging First**
   ```bash
   # Deploy to staging environment
   ansible-playbook playbooks/web_server.yml --limit staging
   
   # Validate staging deployment
   ansible staging -m uri -a "url=http://localhost return_content=yes"
   ```

3. **Production Deployment**
   ```bash
   # Use check mode first
   ansible-playbook playbooks/web_server.yml --limit production --check --diff
   
   # Review changes carefully
   # Deploy to production
   ansible-playbook playbooks/web_server.yml --limit production
   ```

4. **Post-Deployment Validation**
   ```bash
   # Verify services running
   ansible production -m service_facts
   
   # Check application health
   ansible production -m uri -a "url=http://localhost/health"
   
   # Review logs
   ansible production -m shell -a "tail -20 /var/log/nginx/error.log"
   ```

5. **Rollback Plan**
   ```yaml
   # playbooks/rollback_nginx.yml
   ---
   - name: Rollback Nginx to previous version
     hosts: "{{ target_hosts }}"
     become: yes
     
     tasks:
       - name: Stop Nginx
         ansible.builtin.service:
           name: nginx
           state: stopped
       
       - name: Restore previous configuration
         ansible.builtin.copy:
           src: /etc/nginx/nginx.conf.bak
           dest: /etc/nginx/nginx.conf
           remote_src: yes
       
       - name: Start Nginx
         ansible.builtin.service:
           name: nginx
           state: started
   ```

**Interactive Questions:**
- "Have you verified the changes in staging?"
- "Do you have a rollback plan?"
- "Is this deployment during a maintenance window?"

**Validation:** Successful production deployment with verification.

---

## Interactive Workflow Patterns

### Pattern 1: Build-Test-Deploy Loop

```bash
# 1. Make changes
vim roles/myapp/tasks/main.yml

# 2. Syntax check
ansible-playbook playbooks/myapp.yml --syntax-check

# 3. Lint check
ansible-lint playbooks/myapp.yml

# 4. Check mode
ansible-playbook playbooks/myapp.yml --check --limit dev

# 5. Deploy to dev
ansible-playbook playbooks/myapp.yml --limit dev

# 6. Verify
ansible dev -m shell -a "systemctl status myapp"

# Repeat until satisfied, then deploy to production
```

### Pattern 2: Incremental Host Rollout

```yaml
# playbooks/rolling_update.yml
---
- name: Rolling update with validation
  hosts: web_servers
  serial: 1  # One host at a time
  
  tasks:
    - name: Remove from load balancer
      # Remove from LB
      
    - name: Update application
      # Deployment tasks
    
    - name: Verify health
      ansible.builtin.uri:
        url: http://localhost/health
        status_code: 200
      retries: 5
      delay: 10
    
    - name: Add back to load balancer
      # Add to LB
```

### Pattern 3: Progressive Environment Deployment

```bash
# 1. Development
ansible-playbook playbooks/deploy.yml --limit development
# Validate

# 2. Staging
ansible-playbook playbooks/deploy.yml --limit staging
# Validate

# 3. Production (subset)
ansible-playbook playbooks/deploy.yml --limit "production[0]"
# Validate canary

# 4. Production (all)
ansible-playbook playbooks/deploy.yml --limit production
```

## Interactive Troubleshooting Guide

### When Playbooks Fail

**Step 1: Identify the failure**
```bash
# Run with verbosity
ansible-playbook playbooks/site.yml -vvv

# Look for "failed:" or "fatal:" in output
```

**Step 2: Isolate the problem**
```bash
# Run single task with tags
ansible-playbook playbooks/site.yml --tags problem_task

# Run on single host
ansible-playbook playbooks/site.yml --limit problem_host
```

**Step 3: Debug interactively**
```yaml
# Add debug tasks
- name: Debug variable
  ansible.builtin.debug:
    var: my_variable
    verbosity: 0  # Always show

- name: Debug registered result
  ansible.builtin.debug:
    msg: "{{ result | to_nice_json }}"
```

**Step 4: Test manually**
```bash
# Test the failing command directly on host
ansible problem_host -m shell -a "the-failing-command"

# Check if file exists
ansible problem_host -m stat -a "path=/path/to/file"
```

**Step 5: Fix and verify**
```bash
# Make fix
# Test in check mode
ansible-playbook playbooks/site.yml --check

# Apply fix
ansible-playbook playbooks/site.yml
```

## Best Practices for Interactive Development

### 1. Always Validate Each Step

```bash
# Before running any playbook
ansible-playbook playbook.yml --syntax-check  # Syntax
ansible-lint playbook.yml                      # Best practices
ansible-playbook playbook.yml --check         # Dry run
ansible-playbook playbook.yml                 # Execute
```

### 2. Use Version Control

```bash
# Commit after each working phase
git add .
git commit -m "Phase 3: Connectivity testing complete"
git push
```

### 3. Test on Development First

```bash
# Never test directly in production
ansible-playbook playbooks/site.yml --limit development
# Validate thoroughly
# Then deploy to production
```

### 4. Keep Playbooks Idempotent

```bash
# Playbook should produce same result when run multiple times
ansible-playbook playbooks/site.yml  # Run 1
ansible-playbook playbooks/site.yml  # Run 2 - should show no changes
```

### 5. Document as You Go

```yaml
# Add comments explaining WHY not WHAT
tasks:
  # Required for SELinux compatibility with custom app paths
  - name: Set SELinux context
    ansible.builtin.sefcontext:
      target: '/opt/myapp(/.*)?'
      setype: httpd_sys_content_t
```

## Quick Reference Commands

### Inventory Management
```bash
# List all hosts
ansible all --list-hosts

# List hosts in group
ansible web_servers --list-hosts

# Show inventory structure
ansible-inventory --graph

# Validate inventory
ansible-inventory --list
```

### Ad-hoc Testing
```bash
# Ping all hosts
ansible all -m ping

# Run command
ansible all -m shell -a "uptime"

# Check service status
ansible all -m service -a "name=nginx" --become

# Copy file
ansible all -m copy -a "src=/local/file dest=/remote/file"
```

### Playbook Execution
```bash
# Syntax check
ansible-playbook playbook.yml --syntax-check

# Check mode (dry run)
ansible-playbook playbook.yml --check

# With diff
ansible-playbook playbook.yml --check --diff

# Limit to hosts
ansible-playbook playbook.yml --limit web_servers

# Use tags
ansible-playbook playbook.yml --tags install,configure

# With extra vars
ansible-playbook playbook.yml -e "version=1.2.3"
```

### Debugging
```bash
# Verbose output
ansible-playbook playbook.yml -v    # Basic
ansible-playbook playbook.yml -vv   # More details
ansible-playbook playbook.yml -vvv  # Connection debugging
ansible-playbook playbook.yml -vvvv # Everything

# Start at specific task
ansible-playbook playbook.yml --start-at-task="Task name"

# Step through tasks
ansible-playbook playbook.yml --step
```

## Output Template

When providing interactive guidance, structure responses as:

1. **Current Phase**: What we're accomplishing
2. **Steps**: Numbered, executable steps
3. **Commands**: Exact commands to run
4. **Validation**: How to verify success
5. **Interactive Questions**: Gather information for next steps
6. **Troubleshooting**: Common issues and fixes
7. **Next Phase**: Preview of what's coming

Example interaction:
```
We're in Phase 3: Connectivity Testing

Let's verify Ansible can connect to your hosts.

Step 1: Test basic connectivity
Run: ansible all -m ping

Did all hosts respond with "pong"? (yes/no)
> yes

Great! All hosts are reachable.

Step 2: Gather system facts
Run: ansible all -m setup -a "filter=ansible_distribution*"

What operating systems did it detect?
> Ubuntu 22.04

Perfect! Next we'll create our first playbook...
```

When guiding users through Ansible development, break complex tasks into small, validated steps, ask clarifying questions, verify success before proceeding, and provide immediate troubleshooting when issues arise.
