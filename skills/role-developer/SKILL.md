---
name: role-developer
description: >
  Develop Ansible roles following Red Hat Communities of Practice standards with complete
  structure, testing, validation, and documentation. Use this skill when the user asks to:
  "create a role", "new role", "develop a role", "write a role", "ansible role for",
  "build a role", "role to manage", "function role", "component role", "role skeleton",
  "molecule test", "create ansible role", or mentions developing Ansible roles.
  Always invoke this skill for role development tasks.
version: 1.0.0
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Role Developer Skill

Develop comprehensive Ansible roles following Red Hat Communities of Practice (CoP) standards with complete testing, validation, and documentation.

## Core Role Concepts

### Roles in the Type-Function Pattern

- **Function Roles**: Implement reusable capabilities (e.g., `apache_install`, `postgresql_config`)
  - Single, focused purpose
  - Reusable across multiple types
  - Self-contained with all dependencies documented

- **Component Roles**: Smaller roles used within function roles for complex implementations
  - Break large functions into maintainable components
  - Used via `include_role` or `import_role` within parent role

### Role Naming Standards

**CRITICAL: No dashes in role names** - they cause collection packaging issues.

```
Good naming:
  apache_install
  postgresql_config
  firewall_setup
  monitoring_agent

Bad naming:
  apache-install      # Dashes not allowed
  postgresqlConfig    # CamelCase not allowed
  fw_setup            # Abbreviations discouraged
  monitoring-agent    # Dashes not allowed
```

**Naming convention:**
- **Snake_case exclusively**
- **No dashes** (breaks collections)
- **No abbreviations** (clarity over brevity)
- **Verb_noun pattern** when appropriate (`install_apache`, `configure_firewall`)
- **Descriptive names** that indicate purpose

## Complete Role Structure

Every role must include these components:

```
role_name/
├── defaults/
│   └── main.yml           # User-facing default variables
├── files/                 # Static files
├── handlers/
│   └── main.yml           # Event handlers (service restarts, etc.)
├── meta/
│   ├── main.yml           # Role metadata and dependencies
│   └── argument_specs.yml # Argument validation (Ansible 2.11+)
├── molecule/              # Testing with Molecule
│   └── default/
│       ├── molecule.yml   # Molecule configuration
│       ├── converge.yml   # Test playbook
│       └── verify.yml     # Verification tests
├── tasks/
│   └── main.yml           # Main task list (orchestrates includes)
├── templates/             # Jinja2 templates
├── tests/
│   ├── inventory          # Test inventory
│   └── test.yml           # Legacy test playbook
├── vars/
│   ├── main.yml           # Internal role variables
│   ├── RedHat.yml         # RedHat-specific variables
│   └── Debian.yml         # Debian-specific variables
├── README.md              # Comprehensive documentation
└── .ansible-lint          # ansible-lint configuration

```

## Variable Naming Standards

**CRITICAL: All role variables MUST be prefixed with the role name.**

### External Variables (User-Facing)

Variables users can/should override:

```yaml
# File: defaults/main.yml
---
# All variables prefixed with role name
apache_install_version: "2.4"
apache_install_listen_port: 80
apache_install_ssl_enabled: true
apache_install_modules:
  - ssl
  - rewrite
  - headers

# Document each variable
# Variable: apache_install_version
# Type: string
# Description: Apache version to install
# Default: "2.4"
```

### Internal Variables (Implementation Details)

Variables used only within the role:

```yaml
# File: vars/main.yml or task-specific vars
---
# Double underscore prefix for internal variables
__apache_install_package_name: "httpd"
__apache_install_service_name: "httpd"
__apache_install_config_path: "/etc/httpd"
__apache_install_temp_dir: "/tmp/apache_install"
```

**Naming rules:**
- External: `rolename_purpose_detail`
- Internal: `__rolename_purpose_detail` (double underscore prefix)
- **Always snake_case**
- **Never abbreviate** (apache_install not ap_inst)
- **No special characters** except underscores

