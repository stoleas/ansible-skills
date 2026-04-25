# Ansible Skills for Claude Code

Comprehensive Ansible automation skills following Red Hat Communities of Practice (CoP) best practices.

## Overview

This plugin provides four specialized skills to help you create, develop, convert, and troubleshoot Ansible automation following industry best practices from Red Hat's Communities of Practice.

## Skills Included

### 1. **playbook-creator**
Create Ansible playbooks from scratch following the Type-Function pattern and Red Hat CoP standards.

**Use when:** You need to write a new playbook, implement the Type-Function pattern, or create landscape playbooks.

**Triggers:** "create a playbook", "new playbook", "write a playbook", "ansible playbook for"

### 2. **role-developer**
Develop complete Ansible roles with proper structure, testing, and validation.

**Use when:** You need to create a new role with complete skeleton, Molecule tests, and ansible-lint configuration.

**Triggers:** "create a role", "new role", "develop a role", "ansible role for", "role skeleton"

### 3. **shell-to-ansible**
Convert shell scripts to idempotent Ansible playbooks using declarative patterns.

**Use when:** You have existing shell scripts that need to be migrated to Ansible automation.

**Triggers:** "convert shell script", "bash to ansible", "shell to playbook", "migrate script to ansible"

### 4. **ansible-troubleshooter**
Debug, troubleshoot, and validate Ansible playbooks and roles using ansible-lint and Molecule.

**Use when:** You encounter errors, want to validate playbooks, or need debugging strategies.

**Triggers:** "debug ansible", "troubleshoot playbook", "ansible not working", "fix ansible error", "ansible lint"

## Red Hat CoP Best Practices

All skills in this plugin enforce the following Red Hat Communities of Practice standards:

### Type-Function Pattern
- Each managed host has exactly one **type** (e.g., web-server, database, middleware)
- Types are composed of reusable **function roles**
- Playbooks remain simple lists of roles
- Enables scalable, maintainable infrastructure automation

### Role Standards
- **Variable Naming**: All role variables prefixed with role name (`rolename_variable`)
- **Internal Variables**: Double underscore prefix (`__rolename_internal`)
- **Idempotency**: Mandatory - roles must not report changes on repeated identical runs
- **Check Mode**: Required support
- **Multi-Distribution**: Platform-specific variables via `include_vars`
- **Argument Validation**: Using `meta/argument_specs.yml` (Ansible 2.11+)

### Naming Conventions
- Snake_case exclusively - no dashes, no abbreviations
- `.yml` extension (not `.yaml`)
- No dashes in role names (causes collection issues)

### YAML Formatting
- Two-space indentation
- Indent list contents beyond list definition
- Use `>-` for line folding
- Break long `when:` conditions into lists
- Use `true`/`false` booleans (YAML 1.2)

### Testing Requirements
- **ansible-lint**: Moderate profile minimum
- **Molecule**: For role testing with idempotence validation
- **Multi-Platform**: Test across distributions

## Installation

### Option 1: Clone into Claude Code plugins directory

```bash
cd ~/.claude/plugins/
git clone <repository-url> ansible-skills
```

### Option 2: Use as local plugin

```bash
# Clone to any directory
git clone <repository-url> /path/to/ansible-skills

# Symlink to Claude Code plugins directory
ln -s /path/to/ansible-skills ~/.claude/plugins/ansible-skills
```

### Enable the Plugin

The plugin should be automatically detected by Claude Code. Verify with:

```bash
claude plugins list
```

## Quick Start

### Creating a Playbook

```
You: Create a playbook for web server type following Red Hat CoP
```

Claude will invoke the `playbook-creator` skill and generate a playbook following the Type-Function pattern with proper structure and tagging.

### Developing a Role

```
You: Create a new role for apache_install
```

Claude will invoke the `role-developer` skill and generate:
- Complete role directory structure
- Argument validation in `meta/argument_specs.yml`
- Platform-specific variable files
- Molecule test scenario
- ansible-lint configuration
- Comprehensive README

### Converting Shell Scripts

```
You: Convert this bash script to an Ansible playbook
```

Claude will invoke the `shell-to-ansible` skill and transform procedural shell commands into declarative, idempotent Ansible tasks using appropriate modules.

### Troubleshooting

```
You: Debug this ansible playbook error
```

Claude will invoke the `ansible-troubleshooter` skill to diagnose issues, suggest fixes, and provide debugging strategies.

## Project Structure

```
ansible-skills/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── skills/
│   ├── playbook-creator/        # Playbook creation skill
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   └── examples/
│   ├── role-developer/          # Role development skill
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   ├── examples/
│   │   └── references/
│   ├── shell-to-ansible/        # Shell conversion skill
│   │   ├── SKILL.md
│   │   ├── examples/
│   │   └── references/
│   └── ansible-troubleshooter/  # Debugging skill
│       ├── SKILL.md
│       ├── templates/
│       └── references/
├── README.md
└── LICENSE
```

## Examples

### Type Playbook Structure

```yaml
---
# Type Playbook: web_server
# Description: Manages web server hosts

- name: Configure web server type
  hosts: web_server
  become: true
  
  roles:
    - role: namespace.collection.base_linux
      tags: ['base', 'os']
    
    - role: namespace.collection.apache_install
      tags: ['apache', 'web']
    
    - role: namespace.collection.firewall_config
      tags: ['firewall', 'security']
```

### Role Variable Naming

```yaml
---
# Good - follows Red Hat CoP
apache_install_version: "2.4"
apache_install_listen_port: 80
__apache_install_temp_path: "/tmp/apache"  # Internal variable

# Bad - does not follow standards
version: "2.4"              # No prefix
apache-port: 80             # Uses dash instead of underscore
apacheInstallPort: 80       # CamelCase not allowed
```

## Testing Your Generated Content

### Syntax Validation

```bash
# Check playbook syntax
ansible-playbook --syntax-check playbook.yml

# Lint with Red Hat CoP standards
ansible-lint --profile moderate playbook.yml
```

### Role Testing

```bash
# Run Molecule tests
cd roles/your_role/
molecule test

# Test idempotence specifically
molecule converge
molecule idempotence
```

## Dependencies

To use all features of this plugin, install:

```bash
# Core Ansible
pip install ansible-core

# Linting and testing
pip install ansible-lint molecule molecule-plugins[podman]

# YAML validation
pip install yamllint
```

## Resources

- [Red Hat Communities of Practice - Good Practices for Ansible](https://redhat-cop.github.io/automation-good-practices/)
- [Ansible Documentation](https://docs.ansible.com/)
- [ansible-lint Rules](https://ansible-lint.readthedocs.io/)
- [Molecule Documentation](https://molecule.readthedocs.io/)

## Contributing

Contributions are welcome! Please:

1. Follow Red Hat CoP standards in all examples
2. Test templates with ansible-lint (moderate profile)
3. Validate YAML syntax
4. Update documentation

## License

MIT License - See LICENSE file for details
