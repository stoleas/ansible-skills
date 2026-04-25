---
name: ansible-cop-review
description: >
  Review Ansible code against Red Hat Communities of Practice automation good practices.
  Use this skill when the user asks to: "review ansible code", "check CoP compliance",
  "validate against Red Hat standards", "cop review", "ansible best practices review",
  "check ansible code quality", "review playbook", "review role", or wants to validate
  their Ansible automation against Red Hat CoP standards. Always invoke this skill for
  code review and validation tasks.
version: 1.0.0
allowed-tools: [Read, Bash, Grep, Glob]
---

# Ansible CoP Review Skill

Review Ansible code against all Red Hat Communities of Practice (CoP) automation good practices, providing detailed feedback and actionable recommendations.

## Review Scope

This skill reviews Ansible automation against the complete Red Hat CoP framework:

1. **Structure & Organization** - Project layout, directory structure, naming
2. **Role Design** - Variable naming, idempotency, platform support
3. **Playbook Design** - Type-Function pattern, simplicity, tagging
4. **Code Quality** - YAML formatting, ansible-lint compliance, documentation
5. **Testing** - Molecule tests, idempotence validation, CI/CD integration
6. **Security** - Credential handling, privilege escalation, validation

## Review Process

### 1. Identify What to Review

Determine the scope:
- **Single role** - Review role structure and implementation
- **Playbook** - Review playbook design and role usage
- **Collection** - Review collection organization and content
- **Complete project** - Review entire automation project

### 2. Read the Code

Use appropriate tools to read all relevant files:
```bash
# List project structure
find . -type f -name "*.yml" -o -name "*.yaml"

# Read playbooks
cat playbooks/*.yml

# Read role files
cat roles/*/tasks/main.yml
cat roles/*/defaults/main.yml
cat roles/*/meta/main.yml
```

### 3. Apply CoP Standards

Check against all Red Hat CoP criteria (detailed below).

### 4. Generate Review Report

Provide structured feedback:
- **Summary** - Overall assessment
- **Critical Issues** - Must fix (breaks standards)
- **Warnings** - Should fix (best practices)
- **Recommendations** - Nice to have (improvements)
- **Strengths** - What's done well

## Red Hat CoP Standards Checklist

### Structure & Organization

#### Project Structure

**Standard:**
```
project/
├── ansible.cfg
├── inventory/
│   ├── production/
│   │   ├── hosts
│   │   └── group_vars/
│   └── staging/
├── playbooks/
│   ├── types/              # Type playbooks
│   │   ├── web_server.yml
│   │   └── database.yml
│   └── landscapes/         # Landscape playbooks
│       └── ecommerce.yml
├── roles/                  # Local roles
└── collections/
    └── requirements.yml
```

**Review Points:**
- [ ] Inventory separated by environment
- [ ] Playbooks organized by type/landscape
- [ ] ansible.cfg present with proper settings
- [ ] Collections requirements defined
- [ ] Documentation exists (README.md)

#### Naming Conventions

**Rules:**
- Snake_case exclusively
- `.yml` extension (not `.yaml`)
- No dashes in role names
- No abbreviations
- Descriptive names

**Review Points:**
- [ ] All files use `.yml` extension
- [ ] Role names use underscores (not dashes)
- [ ] Variables use snake_case
- [ ] No abbreviations in names
- [ ] Names are descriptive

### Role Standards

#### Variable Naming

**Required Pattern:**
- External: `rolename_variable_name`
- Internal: `__rolename_internal_variable`

**Review Points:**
- [ ] All variables prefixed with role name
- [ ] Internal variables use double underscore
- [ ] No generic variable names (enabled, version, port)
- [ ] Variables documented in defaults/main.yml
- [ ] Platform-specific vars in separate files

**Example Check:**
```yaml
# Good
apache_install_version: "2.4"
apache_install_listen_port: 80
__apache_install_package_name: "httpd"

# Bad
version: "2.4"           # No role prefix
apache-port: 80          # Dash instead of underscore
apacheVersion: "2.4"     # CamelCase
```

#### Argument Validation

**Required:** `meta/argument_specs.yml` for Ansible 2.11+

**Review Points:**
- [ ] argument_specs.yml exists
- [ ] All user-facing variables defined
- [ ] Types specified correctly
- [ ] Required variables marked
- [ ] Descriptions provided

#### Idempotency

**Required:** Roles must be idempotent

**Review Points:**
- [ ] Uses declarative modules (package, service, file)
- [ ] Commands have `creates`/`removes` or `changed_when`
- [ ] No always-changing operations
- [ ] Templates don't include timestamps
- [ ] Molecule idempotence test exists

**Common Violations:**
```yaml
# Bad - always reports changed
- ansible.builtin.command: yum install -y httpd

# Good - idempotent
- ansible.builtin.package:
    name: httpd
    state: present
```

#### Multi-Platform Support

**Required:** Platform-specific variables in separate files