### Variable Documentation Template

```yaml
---
# defaults/main.yml for role: example_role

# Package configuration
# Type: string
# Description: Package name to install
# Default: "example-package"
# Required: No
example_role_package_name: "example-package"

# Service configuration
# Type: boolean
# Description: Whether to enable the service on boot
# Default: true
# Required: No
example_role_service_enabled: true

# Port configuration
# Type: integer
# Description: Port number for the service to listen on
# Default: 8080
# Required: No
# Valid range: 1024-65535
example_role_listen_port: 8080

# Feature list
# Type: list
# Description: List of features to enable
# Default: []
# Required: No
example_role_enabled_features: []
```

## Idempotency Requirements

**All roles MUST be idempotent** - running multiple times produces the same result without unnecessary changes.

### Testing Idempotency

```bash
# Role must pass idempotence test
molecule converge
molecule idempotence  # Should report 0 changes
```

### Ensuring Idempotency

#### Use Declarative Modules

```yaml
# Good - idempotent by default
- name: Ensure Apache is installed
  ansible.builtin.package:
    name: httpd
    state: present

# Bad - always reports changed
- name: Install Apache
  ansible.builtin.shell: yum install -y httpd
```

#### Control `changed` Status

```yaml
# For commands that are idempotent but always report changed
- name: Check Apache configuration
  ansible.builtin.command: apachectl configtest
  register: config_test
  changed_when: false  # Checking doesn't change anything
  failed_when: config_test.rc != 0

# For complex shell commands
- name: Initialize database
  ansible.builtin.shell: >
    /usr/local/bin/init-db.sh
  args:
    creates: /var/lib/database/.initialized
  # Only runs if .initialized file doesn't exist
```

#### Fact-Based Guards

```yaml
# Gather facts first, use for idempotent decisions
- name: Check if application is already installed
  ansible.builtin.stat:
    path: /opt/app/bin/app
  register: __example_role_app_installed

- name: Download and install application
  ansible.builtin.get_url:
    url: "{{ example_role_app_url }}"
    dest: /opt/app/bin/app
    mode: '0755'
  when: not __example_role_app_installed.stat.exists
```

## Multi-Platform Support

Support multiple operating systems using platform-specific variable files.

### Platform Variables Pattern

```yaml
# File: tasks/main.yml
---
- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"
  tags: ['always']

# File: vars/RedHat.yml
---
__apache_install_package_name: "httpd"
__apache_install_service_name: "httpd"
__apache_install_config_dir: "/etc/httpd/conf.d"

# File: vars/Debian.yml
---
__apache_install_package_name: "apache2"
__apache_install_service_name: "apache2"
__apache_install_config_dir: "/etc/apache2/sites-available"
```

### Platform-Specific Tasks

```yaml
# Conditional task execution
- name: Install Apache on RedHat systems
  ansible.builtin.yum:
    name: "{{ __apache_install_package_name }}"
    state: present
  when: ansible_os_family == "RedHat"

- name: Install Apache on Debian systems
  ansible.builtin.apt:
    name: "{{ __apache_install_package_name }}"
    state: present
    update_cache: true
  when: ansible_os_family == "Debian"

# Or use the generic package module (determines package manager automatically)
- name: Install Apache (platform-agnostic)
  ansible.builtin.package:
    name: "{{ __apache_install_package_name }}"
    state: present
```

## Argument Validation with argument_specs

Ansible 2.11+ supports argument validation in `meta/argument_specs.yml`.

### Benefits

- Fail fast with clear error messages
- Type validation
- Required parameter enforcement
- Documentation in machine-readable format
- IDE autocomplete support

### argument_specs.yml Structure

