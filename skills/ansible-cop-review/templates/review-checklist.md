# Red Hat CoP Review Checklist

Quick reference checklist for reviewing Ansible code against Red Hat Communities of Practice standards.

## Project Structure

- [ ] Inventory separated by environment (production/, staging/)
- [ ] Playbooks organized by type/landscape
- [ ] ansible.cfg present with proper configuration
- [ ] Collections requirements defined
- [ ] Root README.md exists

## Naming Conventions

- [ ] All YAML files use `.yml` extension (not `.yaml`)
- [ ] Role names use underscores (not dashes)
- [ ] All variables use snake_case
- [ ] No abbreviations in names
- [ ] Names are descriptive and clear

## Role Variables

- [ ] All variables prefixed with role name (`rolename_variable`)
- [ ] Internal variables use double underscore (`__rolename_internal`)
- [ ] No generic names (version, port, enabled)
- [ ] Variables documented in defaults/main.yml
- [ ] Platform-specific vars in separate files (vars/RedHat.yml, vars/Debian.yml)

## Role Structure

Required files:
- [ ] defaults/main.yml exists
- [ ] tasks/main.yml exists
- [ ] meta/main.yml exists
- [ ] meta/argument_specs.yml exists (Ansible 2.11+)
- [ ] README.md exists and is comprehensive

Recommended files:
- [ ] handlers/main.yml for service management
- [ ] vars/RedHat.yml for RHEL-specific variables
- [ ] vars/Debian.yml for Debian-specific variables
- [ ] molecule/ directory for testing

## Argument Validation

- [ ] meta/argument_specs.yml exists
- [ ] All user-facing variables defined
- [ ] Types specified (str, int, bool, list, dict, path)
- [ ] Required variables marked
- [ ] Default values documented
- [ ] Descriptions provided

## Idempotency

- [ ] Uses declarative modules (package, service, file, copy, template)
- [ ] Commands have `creates`, `removes`, or `changed_when`
- [ ] No shell scripts that always run
- [ ] Templates don't include dynamic timestamps
- [ ] Molecule idempotence test exists and passes

## Multi-Platform Support

- [ ] Platform variables loaded via include_vars
- [ ] Package names mapped per OS (vars/RedHat.yml, vars/Debian.yml)
- [ ] Service names mapped per OS
- [ ] File paths mapped per OS
- [ ] Uses generic modules when possible (package vs yum/apt)

## Type-Function Pattern

- [ ] Type playbooks exist (web_server.yml, database.yml, etc.)
- [ ] Each type applies multiple function roles
- [ ] Landscape playbooks import type playbooks
- [ ] Playbooks are simple role lists
- [ ] No complex logic embedded in playbooks

## Playbook Design

- [ ] Uses `roles` OR `tasks` section (not both)
- [ ] Minimal embedded logic
- [ ] Variables defined in inventory (not playbook)
- [ ] Complex logic delegated to roles
- [ ] Descriptive play names

## Tagging Strategy

- [ ] All roles have tags
- [ ] First tag is exact role name
- [ ] Additional tags by category (install, configure, security)
- [ ] Tags don't imply required execution order
- [ ] Tags enable selective execution

## YAML Formatting

- [ ] Consistent 2-space indentation
- [ ] No tabs used
- [ ] Lists indented beyond list key
- [ ] Long lines broken appropriately (max 160 chars)
- [ ] Boolean values use `true`/`false` (not yes/no)
- [ ] Line folding uses `>-` when needed
- [ ] Long `when` conditions broken into lists

## ansible-lint Compliance

- [ ] No syntax errors
- [ ] FQCN used for all modules (ansible.builtin.*)
- [ ] All tasks have descriptive names
- [ ] Task names start with capital letter
- [ ] No deprecated modules used
- [ ] File permissions explicitly set (mode parameter)
- [ ] Commands have `changed_when` defined
- [ ] Passes `ansible-lint --profile moderate`

## Documentation

Role README must include:
- [ ] Description of what role does
- [ ] Requirements (Ansible version, platforms)
- [ ] Variable documentation table
- [ ] Example playbook usage
- [ ] Dependencies listed
- [ ] Capabilities listed
- [ ] Idempotency status stated
- [ ] Rollback capabilities documented
- [ ] Supported platforms listed
- [ ] License information
- [ ] Author information

## Testing

- [ ] Molecule scenario exists (molecule/default/)
- [ ] molecule.yml configured for multiple platforms
- [ ] converge.yml applies the role
- [ ] verify.yml validates results
- [ ] Idempotence test passes
- [ ] ansible-lint integrated in molecule.yml
- [ ] Tests verify package installation
- [ ] Tests verify service state
- [ ] Tests verify configuration files
- [ ] Tests verify ports/listeners

## Security

- [ ] No hardcoded passwords or credentials
- [ ] Ansible Vault used for secrets
- [ ] `no_log: true` on sensitive tasks
- [ ] SSH keys not in repository
- [ ] API tokens externalized
- [ ] `become` only used when necessary
- [ ] `become_method` specified explicitly
- [ ] Minimal privilege principle followed

## Handlers

- [ ] Service restarts in handlers (not tasks)
- [ ] Handlers have clear names
- [ ] Handlers only run when notified
- [ ] Validation handlers use `changed_when: false`

## Templates

- [ ] Include `{{ ansible_managed }}` comment
- [ ] No dynamic timestamps
- [ ] Proper Jinja2 syntax
- [ ] Variables have defaults or checks
- [ ] File permissions set on deployment

## Common Anti-Patterns to Avoid

- [ ] No generic variable names without role prefix
- [ ] No mixing roles and tasks in same play
- [ ] No dashes in role names
- [ ] No `state: latest` without justification
- [ ] No shell/command without creates/removes/changed_when
- [ ] No hardcoded platform-specific values in tasks
- [ ] No abbreviations in names
- [ ] No `.yaml` file extension
- [ ] No timestamp-based config generation
- [ ] No `--no-verify` or hook bypassing

## Quick Validation Commands

```bash
# Check YAML syntax
ansible-playbook --syntax-check playbook.yml

# Run ansible-lint
ansible-lint --profile moderate .

# Find generic variable names
grep -r "^[^#_]*: " roles/*/defaults/main.yml | grep -vE "^[a-z_]+_[a-z_]+"

# Find roles with dashes
find roles/ -maxdepth 1 -type d -name "*-*"

# Find .yaml files
find . -name "*.yaml"

# Check for missing argument_specs
find roles/*/meta -type d | while read d; do
  [ ! -f "$d/argument_specs.yml" ] && echo "Missing: $d/argument_specs.yml"
done

# Test idempotence with Molecule
cd roles/role_name && molecule idempotence
```

## Severity Levels

**Critical (Must Fix):**
- Variable naming violations
- Non-idempotent operations
- Security issues
- Syntax errors
- Missing required files

**Warning (Should Fix):**
- Missing argument_specs.yml
- ansible-lint warnings
- Incomplete documentation
- Missing platform support
- No Molecule tests

**Recommendation (Nice to Have):**
- Additional test coverage
- CI/CD integration
- More comprehensive examples
- Performance optimizations