**Review Points:**
- [ ] vars/RedHat.yml exists for RHEL/CentOS
- [ ] vars/Debian.yml exists for Debian/Ubuntu
- [ ] Platform vars loaded via include_vars
- [ ] Package names mapped per platform
- [ ] Service names mapped per platform

**Example:**
```yaml
# tasks/main.yml
- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"
```

#### Role Structure

**Required Files:**
- defaults/main.yml
- tasks/main.yml
- meta/main.yml
- meta/argument_specs.yml
- README.md

**Optional but Recommended:**
- handlers/main.yml
- vars/main.yml
- vars/RedHat.yml, vars/Debian.yml
- templates/
- files/
- molecule/

**Review Points:**
- [ ] All required files present
- [ ] README.md comprehensive
- [ ] meta/main.yml complete
- [ ] Tasks organized via includes
- [ ] Handlers defined for service management

### Playbook Standards

#### Type-Function Pattern

**Required Architecture:**
- Each host has ONE type
- Types composed of function roles
- Playbooks are simple role lists

**Review Points:**
- [ ] Type playbooks exist (web_server.yml, database.yml)
- [ ] Each type applies multiple function roles
- [ ] Landscape playbooks import type playbooks
- [ ] No complex logic in playbooks
- [ ] Roles section OR tasks section (not both)

**Example:**
```yaml
# Good - Type playbook
- name: Configure web server type
  hosts: web_server
  become: true
  roles:
    - base_linux
    - apache_install
    - app_deploy
```

#### Playbook Simplicity

**Rules:**
- Use `roles` OR `tasks`, never both
- Delegate logic to roles
- Keep playbooks as orchestration

**Review Points:**
- [ ] Playbooks don't mix roles and tasks
- [ ] Minimal embedded logic
- [ ] Variables defined in inventory (not playbook)
- [ ] Complex logic delegated to roles

#### Tagging Strategy

**Required Pattern:**
- Tag by role name
- Tag by purpose/category
- Enable selective execution

**Review Points:**
- [ ] All roles have tags
- [ ] First tag is role name
- [ ] Additional tags by category
- [ ] Tags don't imply execution order

**Example:**
```yaml
roles:
  - role: apache_install
    tags: ['apache_install', 'web', 'install']
```

### YAML Formatting

#### Style Rules

**Standards:**
- 2-space indentation
- List items indented beyond list key
- Use `>-` for line folding
- `true`/`false` booleans (not yes/no)
- Max 160 characters per line

**Review Points:**
- [ ] Consistent 2-space indentation
- [ ] No tabs used
- [ ] Lists properly indented
- [ ] Long lines broken appropriately
- [ ] Boolean values use true/false

**Example:**
```yaml
# Good
- name: Task with long conditional
  ansible.builtin.package:
    name: httpd
  when:
    - ansible_os_family == "RedHat"
    - ansible_distribution_major_version|int >= 8
    - httpd_enabled|bool
```

### Code Quality

#### ansible-lint Compliance

**Required:** Pass ansible-lint moderate profile

**Review Points:**
- [ ] No syntax errors
- [ ] FQCN used for all modules
- [ ] All tasks have names
- [ ] Names start with capital letter
- [ ] No deprecated modules
- [ ] File permissions explicitly set

**Check:**
```bash
ansible-lint --profile moderate .
```

#### Documentation

**Required for Roles:**
- Comprehensive README.md
- Variable documentation in defaults/main.yml
- meta/argument_specs.yml with descriptions

**Review Points:**
- [ ] README includes description
- [ ] README lists requirements
- [ ] README shows example usage
- [ ] Variables documented inline
- [ ] Capabilities listed
- [ ] Idempotency status stated
- [ ] Supported platforms listed

### Testing

#### Molecule Tests

**Required for Roles:**
- molecule/default/molecule.yml
- molecule/default/converge.yml
- molecule/default/verify.yml

**Review Points:**
- [ ] Molecule scenario exists
- [ ] Tests multiple platforms
- [ ] Idempotence test included
- [ ] Verification tests comprehensive
- [ ] ansible-lint integrated

#### Test Coverage

**Review Points:**
- [ ] Package installation verified
- [ ] Service state verified
- [ ] Configuration files verified
- [ ] Ports/listeners verified
- [ ] Idempotence passes

### Security

#### Credential Handling

**Rules:**
- Never hardcode credentials
- Use Ansible Vault for secrets
- Use no_log for sensitive tasks

**Review Points:**
- [ ] No plaintext passwords
- [ ] Vault used for secrets
- [ ] no_log on password tasks
- [ ] SSH keys not in repository
- [ ] API tokens externalized

**Example:**
```yaml
# Good
- name: Set user password
  ansible.builtin.user:
    name: alice
    password: "{{ user_password }}"
  no_log: true
```

#### Privilege Escalation

**Rules:**
- Use become sparingly
- Prefer become_user to root
- Document why become needed

**Review Points:**
- [ ] become only when necessary
- [ ] become_method specified
- [ ] Minimal privilege principle followed