```yaml
---
# File: meta/argument_specs.yml
argument_specs:
  main:
    short_description: Short one-line description of role
    description:
      - Detailed description of what the role does
      - Can be multiple lines
      - Describe capabilities and outcomes
    author:
      - Your Name (@github_handle)
    options:
      apache_install_version:
        description:
          - Apache version to install
          - Must be a valid Apache version number
        type: str
        required: false
        default: "2.4"

      apache_install_listen_port:
        description: Port number for Apache to listen on
        type: int
        required: false
        default: 80

      apache_install_ssl_enabled:
        description: Whether to enable SSL/TLS support
        type: bool
        required: false
        default: true

      apache_install_modules:
        description: List of Apache modules to enable
        type: list
        elements: str
        required: false
        default: []

      apache_install_domain:
        description: Primary domain name for Apache virtual host
        type: str
        required: true  # This parameter is mandatory
```

**Supported types:**
- `str` - String
- `int` - Integer
- `float` - Floating point number
- `bool` - Boolean
- `list` - List/array
- `dict` - Dictionary/hash
- `path` - File system path
- `raw` - Any type

## Task Organization

Keep `tasks/main.yml` as an orchestration file that includes component task files.

### tasks/main.yml Pattern

```yaml
---
# File: tasks/main.yml
# Orchestrates role execution by including component task files

- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"
  tags: ['always']

- name: Gather required facts if not present
  ansible.builtin.setup:
    gather_subset:
      - '!all'
      - '!min'
      - distribution
  when: >-
    not ansible_facts.keys() | list |
    intersect(__apache_install_required_facts)
  tags: ['always']

- name: Validate required arguments
  ansible.builtin.assert:
    that:
      - apache_install_domain is defined
      - apache_install_domain | length > 0
      - apache_install_listen_port >= 1
      - apache_install_listen_port <= 65535
    fail_msg: "Required variables not properly configured"
  tags: ['always']

- name: Include preflight checks
  ansible.builtin.include_tasks: preflight.yml
  tags: ['preflight']

- name: Include installation tasks
  ansible.builtin.include_tasks: install.yml
  tags: ['install']

- name: Include configuration tasks
  ansible.builtin.include_tasks: configure.yml
  tags: ['configure']

- name: Include service management tasks
  ansible.builtin.include_tasks: service.yml
  tags: ['service']
```

### Component Task Files

```yaml
# File: tasks/install.yml
---
- name: Install Apache package
  ansible.builtin.package:
    name: "{{ __apache_install_package_name }}"
    state: present

- name: Install Apache modules
  ansible.builtin.package:
    name: "{{ item }}"
    state: present
  loop: "{{ __apache_install_module_packages }}"

# File: tasks/configure.yml
---
- name: Deploy Apache configuration
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: "{{ __apache_install_config_dir }}/httpd.conf"
    mode: '0644'
    owner: root
    group: root
    validate: apachectl -t -f %s
  notify: Restart Apache

# File: tasks/service.yml
---
- name: Enable and start Apache service
  ansible.builtin.service:
    name: "{{ __apache_install_service_name }}"
    state: started
    enabled: true
```

## Handlers

Handlers respond to task notifications (e.g., restart services after config changes).

```yaml
# File: handlers/main.yml
---
- name: Restart Apache
  ansible.builtin.service:
    name: "{{ __apache_install_service_name }}"
    state: restarted

- name: Reload Apache
  ansible.builtin.service:
    name: "{{ __apache_install_service_name }}"
    state: reloaded

- name: Validate Apache configuration
  ansible.builtin.command: apachectl configtest
  changed_when: false
```

**Handler best practices:**
- Name handlers clearly (what they do, not when)
- Use `listen` for grouped handlers
- Handlers run once at end of play, even if notified multiple times
- Handlers don't run if play fails (use `--force-handlers` to override)

## Templates with ansible_managed

All templates should include the `ansible_managed` comment:

