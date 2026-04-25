# ansible-lint Key Rules Reference

Common ansible-lint rules and how to fix violations. Red Hat CoP recommends the `moderate` profile.

## Rule Categories

### Syntax and Formatting

#### `yaml[line-length]` - Line too long

Lines should not exceed 160 characters.

**Bad:**
```yaml
- name: This is a very long task name that goes on and on and describes every single detail about what the task does in excruciating detail which makes it exceed the line length limit
```

**Good:**
```yaml
- name: Configure application with recommended settings
  # Add detailed explanation in a comment if needed
```

#### `yaml[trailing-spaces]` - Trailing whitespace

Remove trailing spaces at end of lines.

**Fix:** Configure your editor to remove trailing whitespace automatically.

#### `yaml[indentation]` - Incorrect indentation

Use consistent 2-space indentation.

**Bad:**
```yaml
tasks:
    - name: Task
      package:
          name: httpd
```

**Good:**
```yaml
tasks:
  - name: Task
    ansible.builtin.package:
      name: httpd
```

### Naming and Documentation

#### `name[missing]` - Task should have a name

All tasks must have descriptive names.

**Bad:**
```yaml
- ansible.builtin.package:
    name: httpd
```

**Good:**
```yaml
- name: Install Apache web server
  ansible.builtin.package:
    name: httpd
```

#### `name[casing]` - Improper name casing

Task names should start with a capital letter.

**Bad:**
```yaml
- name: install apache
```

**Good:**
```yaml
- name: Install Apache
```

#### `name[template]` - Template in name

Avoid Jinja2 templates in task names.

**Bad:**
```yaml
- name: Install {{ package_name }}
```

**Good:**
```yaml
- name: Install configured package
  ansible.builtin.package:
    name: "{{ package_name }}"
```

### Module Usage

#### `fqcn[action-core]` - Use FQCN for builtin modules

Use fully qualified collection names (FQCN) for all modules.

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

#### `no-changed-when` - Commands should have changed_when

Commands should define when they cause changes.

**Bad:**
```yaml
- name: Check configuration
  ansible.builtin.command: httpd -t
```

**Good:**
```yaml
- name: Check configuration
  ansible.builtin.command: httpd -t
  changed_when: false
```

#### `no-free-form` - Avoid free-form syntax

Use explicit parameter syntax.

**Bad:**
```yaml
- name: Install package
  ansible.builtin.command: yum install -y httpd
```

**Good:**
```yaml
- name: Install package
  ansible.builtin.yum:
    name: httpd
    state: present
```

#### `package-latest` - Avoid using state: latest

Pin specific versions or use `state: present`.

**Bad:**
```yaml
- name: Install Apache
  ansible.builtin.package:
    name: httpd
    state: latest  # Unpredictable updates
```

**Good:**
```yaml
- name: Install Apache
  ansible.builtin.package:
    name: httpd-2.4.53
    state: present

# Or if latest is intentional, document why
- name: Ensure Apache is up-to-date
  ansible.builtin.package:
    name: httpd
    state: latest
  # Latest required for security patches
```

### Best Practices

#### `literal-compare` - Don't compare with literal True/False

Use direct boolean checks.

**Bad:**
```yaml
when: my_var == True
when: my_var == False
```

**Good:**
```yaml
when: my_var | bool
when: not my_var | bool
```

#### `deprecated-module` - Module is deprecated

Replace deprecated modules with current alternatives.

**Bad:**
```yaml
- apt_repository:  # Deprecated
```

**Good:**
```yaml
- ansible.builtin.deb822_repository:
```

#### `risky-file-permissions` - File permissions not set

Always specify file permissions explicitly.

**Bad:**
```yaml
- name: Create file
  ansible.builtin.copy:
    content: "data"
    dest: /etc/app/config
```

**Good:**
```yaml
- name: Create file
  ansible.builtin.copy:
    content: "data"
    dest: /etc/app/config
    owner: root
    group: root
    mode: '0644'
```

#### `risky-shell-pipe` - Risky shell piping

Avoid shell pipes, use modules instead.

**Bad:**
```yaml
- name: Get package list
  ansible.builtin.shell: rpm -qa | grep httpd
```

**Good:**
```yaml
- name: Get package facts
  ansible.builtin.package_facts:

- name: Check if Apache installed
  ansible.builtin.assert:
    that: "'httpd' in ansible_facts.packages"
```