## Common Issues & Fixes

### Issue 1: Generic Variable Names

**Problem:**
```yaml
# roles/apache_install/defaults/main.yml
version: "2.4"
port: 80
enabled: true
```

**Fix:**
```yaml
# roles/apache_install/defaults/main.yml
apache_install_version: "2.4"
apache_install_listen_port: 80
apache_install_service_enabled: true
```

### Issue 2: Non-Idempotent Tasks

**Problem:**
```yaml
- name: Install Apache
  ansible.builtin.shell: yum install -y httpd
```

**Fix:**
```yaml
- name: Install Apache
  ansible.builtin.package:
    name: httpd
    state: present
```

### Issue 3: Mixing Roles and Tasks

**Problem:**
```yaml
- name: Configure servers
  hosts: all
  roles:
    - base_config
  tasks:
    - name: Additional task
      ansible.builtin.command: something
```

**Fix:**
```yaml
# Option 1: Move task to role
- name: Configure servers
  hosts: all
  roles:
    - base_config
    - additional_config

# Option 2: Use only tasks
- name: Configure servers
  hosts: all
  tasks:
    - ansible.builtin.include_role:
        name: base_config
    - name: Additional task
      ansible.builtin.command: something
```

### Issue 4: Dashes in Role Names

**Problem:**
```
roles/
└── apache-install/  # Bad - dashes cause collection issues
```

**Fix:**
```
roles/
└── apache_install/  # Good - underscores
```

### Issue 5: Missing Platform Support

**Problem:**
```yaml
# tasks/main.yml
- name: Install Apache
  ansible.builtin.yum:
    name: httpd
    state: present
# Only works on RedHat
```

**Fix:**
```yaml
# tasks/main.yml
- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"

- name: Install Apache
  ansible.builtin.package:
    name: "{{ __apache_install_package_name }}"
    state: present

# vars/RedHat.yml
__apache_install_package_name: httpd

# vars/Debian.yml
__apache_install_package_name: apache2
```

## Review Report Template

Use this structure for review output:

```markdown
# Ansible CoP Review Report

## Summary
[Overall assessment - compliant/needs work/major issues]

## Scope Reviewed
- [x] Playbooks (3 files)
- [x] Roles (2 roles)
- [ ] Collections
- [x] Testing setup

## Critical Issues (Must Fix)
1. **Variable naming violations** (roles/apache/defaults/main.yml:5)
   - Using generic variable `port` instead of `apache_port`
   - Fix: Prefix all variables with role name

2. **Non-idempotent command** (roles/app/tasks/main.yml:12)
   - Command always runs without changed_when
   - Fix: Add `changed_when: false` or use creates parameter

## Warnings (Should Fix)
1. **Missing argument_specs.yml** (roles/apache/meta/)
   - No argument validation defined
   - Recommendation: Add meta/argument_specs.yml

2. **ansible-lint warnings** (multiple files)
   - 3 tasks missing FQCN
   - Fix: Use ansible.builtin.* for core modules

## Recommendations (Nice to Have)
1. Add Molecule tests for idempotence validation
2. Include more comprehensive README documentation
3. Add CI/CD integration for automated testing

## Strengths
- ✅ Good Type-Function pattern implementation
- ✅ Proper YAML formatting throughout
- ✅ Multi-platform support in place
- ✅ Comprehensive tagging strategy

## Next Steps
1. Fix all critical issues
2. Address warnings
3. Run ansible-lint --profile moderate
4. Test with Molecule
5. Re-review after fixes

## Resources
- Red Hat CoP: https://redhat-cop.github.io/automation-good-practices/
- ansible-lint rules: https://ansible-lint.readthedocs.io/
```

## Automated Checks

Run these commands for automated validation:

```bash
# Syntax check
find . -name "*.yml" -exec ansible-playbook --syntax-check {} \;

# ansible-lint
ansible-lint --profile moderate .

# Check for generic variable names
grep -r "^[^#]*: " roles/*/defaults/main.yml | grep -v "^[a-z_]*_"

# Check for dashes in role names
find roles/ -maxdepth 1 -type d -name "*-*"

# Verify .yml extension
find . -name "*.yaml"

# Check for missing argument_specs
find roles/ -maxdepth 2 -type d -name meta | while read meta; do
  if [ ! -f "$meta/argument_specs.yml" ]; then
    echo "Missing: $meta/argument_specs.yml"
  fi
done
```

## Review Workflow

When asked to review Ansible code:

1. **Understand the scope** - What needs reviewing?
2. **Read all relevant files** - Use Read, Grep, Glob tools
3. **Apply CoP standards** - Check against all criteria above
4. **Run automated checks** - ansible-lint, syntax validation
5. **Generate report** - Use template above
6. **Prioritize issues** - Critical → Warnings → Recommendations
7. **Provide fixes** - Show exact code changes needed
8. **Suggest next steps** - Clear action items

Remember: The goal is **constructive feedback** that helps improve code quality while maintaining Red Hat CoP compliance.