```jinja2
{# File: templates/httpd.conf.j2 #}
# {{ ansible_managed }}
# Apache Configuration
# Managed by ansible role: apache_install

ServerRoot "{{ __apache_install_server_root }}"
Listen {{ apache_install_listen_port }}

{% if apache_install_ssl_enabled %}
Listen 443 https
{% endif %}

ServerName {{ apache_install_domain }}

# Load modules
{% for module in apache_install_modules %}
LoadModule {{ module }}_module modules/mod_{{ module }}.so
{% endfor %}
```

**Benefits of `ansible_managed`:**
- Clear indication file is managed by Ansible
- Discourages manual edits
- Can include timestamp, hostname, etc. via ansible.cfg

## Role Metadata

```yaml
# File: meta/main.yml
---
galaxy_info:
  role_name: apache_install
  namespace: company
  author: Your Name
  description: Install and configure Apache web server
  company: Your Company
  license: MIT
  min_ansible_version: "2.11"

  platforms:
    - name: EL
      versions:
        - "8"
        - "9"
    - name: Debian
      versions:
        - bullseye
        - bookworm
    - name: Ubuntu
      versions:
        - focal
        - jammy

  galaxy_tags:
    - web
    - apache
    - httpd

dependencies: []
  # - role: company.infrastructure.base_linux
  #   vars:
  #     base_linux_install_tools: true
```

## Check Mode Support

Roles should support check mode (`--check`) for dry-run validation:

```yaml
# Most declarative modules support check mode by default
- name: Install package (check mode supported)
  ansible.builtin.package:
    name: httpd
    state: present
  # Works in check mode automatically

# For modules that don't support check mode
- name: Run custom script
  ansible.builtin.command: /usr/local/bin/setup.sh
  check_mode: false  # Skip in check mode
  when: not ansible_check_mode

# Or provide check mode alternative
- name: Check if setup needed (check mode)
  ansible.builtin.stat:
    path: /var/lib/app/.initialized
  register: setup_status
  check_mode: true

- name: Run setup if needed
  ansible.builtin.command: /usr/local/bin/setup.sh
  when:
    - not ansible_check_mode
    - not setup_status.stat.exists
```

## Testing with Molecule

Molecule provides role testing framework with multiple scenarios:

```yaml
# File: molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: podman
platforms:
  - name: rhel9-instance
    image: registry.access.redhat.com/ubi9/ubi-init:latest
    pre_build_image: true
    privileged: true
    command: /sbin/init
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro

  - name: debian12-instance
    image: debian:12
    pre_build_image: true
    privileged: true
    command: /sbin/init
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro

provisioner:
  name: ansible
  config_options:
    defaults:
      callbacks_enabled: ansible.posix.profile_tasks
      stdout_callback: yaml
  inventory:
    host_vars:
      rhel9-instance:
        apache_install_domain: "test.example.com"
        apache_install_listen_port: 8080
      debian12-instance:
        apache_install_domain: "test.example.org"
        apache_install_listen_port: 8080

verifier:
  name: ansible

lint: |
  set -e
  ansible-lint
  yamllint .
```

### Molecule Test Sequence

```bash
# Full test sequence
molecule test

# Individual steps
molecule create      # Create test instances
molecule converge    # Run the role
molecule idempotence # Verify no changes on re-run
molecule verify      # Run verification tests
molecule destroy     # Clean up instances

# Development workflow
molecule converge    # Apply role changes
molecule verify      # Test the result
molecule destroy     # Clean up when done
```

## ansible-lint Configuration

```yaml
# File: .ansible-lint
---
profile: moderate

exclude_paths:
  - .cache/
  - .git/
  - molecule/

skip_list: []
  # Add rules to skip if needed
  # - yaml[line-length]

warn_list:
  - experimental
  - meta-no-tags

kinds:
  - tasks: "**/tasks/*.yml"
  - vars: "**/vars/*.yml"
  - meta: "**/meta/main.yml"
  - yaml: "**/*.yaml"
```

Run lint before committing:
```bash
ansible-lint
```

## README Documentation Template

Every role needs comprehensive README:

