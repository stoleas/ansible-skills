---
name: playbook-creator
description: >
  Create Ansible playbooks from scratch following Red Hat Communities of Practice best practices.
  Use this skill when the user asks to: "create a playbook", "new playbook", "write a playbook",
  "ansible playbook for", "build a playbook", "playbook to deploy", "playbook to configure",
  "type playbook", "landscape playbook", "ansible automation for", or mentions creating Ansible
  automation. Always invoke this skill for playbook creation tasks.
version: 1.0.0
allowed-tools: [Read, Write, Edit, Bash, Glob]
---

# Playbook Creator Skill

Create Ansible playbooks following Red Hat Communities of Practice (CoP) standards with proper Type-Function pattern implementation.

## Core Principles

### Type-Function Pattern Architecture

The Type-Function pattern is the cornerstone of Red Hat CoP automation design:

- **Type**: A classification of managed hosts (e.g., `web_server`, `database`, `load_balancer`)
  - Each host has exactly ONE type
  - Type defined by the host's primary purpose in the infrastructure
  - Types are implemented as playbooks that orchestrate function roles

- **Function**: A reusable capability implemented as a role (e.g., `apache_install`, `postgresql_config`, `firewall_setup`)
  - Functions are composed into types
  - Functions can be shared across multiple types
  - Functions are atomic, focused capabilities

- **Component**: Maintainability units within functions (task files or component roles)
  - Keep functions manageable by breaking into components
  - Use task includes for organization within roles

- **Landscape**: Complete application or service deployment
  - Orchestrates multiple type playbooks
  - Represents full infrastructure topology
  - Managed via Ansible Automation Controller workflows

### Playbook Simplicity Principle

**Keep playbooks simple** - they should be primarily lists of roles with minimal embedded logic.

**Use `roles` OR `tasks`, never both** in the same play. Choose one:

```yaml
# Good - uses roles section
- name: Configure web servers
  hosts: web_server
  become: true
  roles:
    - role: namespace.collection.apache_install
    
# Good - uses tasks section (for ad-hoc tasks)
- name: Quick maintenance task
  hosts: all
  tasks:
    - name: Restart service
      ansible.builtin.service:
        name: httpd
        state: restarted

# Bad - mixes roles and tasks
- name: Configure web servers
  hosts: web_server
  become: true
  roles:
    - role: namespace.collection.apache_install
  tasks:  # Don't do this!
    - name: Additional task
      ansible.builtin.command: some_command
```

Delegate complex logic to roles - playbooks orchestrate, roles implement.

## Playbook Structure Standards

### YAML Formatting

Follow these strict YAML formatting rules:

```yaml
---
# Two-space indentation throughout
- name: Example playbook
  hosts: target_group
  become: true
  
  vars:
    # List items indented beyond the list key
    my_list:
      - item1
      - item2
      - item3
    
    # Use >- for line folding (removes trailing newline)
    long_description: >-
      This is a long description that spans
      multiple lines but will be folded into
      a single line in the final output.
    
  tasks:
    - name: Task with long conditional
      ansible.builtin.package:
        name: httpd
        state: present
      when:
        - ansible_os_family == "RedHat"
        - ansible_distribution_major_version|int >= 8
        - httpd_install_enabled|bool
```

**Key rules:**
- **Two-space indentation** (never tabs)
- **`.yml` extension** (not `.yaml`)
- **List contents indented beyond list definition**
- **Break long `when:` conditions into lists** for readability
- **Use `true`/`false` booleans** (YAML 1.2 standard)
- **Use `>-` for line folding** to avoid trailing whitespace

### Role Inclusion

Prefer `import_role` for static inclusion and `include_role` for dynamic scenarios:

