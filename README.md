# Ansible Skills for Claude Code & OpenClaw

Comprehensive Ansible automation skills following Red Hat Communities of Practice (CoP) best practices.

## Overview

This plugin provides **eleven comprehensive skills** to help you create, develop, convert, troubleshoot, review, scaffold, configure, automate event-driven responses, guide interactive development, and manage Ansible Automation Platform with Ansible following industry best practices from Red Hat's Communities of Practice.

**Dual Compatible:** This plugin works with both [Claude Code](https://claude.ai/code) (Anthropic's official CLI) and [OpenClaw](https://openclaw.ai/) (open-source AI assistant platform) using the AgentSkills standard format.

**Marketplace Ready:** Includes marketplace.json for easy distribution and discovery in Claude Code plugin marketplaces.

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

### 5. **ansible-cop-review**
Review Ansible code against all Red Hat Communities of Practice automation good practices.

**Use when:** You want to validate existing code, ensure CoP compliance, or get code quality feedback.

**Triggers:** "review ansible code", "check CoP compliance", "validate against Red Hat standards", "cop review", "ansible best practices review"

### 6. **ansible-scaffold-collection**
Scaffold new Ansible collections following Red Hat CoP structure and standards.

**Use when:** You need to create a new Ansible content collection with proper organization and packaging.

**Triggers:** "create a collection", "new collection", "scaffold collection", "ansible collection structure", "build a collection"

### 7. **ansible-scaffold-ee**
Scaffold and build Ansible Execution Environments (containerized Ansible runtime) using ansible-builder.

**Use when:** You need to create a custom execution environment with specific collections, dependencies, or system packages.

**Triggers:** "create execution environment", "scaffold ee", "ansible-builder", "build execution environment", "custom ee image"

### 8. **ansible-navigator-config**
Configure ansible-navigator for optimal workflow, execution environment integration, and troubleshooting.

**Use when:** You need to set up ansible-navigator configuration, integrate with execution environments, or optimize CI/CD workflows.

**Triggers:** "configure ansible-navigator", "setup navigator", "navigator config", "ansible-navigator settings", "navigator ee integration"

### 9. **ansible-eda-rulebook**
Create Event-Driven Ansible rulebooks that respond to events from various sources for automated infrastructure response.

**Use when:** You need to automate responses to monitoring alerts, security events, CI/CD triggers, or any event-driven automation scenario.

**Triggers:** "create eda rulebook", "event-driven ansible", "ansible rulebook", "webhook automation", "event automation", "integrate event source"

### 10. **ansible-interactive**
Interactive step-by-step guided Ansible development workflow from environment setup through playbook deployment.

**Use when:** You need hands-on guidance through Ansible development, want to learn best practices interactively, or prefer incremental validated development.

**Triggers:** "guide me through ansible", "interactive ansible setup", "step by step ansible", "walk me through ansible", "help me start with ansible"

### 11. **aap-config-as-code**
Configure Ansible Automation Platform as code using Red Hat CoP infra.aap_configuration collection for infrastructure-as-code management.

**Use when:** You need to manage AAP configuration as version-controlled code, deploy multi-environment AAP setups, or automate AAP platform configuration.

**Triggers:** "configure AAP as code", "aap configuration management", "manage AAP with ansible", "aap infrastructure as code", "configure automation controller"

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

### For Claude Code

#### Option 1: Clone into Claude Code plugins directory

```bash
cd ~/.claude/plugins/
git clone <repository-url> ansible-skills
```

#### Option 2: Use as local plugin

```bash
# Clone to any directory
git clone <repository-url> /path/to/ansible-skills

# Symlink to Claude Code plugins directory
ln -s /path/to/ansible-skills ~/.claude/plugins/ansible-skills
```

#### Verify Installation

The plugin should be automatically detected by Claude Code:

```bash
claude plugins list
```

### For OpenClaw

#### Option 1: Install Local Plugin

```bash
# Clone the repository
git clone <repository-url> /path/to/ansible-skills

# Install as OpenClaw plugin
openclaw plugin install /path/to/ansible-skills
```

#### Option 2: Install Individual Skills from Local Directory

```bash
cd /path/to/ansible-skills

# Install all skills
openclaw skills install skills/playbook-creator
openclaw skills install skills/role-developer
openclaw skills install skills/shell-to-ansible
openclaw skills install skills/ansible-troubleshooter
openclaw skills install skills/ansible-cop-review
openclaw skills install skills/ansible-scaffold-collection
openclaw skills install skills/ansible-scaffold-ee
openclaw skills install skills/ansible-navigator-config
openclaw skills install skills/ansible-eda-rulebook
openclaw skills install skills/ansible-interactive
openclaw skills install skills/aap-config-as-code
```

#### Verify Installation

```bash
openclaw skills list
```

### Compatibility

Both platforms use the **AgentSkills standard format** developed by Anthropic, ensuring seamless compatibility:
- ✅ Same SKILL.md frontmatter structure
- ✅ Compatible markdown instruction format
- ✅ Cross-platform skill loading
- ✅ Shared skill ecosystem

## Quick Start

### Creating a Playbook

**Claude Code:**
```
You: Create a playbook for web server type following Red Hat CoP
```

**OpenClaw:**
```
You: /skill playbook-creator - Create a playbook for web server type
```

The AI will invoke the `playbook-creator` skill and generate a playbook following the Type-Function pattern with proper structure and tagging.

### Developing a Role

**Claude Code:**
```
You: Create a new role for apache_install
```

**OpenClaw:**
```
You: /skill role-developer - Create a new role for apache_install
```

The AI will invoke the `role-developer` skill and generate:
- Complete role directory structure
- Argument validation in `meta/argument_specs.yml`
- Platform-specific variable files
- Molecule test scenario
- ansible-lint configuration
- Comprehensive README

### Converting Shell Scripts

**Claude Code:**
```
You: Convert this bash script to an Ansible playbook
```

**OpenClaw:**
```
You: /skill shell-to-ansible - Convert this bash script to Ansible
```

The AI will invoke the `shell-to-ansible` skill and transform procedural shell commands into declarative, idempotent Ansible tasks using appropriate modules.

### Troubleshooting

**Claude Code:**
```
You: Debug this ansible playbook error
```

**OpenClaw:**
```
You: /skill ansible-troubleshooter - Debug this playbook error
```

The AI will invoke the `ansible-troubleshooter` skill to diagnose issues, suggest fixes, and provide debugging strategies.

### Reviewing Code

**Claude Code:**
```
You: Review this Ansible role against Red Hat CoP standards
```

**OpenClaw:**
```
You: /skill ansible-cop-review - Review my playbook for CoP compliance
```

The AI will invoke the `ansible-cop-review` skill to analyze code against Red Hat CoP standards and provide detailed feedback.

### Scaffolding a Collection

**Claude Code:**
```
You: Create a new Ansible collection called company.infrastructure
```

**OpenClaw:**
```
You: /skill ansible-scaffold-collection - Scaffold collection namespace.collection_name
```

The AI will invoke the `ansible-scaffold-collection` skill to create a complete collection structure with all required files.

### Scaffolding an Execution Environment

**Claude Code:**
```
You: Create a custom execution environment with ansible.posix and kubernetes.core collections
```

**OpenClaw:**
```
You: /skill ansible-scaffold-ee - Build EE with specific collections
```

The AI will invoke the `ansible-scaffold-ee` skill to create an execution environment definition and build process.

### Configuring ansible-navigator

**Claude Code:**
```
You: Configure ansible-navigator for development with custom EE
```

**OpenClaw:**
```
You: /skill ansible-navigator-config - Setup navigator for CI/CD
```

The AI will invoke the `ansible-navigator-config` skill to create appropriate ansible-navigator.yml configuration files.

### Creating EDA Rulebooks

**Claude Code:**
```
You: Create an EDA rulebook for webhook-based monitoring with automated remediation
```

**OpenClaw:**
```
You: /skill ansible-eda-rulebook - Create rulebook for Prometheus Alertmanager integration
```

The AI will invoke the `ansible-eda-rulebook` skill to create event-driven automation rulebooks with appropriate event sources, conditions, and actions.

### Interactive Guided Development

**Claude Code:**
```
You: Guide me through setting up my first Ansible project step by step
```

**OpenClaw:**
```
You: /skill ansible-interactive - Walk me through Ansible development
```

The AI will invoke the `ansible-interactive` skill to provide hands-on, incremental guidance through environment setup, connectivity testing, playbook development, and deployment.

### Configuring AAP as Code

**Claude Code:**
```
You: Configure Ansible Automation Platform as code with multi-environment support
```

**OpenClaw:**
```
You: /skill aap-config-as-code - Set up AAP configuration for dev/qa/prod environments
```

The AI will invoke the `aap-config-as-code` skill to create infrastructure-as-code configuration for AAP using the Red Hat CoP infra.aap_configuration collection.

## Project Structure

```
ansible-skills/
├── .claude-plugin/
│   ├── plugin.json              # Claude Code plugin metadata
│   └── marketplace.json         # Marketplace distribution config
├── openclaw.plugin.json         # OpenClaw plugin metadata
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
│   ├── ansible-troubleshooter/  # Debugging skill
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   └── references/
│   ├── ansible-cop-review/      # Code review skill
│   │   ├── SKILL.md
│   │   └── templates/
│   ├── ansible-scaffold-collection/  # Collection scaffolding skill
│   │   ├── SKILL.md
│   │   └── templates/
│   ├── ansible-scaffold-ee/     # Execution environment skill
│   │   ├── SKILL.md
│   │   └── templates/
│   ├── ansible-navigator-config/  # Navigator configuration skill
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   └── examples/
│   ├── ansible-eda-rulebook/    # Event-driven automation skill
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   ├── examples/
│   │   └── references/
│   ├── ansible-interactive/     # Interactive guided development skill
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   ├── examples/
│   │   └── references/
│   └── aap-config-as-code/      # AAP configuration as code skill
│       ├── SKILL.md
│       ├── templates/
│       ├── examples/
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

## Platform-Specific Notes

### Claude Code
- Skills auto-activate based on trigger phrases in conversations
- Access via natural language prompts
- Integrated with Claude's context window

### OpenClaw
- Skills can be invoked via `/skill <skill-name>` command
- Works with multiple AI providers (Claude, GPT-4, DeepSeek, Gemini)
- Can integrate with messaging platforms (Signal, Telegram, Discord, WhatsApp)

## File Structure

```
ansible-skills/
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin metadata
├── openclaw.plugin.json         # OpenClaw plugin metadata
├── skills/
│   ├── playbook-creator/
│   │   ├── SKILL.md            # Skill definition (AgentSkills format)
│   │   ├── templates/          # Playbook templates
│   │   └── examples/           # Example playbooks
│   ├── role-developer/
│   │   ├── SKILL.md
│   │   ├── templates/          # Role skeleton & Molecule scenarios
│   │   ├── examples/           # Example roles
│   │   └── references/         # Reference documentation
│   ├── shell-to-ansible/
│   │   ├── SKILL.md
│   │   ├── examples/           # Before/after conversions
│   │   └── references/         # Module mappings & patterns
│   └── ansible-troubleshooter/
│       ├── SKILL.md
│       ├── templates/          # Troubleshooting checklists
│       └── references/         # Debugging guides
├── README.md
└── LICENSE
```

## Contributing

Contributions are welcome! Please:

1. Follow Red Hat CoP standards in all examples
2. Test templates with ansible-lint (moderate profile)
3. Validate YAML syntax
4. Ensure compatibility with both Claude Code and OpenClaw
5. Test skills on multiple platforms
6. Update documentation

### Testing Your Changes

**Claude Code:**
```bash
claude plugins reload
claude plugins list
```

**OpenClaw:**
```bash
openclaw skills inspect <skill-name>
openclaw skills install /path/to/skill
```

## Support & Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [OpenClaw Documentation](https://docs.openclaw.ai/)
- [ClawHub Skill Registry](https://clawhub.ai/)
- [Red Hat CoP - Ansible Good Practices](https://redhat-cop.github.io/automation-good-practices/)
- [AgentSkills Standard Format](https://openclaw-ai.com/en/docs/tools/skills)

## License

MIT License - See LICENSE file for details