### Security

#### `no-log-password` - Password in clear text

Passwords should use `no_log: true`.

**Bad:**
```yaml
- name: Set user password
  ansible.builtin.user:
    name: alice
    password: "{{ user_password }}"
```

**Good:**
```yaml
- name: Set user password
  ansible.builtin.user:
    name: alice
    password: "{{ user_password }}"
  no_log: true
```

#### `var-naming` - Invalid variable name

Variables should use snake_case, no special characters.

**Bad:**
```yaml
vars:
  My-Variable: value
  camelCaseVar: value
```

**Good:**
```yaml
vars:
  my_variable: value
  my_other_variable: value
```

### Jinja2 Templates

#### `jinja[spacing]` - Jinja2 spacing

Consistent spacing in Jinja2 expressions.

**Bad:**
```yaml
msg: "{{variable}}"
when: "{{condition}}"
```

**Good:**
```yaml
msg: "{{ variable }}"
when: condition | bool  # No quotes or braces needed in when
```

#### `jinja[invalid]` - Invalid Jinja2

Syntax errors in Jinja2 templates.

**Fix:** Check Jinja2 syntax, common issues:
- Unclosed `{{` or `{%`
- Wrong filter syntax
- Undefined variables

### Playbook Structure

#### `syntax-check` - Ansible syntax error

Basic Ansible syntax violations.

**Fix:** Run `ansible-playbook --syntax-check` for details.

#### `key-order` - Wrong key order in mappings

Follow standard task key order.

**Good order:**
```yaml
- name: Task name
  become: true
  ansible.builtin.package:
    name: httpd
    state: present
  when: condition
  tags: ['tag']
  notify: Handler name
```

## Profile-Specific Rules

### Moderate Profile (Red Hat CoP)

The `moderate` profile includes:
- All `min` and `basic` rules
- Best practice rules
- Moderate safety rules
- Recommended formatting

**Configure:**
```yaml
# .ansible-lint
---
profile: moderate
```

### Production Profile

Stricter than moderate, recommended for production roles:

```yaml
# .ansible-lint
---
profile: production
```

## Configuring ansible-lint

### Skip Specific Rules

```yaml
# .ansible-lint
---
profile: moderate

skip_list:
  - yaml[line-length]  # Only if you have legitimate need
  - name[template]     # Only if necessary
```

### Warn Instead of Fail

```yaml
# .ansible-lint
---
warn_list:
  - experimental  # Warn about experimental features
  - name[casing]  # Warn about casing but don't fail
```

### Exclude Paths

```yaml
# .ansible-lint
---
exclude_paths:
  - .cache/
  - .git/
  - molecule/
  - tests/
```

## Running ansible-lint

```bash
# Basic lint
ansible-lint playbook.yml

# With specific profile
ansible-lint --profile moderate playbook.yml

# Lint a role
ansible-lint roles/my_role/

# Show all issues (including warnings)
ansible-lint -p playbook.yml

# List all available rules
ansible-lint --list-rules

# Explain a specific rule
ansible-lint -r rule_name

# Generate baseline (ignore existing issues)
ansible-lint --generate-ignore
```

## CI/CD Integration

### GitLab CI

```yaml
# .gitlab-ci.yml
ansible-lint:
  stage: test
  script:
    - pip install ansible-lint
    - ansible-lint --profile moderate .
```

### GitHub Actions

```yaml
# .github/workflows/ansible-lint.yml
name: Ansible Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run ansible-lint
        uses: ansible/ansible-lint-action@main
        with:
          args: "--profile moderate"
```

## Quick Reference

| Rule | Issue | Fix |
|------|-------|-----|
| `name[missing]` | No task name | Add `name:` to all tasks |
| `fqcn[action-core]` | No FQCN | Use `ansible.builtin.module` |
| `no-changed-when` | Command without changed_when | Add `changed_when: false` or condition |
| `yaml[line-length]` | Line > 160 chars | Break into multiple lines |
| `risky-file-permissions` | No file mode | Add `mode: '0644'` |
| `package-latest` | Uses state: latest | Use specific version or document why |
| `literal-compare` | `== True/False` | Use `\| bool` filter |

## Resources

- ansible-lint documentation: https://ansible-lint.readthedocs.io/
- Red Hat CoP: https://redhat-cop.github.io/automation-good-practices/
- Ansible best practices: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