```yaml
---
- name: Configure servers with static roles
  hosts: all
  become: true
  
  roles:
    # Simple role list - preferred for most cases
    - role: namespace.collection.base_linux
      tags: ['base', 'os']
    
  tasks:
    # Static import - roles are loaded at playbook parse time
    - name: Import monitoring role
      ansible.builtin.import_role:
        name: namespace.collection.monitoring
      tags: ['monitoring']
    
    # Dynamic include - role loaded at task execution time
    # Use when role selection depends on runtime facts/variables
    - name: Include platform-specific role
      ansible.builtin.include_role:
        name: "namespace.collection.{{ ansible_os_family|lower }}_config"
      when: ansible_os_family in ['RedHat', 'Debian']
```

**When to use each:**
- **`roles` section**: Default choice for simple, static role lists
- **`import_role`**: When you need task-level control (tags, when conditions) but static loading
- **`include_role`**: Only when role selection is dynamic (based on variables/facts)

### Tagging Strategy

Tag roles by name and purpose to enable selective execution:

```yaml
---
- name: Configure database servers
  hosts: database
  become: true
  
  roles:
    # Tag with role name and purpose/category
    - role: namespace.collection.base_linux
      tags: ['base_linux', 'base', 'os']
    
    - role: namespace.collection.postgresql_install
      tags: ['postgresql_install', 'database', 'install']
    
    - role: namespace.collection.postgresql_config
      tags: ['postgresql_config', 'database', 'config']
    
    - role: namespace.collection.firewall_setup
      tags: ['firewall_setup', 'security']
```

**Tag naming convention:**
- First tag: exact role name (with underscores)
- Additional tags: functional categories (base, install, config, security)
- Enables flexible execution: `ansible-playbook site.yml --tags database`

**Avoid tags that require specific execution order** - roles should be independently executable.

### Variable Precedence Strategy

Use the simplified Red Hat CoP variable precedence model:

1. **Role defaults** (`defaults/main.yml`) - Baseline values
2. **Inventory variables** - Desired state defined by infrastructure
3. **Host facts** - Current state gathered from systems
4. **Role variables** (`vars/main.yml`) - Internal role logic
5. **Scoped variables** - Block/task level overrides
6. **Runtime variables** - `register`, `set_fact` results
7. **Extra variables** (`-e`) - Explicit overrides

**Best practice:** Define desired state in inventory, not in playbooks.

```yaml
---
# Good - playbook doesn't define infrastructure state
- name: Configure web servers
  hosts: web_server
  become: true
  
  roles:
    - role: namespace.collection.apache_install
      # Variables come from inventory, not here

# Inventory defines the desired state
# inventory/group_vars/web_server.yml:
# apache_install_version: "2.4"
# apache_install_listen_port: 80
```

## Playbook Types

### Type Playbook

Manages all hosts of a specific type by applying function roles:

```yaml
---
# Purpose: Manages web server hosts
# Type: web_server
# Author: Generated by ansible-skills

- name: Configure web server type
  hosts: web_server
  become: true
  
  # Environment-specific variables can be set here
  # But prefer inventory variables for infrastructure state
  vars:
    deployment_environment: "{{ env | default('production') }}"
  
  # Pre-tasks for preparation
  pre_tasks:
    - name: Update package cache
      ansible.builtin.package:
        update_cache: true
      changed_when: false
      tags: ['always']
  
  # Function roles that define this type
  roles:
    # Base function - always first
    - role: namespace.collection.base_linux
      tags: ['base_linux', 'base', 'os']
    
    # Type-specific functions in logical order
    - role: namespace.collection.apache_install
      tags: ['apache_install', 'web', 'install']
    
    - role: namespace.collection.apache_config
      tags: ['apache_config', 'web', 'config']
    
    - role: namespace.collection.app_deploy
      tags: ['app_deploy', 'application']
    
    - role: namespace.collection.firewall_setup
      tags: ['firewall_setup', 'security']
    
    - role: namespace.collection.monitoring_agent
      tags: ['monitoring_agent', 'monitoring']
  
  # Post-tasks for verification
  post_tasks:
    - name: Verify web service is running
      ansible.builtin.uri:
        url: "http://{{ ansible_host }}:80/health"
        status_code: 200
      delegate_to: localhost
      tags: ['verify']
```