```markdown
# Ansible Role: role_name

## Description

[Detailed description of what this role does, its purpose, and when to use it]

## Requirements

- Ansible 2.11 or higher
- Supported platforms: RHEL 8/9, Debian 11/12, Ubuntu 20.04/22.04
- [Any other requirements]

## Role Variables

### Required Variables

Variables that MUST be defined:

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `role_name_required_var` | string | [Description] | `"value"` |

### Optional Variables

Variables with defaults that can be overridden:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `role_name_optional_var` | string | `"default"` | [Description] |
| `role_name_enabled` | boolean | `true` | [Description] |
| `role_name_port` | integer | `8080` | [Description] |

See `defaults/main.yml` for complete list with documentation.

## Dependencies

List any role dependencies:

- `company.infrastructure.base_linux` - Provides base OS configuration
- None if no dependencies

## Example Playbook

```yaml
---
- name: Example using role_name
  hosts: servers
  become: true

  roles:
    - role: company.collection.role_name
      role_name_required_var: "value"
      role_name_optional_var: "custom_value"
```

## Capabilities

- [Capability 1: What the role can do]
- [Capability 2: Another capability]
- [Capability 3: Third capability]

## Idempotency

**Idempotent:** Yes

This role is fully idempotent. Running it multiple times on the same host will produce the same result without unnecessary changes.

[If not idempotent, explain why and which operations are not idempotent]

## Rollback

**Rollback supported:** Partial

[Describe what can be rolled back and what cannot]
[If no rollback support, explain why]

Example rollback:
```yaml
- role: company.collection.role_name
  role_name_state: absent  # Removes the installation
```

## Check Mode

**Check mode supported:** Yes

This role fully supports check mode (`--check`) for dry-run validation.

## Testing

```bash
# Lint the role
ansible-lint

# Run molecule tests
molecule test

# Test specific scenario
molecule test -s centos9
```

## Supported Platforms

- Red Hat Enterprise Linux 8, 9
- CentOS 8, 9
- Debian 11 (Bullseye), 12 (Bookworm)
- Ubuntu 20.04 LTS (Focal), 22.04 LTS (Jammy)

## License

[License name, e.g., MIT, Apache 2.0]

## Author

[Author name and contact]
[GitHub: @username]

## Contributing

[Guidelines for contributing to this role]
```

## Role Development Checklist

Before considering a role complete, verify:

- [ ] All variables prefixed with role name
- [ ] Internal variables use double underscore prefix
- [ ] `meta/argument_specs.yml` defines and validates all parameters
- [ ] Multi-platform support via platform-specific vars files
- [ ] Role is idempotent (passes `molecule idempotence`)
- [ ] Check mode supported
- [ ] `tasks/main.yml` orchestrates via includes
- [ ] Templates include `{{ ansible_managed }}`
- [ ] Handlers defined for service management
- [ ] Molecule tests for multiple platforms
- [ ] ansible-lint passes with moderate profile
- [ ] Comprehensive README with examples
- [ ] `meta/main.yml` complete with platform info
- [ ] No dashes in role name
- [ ] Snake_case naming throughout
- [ ] `.yml` extension (not `.yaml`)

## Next Steps After Role Creation

1. **Validate structure:**
   ```bash
   ansible-galaxy role init --help  # See standard structure
   ```

2. **Lint the role:**
   ```bash
   ansible-lint --profile moderate
   ```

3. **Run Molecule tests:**
   ```bash
   molecule test
   ```

4. **Test idempotence:**
   ```bash
   molecule converge
   molecule idempotence  # Should show 0 changes
   ```

5. **Test in check mode:**
   ```bash
   ansible-playbook --check -i inventory playbook.yml
   ```

6. **Document in README**

7. **Version control:**
   ```bash
   git init
   git add .
   git commit -m "Initial role: role_name"
   ```

When asked to create a role, analyze requirements, generate a complete role structure following all Red Hat CoP standards, include comprehensive testing setup, and provide clear documentation.