**Type playbook guidelines:**
- Name playbook after the type: `web_server.yml`, `database.yml`
- Apply base function first (OS hardening, common config)
- Order functions logically (install → configure → deploy → secure → monitor)
- Use pre_tasks for preparation (cache updates, fact gathering)
- Use post_tasks for verification
- Tag comprehensively for selective execution

### Landscape Playbook

Orchestrates multiple type playbooks to deploy complete infrastructure:

```yaml
---
# Landscape Playbook: three_tier_app
# Purpose: Deploy complete three-tier application
# Author: Generated by ansible-skills

# Database tier - deployed first
- name: Configure database tier
  import_playbook: types/database.yml
  tags: ['database', 'tier1', 'data']

# Middleware tier - depends on database
- name: Configure middleware tier
  import_playbook: types/middleware.yml
  tags: ['middleware', 'tier2', 'app']

# Web tier - front-end, deployed last
- name: Configure web tier
  import_playbook: types/web_server.yml
  tags: ['web', 'tier3', 'frontend']

# Post-deployment verification
- name: Verify landscape deployment
  hosts: localhost
  gather_facts: false
  tags: ['verify', 'always']
  
  tasks:
    - name: Wait for application to be healthy
      ansible.builtin.uri:
        url: "http://{{ groups['web_server'][0] }}/health"
        status_code: 200
      retries: 30
      delay: 10
      until: health_check is succeeded
      register: health_check
    
    - name: Deployment verification complete
      ansible.builtin.debug:
        msg: "Three-tier application deployment verified successfully"
```

**Landscape playbook guidelines:**
- Use `import_playbook` to include type playbooks
- Deploy in dependency order (data → app → frontend)
- Tag by tier for selective deployment
- Include verification play at the end
- Keep orchestration logic minimal
- Complex workflows should use Ansible Automation Platform/Controller

### Simple Playbook

For single-role or simple automation tasks:

```yaml
---
# Purpose: Install and configure Apache web server
# Author: Generated by ansible-skills

- name: Setup Apache web server
  hosts: webservers
  become: true
  
  roles:
    - role: namespace.collection.apache_install
      apache_install_version: "2.4"
      apache_install_modules:
        - ssl
        - rewrite
      tags: ['apache']
```

**When to use simple playbooks:**
- Single role application
- Ad-hoc automation tasks
- Development/testing scenarios
- Quick fixes or maintenance

## Header Comments

Always include descriptive header comments:

```yaml
---
# Purpose: [What this playbook does and why]
# Type/Landscape: [Type name or landscape name]
# Dependencies: [Any prerequisites or required infrastructure]
# Author: [Author or "Generated by ansible-skills"]
# Last Updated: [Date]

- name: Playbook name
  hosts: target
```

## Output Format

When creating playbooks, structure the output like this:

1. **Header comment** with purpose, type/landscape, author
2. **YAML frontmatter** (`---`)
3. **Play definition** with descriptive name
4. **Host targeting** (`hosts`)
5. **Privilege escalation** (`become`) if needed
6. **Variables** (`vars`) if minimal and not in inventory
7. **Pre-tasks** if preparation needed
8. **Roles list** with tags
9. **Post-tasks** if verification needed

## Common Patterns

### Conditional Role Application

```yaml
---
- name: Configure servers with conditional roles
  hosts: all
  become: true
  
  roles:
    - role: namespace.collection.base_linux
      tags: ['base']
    
    # Apply role only to RedHat family
    - role: namespace.collection.redhat_specific
      when: ansible_os_family == "RedHat"
      tags: ['redhat']
    
    # Apply role based on host variable
    - role: namespace.collection.optional_feature
      when: enable_optional_feature|default(false)|bool
      tags: ['optional']
```

### Environment-Specific Configuration

```yaml
---
- name: Configure application servers
  hosts: app_servers
  become: true
  
  vars:
    # Use environment variable with fallback
    target_env: "{{ lookup('env', 'DEPLOY_ENV') | default('production') }}"
  
  roles:
    - role: namespace.collection.app_deploy
      app_deploy_environment: "{{ target_env }}"
      tags: ['deploy']
```

### Serial Execution for Rolling Updates

```yaml
---
- name: Rolling update of web servers
  hosts: web_server
  become: true
  serial: 2  # Update 2 servers at a time
  
  pre_tasks:
    - name: Remove server from load balancer
      ansible.builtin.command: >
        /usr/local/bin/lb-remove {{ inventory_hostname }}
      delegate_to: loadbalancer
      changed_when: true
  
  roles:
    - role: namespace.collection.app_update
      tags: ['update']
  
  post_tasks:
    - name: Wait for service to be ready
      ansible.builtin.wait_for:
        port: 8080
        delay: 5
        timeout: 60
    
    - name: Add server back to load balancer
      ansible.builtin.command: >
        /usr/local/bin/lb-add {{ inventory_hostname }}
      delegate_to: loadbalancer
      changed_when: true
```

## Validation Checklist

Before finalizing a playbook, verify:

- [ ] YAML syntax is valid (`ansible-playbook --syntax-check`)
- [ ] Uses `.yml` extension
- [ ] Two-space indentation throughout
- [ ] Header comment with purpose and metadata
- [ ] Descriptive play names (not "Play 1", "Configure stuff")
- [ ] Uses `roles` OR `tasks`, not both
- [ ] Roles tagged appropriately (name + purpose)
- [ ] Variables prefer inventory over embedded definitions
- [ ] No hardcoded credentials (use Ansible Vault or external secrets)
- [ ] Long conditionals broken into lists
- [ ] Proper use of `true`/`false` booleans
- [ ] Follows Type-Function pattern for infrastructure playbooks
- [ ] No abbreviations in names
- [ ] Snake_case naming throughout

## Red Hat CoP Anti-Patterns to Avoid

**Don't mix roles and tasks:**
```yaml
# Bad
- name: Configure servers
  hosts: all
  roles:
    - some_role
  tasks:  # Don't do this
    - name: Additional task
```

**Don't embed complex logic in playbooks:**
```yaml
# Bad - complex logic in playbook
- name: Configure servers
  hosts: all
  tasks:
    - name: Complex multi-step logic
      ansible.builtin.shell: |
        if [ -f /etc/config ]; then
          # Many lines of shell logic
        fi
```
**Instead:** Move logic to a function role

**Don't use playbook variables for infrastructure state:**
```yaml
# Bad - hardcoded state in playbook
- name: Configure web
  hosts: web
  vars:
    apache_port: 80  # Should be in inventory
```

**Don't skip idempotency:**
```yaml
# Bad - always reports changed
- name: Configure something
  ansible.builtin.shell: configure.sh
```
**Instead:** Use `creates`, `changed_when`, or proper modules

**Don't use tags that require ordered execution:**
```yaml
# Bad - tags imply order dependency
roles:
  - role: app
    tags: ['step1']
  - role: config
    tags: ['step2']  # Implies must run after step1
```

## Next Steps After Playbook Creation

1. **Validate syntax:**
   ```bash
   ansible-playbook --syntax-check playbook.yml
   ```

2. **Lint the playbook:**
   ```bash
   ansible-lint --profile moderate playbook.yml
   ```

3. **Test in check mode:**
   ```bash
   ansible-playbook --check playbook.yml
   ```

4. **Execute with verbosity:**
   ```bash
   ansible-playbook -v playbook.yml
   ```

5. **Verify idempotence:**
   ```bash
   # Run twice - second run should show no changes
   ansible-playbook playbook.yml
   ansible-playbook playbook.yml
   ```

When asked to create a playbook, analyze the requirements, select the appropriate playbook type (simple/type/landscape), and generate valid, well-structured Ansible playbooks following all Red Hat CoP standards outlined above.
