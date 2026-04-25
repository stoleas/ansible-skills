---
name: ansible-scaffold-collection
description: >
  Scaffold new Ansible collections following Red Hat Communities of Practice structure and
  standards. Use this skill when the user asks to: "create a collection", "new collection",
  "scaffold collection", "ansible collection structure", "build a collection", "collection template",
  "initialize collection", or wants to create a new Ansible content collection. Always invoke
  this skill for collection scaffolding tasks.
version: 1.0.0
allowed-tools: [Write, Bash, Read]
---

# Ansible Collection Scaffolding Skill

Scaffold complete Ansible collections following Red Hat Communities of Practice (CoP) standards with proper structure, documentation, and testing setup.

## What is an Ansible Collection?

An Ansible Collection is a distribution format for Ansible content that can contain:
- **Roles** - Reusable automation units
- **Modules** - Custom Ansible modules
- **Plugins** - Various plugin types (filters, lookups, inventory, etc.)
- **Playbooks** - Example playbooks and workflows
- **Documentation** - Comprehensive guides and references

Collections enable:
- Packaging related automation together
- Versioning and distribution via Ansible Galaxy
- Namespace isolation
- Reusable content across organizations

## Collection Naming

**Format:** `namespace.collection_name`

**Rules:**
- **Namespace**: Organization or author identifier (lowercase, underscores allowed)
- **Collection name**: Descriptive name (lowercase, underscores allowed, no dashes)
- Both must be valid Python identifiers
- Examples: `company.infrastructure`, `redhat.rhel_system_roles`, `community.general`

## Collection Structure

Complete Red Hat CoP compliant collection:

```
namespace/
└── collection_name/
    ├── galaxy.yml                 # Collection metadata (REQUIRED)
    ├── README.md                  # Collection documentation (REQUIRED)
    ├── docs/                      # Additional documentation
    │   ├── getting_started.md
    │   └── guides/
    ├── meta/
    │   └── runtime.yml            # Runtime metadata
    ├── roles/                     # Collection roles
    │   ├── role_name_1/
    │   │   ├── defaults/
    │   │   ├── handlers/
    │   │   ├── meta/
    │   │   │   ├── main.yml
    │   │   │   └── argument_specs.yml
    │   │   ├── tasks/
    │   │   ├── templates/
    │   │   ├── vars/
    │   │   ├── README.md
    │   │   └── molecule/
    │   └── role_name_2/
    ├── plugins/                   # Collection plugins
    │   ├── modules/               # Custom modules
    │   │   └── module_name.py
    │   ├── module_utils/          # Shared module utilities
    │   ├── filter/                # Jinja2 filters
    │   ├── lookup/                # Lookup plugins
    │   ├── inventory/             # Inventory plugins
    │   ├── callback/              # Callback plugins
    │   └── action/                # Action plugins
    ├── playbooks/                 # Example playbooks
    │   ├── example_1.yml
    │   └── example_2.yml
    ├── tests/                     # Collection-level tests
    │   ├── integration/
    │   │   └── targets/
    │   └── unit/
    │       └── plugins/
    ├── changelogs/                # Changelog management
    │   ├── config.yaml
    │   └── changelog.yaml
    ├── .ansible-lint              # Linting configuration
    ├── .yamllint                  # YAML linting configuration
    ├── .gitignore
    └── LICENSE
```

## galaxy.yml - Collection Metadata

**Required fields:**

```yaml
---
namespace: company
name: infrastructure
version: 1.0.0
readme: README.md
authors:
  - Your Name <your.email@company.com>
description: >
  Infrastructure automation collection for managing servers,
  networking, and cloud resources following Red Hat CoP standards.
license:
  - MIT
license_file: LICENSE

tags:
  - infrastructure
  - automation
  - cloud
  - networking

dependencies: {}
  # Other collections this depends on
  # ansible.posix: ">=1.0.0"

repository: https://github.com/company/ansible-infrastructure
documentation: https://docs.company.com/ansible-infrastructure
homepage: https://company.com/automation
issues: https://github.com/company/ansible-infrastructure/issues
```

**Optional but recommended:**

```yaml
# Collection build configuration
build_ignore:
  - .git
  - .gitignore
  - .DS_Store
  - '*.pyc'
  - '*.retry'
  - tests/output
  - .vscode
  - .idea
```

## meta/runtime.yml - Runtime Metadata

Defines collection requirements and redirects:

```yaml
---
requires_ansible: '>=2.11.0'

plugin_routing:
  # Redirect old module names to new ones
  modules:
    old_module_name:
      redirect: namespace.collection.new_module_name
      deprecation:
        removal_version: "2.0.0"
        warning_text: Use namespace.collection.new_module_name instead

action_groups:
  # Group modules for easier reference
  cloud:
    - aws_ec2
    - azure_vm
    - gcp_compute
```

## Collection-Level Documentation

### README.md Template

```markdown
# Ansible Collection: namespace.collection_name

Description of what this collection provides and its purpose.

## Included Content

### Roles
- **role_name_1** - Description of role 1
- **role_name_2** - Description of role 2

### Modules
- **module_name** - Description of module

### Plugins
- **filter/custom_filter** - Description of filter

## Requirements

- Ansible 2.11 or higher
- Python 3.8 or higher
- Supported platforms: RHEL 8/9, Debian 11/12, Ubuntu 20.04/22.04

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy collection install namespace.collection_name
```

### From Git Repository

```bash
ansible-galaxy collection install git+https://github.com/company/collection.git
```

### From Local Source

```bash
cd path/to/namespace/collection_name
ansible-galaxy collection build
ansible-galaxy collection install namespace-collection_name-1.0.0.tar.gz
```

## Usage

### Using Roles

```yaml
---
- name: Example playbook
  hosts: servers
  become: true

  roles:
    - role: namespace.collection_name.role_name_1
      variable_name: value
```

### Using Modules

```yaml
---
- name: Example module usage
  hosts: localhost

  tasks:
    - name: Use custom module
      namespace.collection_name.module_name:
        parameter: value
```

## Development

### Building the Collection

```bash
ansible-galaxy collection build
```

### Testing

```bash
# Lint
ansible-lint

# Run role tests
cd roles/role_name
molecule test

# Integration tests
ansible-test integration
```

## Contributing

Contributions welcome! Please:
1. Follow Red Hat CoP standards
2. Add tests for new features
3. Update documentation
4. Run ansible-lint before submitting

## License

[License Name]

## Support

- Issues: [GitHub Issues](https://github.com/company/collection/issues)
- Documentation: [Docs Site](https://docs.company.com)
- Community: [Slack/Discord]
```

## Collection Roles

Roles in collections must follow the same Red Hat CoP standards:

**Key Requirements:**
- Variable names prefixed: `rolename_variable`
- Internal variables: `__rolename_internal`
- Idempotency required
- Multi-platform support
- Argument specs defined
- Molecule tests included
- Comprehensive README

**Reference:** Use the `role-developer` skill for creating collection roles.

## Collection Modules

Custom modules for collection-specific functionality.

### Module Structure

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2026, Your Name <your.email@company.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: module_name
short_description: Short description of what the module does
description:
  - Detailed description of the module
  - What it accomplishes
  - Use cases
version_added: "1.0.0"
author:
  - Your Name (@github_handle)
options:
  parameter_name:
    description:
      - Description of the parameter
    type: str
    required: true
  another_parameter:
    description:
      - Another parameter description
    type: bool
    required: false
    default: true
'''

EXAMPLES = r'''
- name: Example usage
  namespace.collection_name.module_name:
    parameter_name: value
    another_parameter: true
'''

RETURN = r'''
result:
  description: The result of the operation
  returned: always
  type: dict
  sample: {"status": "success"}
'''

from ansible.module_utils.basic import AnsibleModule

def run_module():
    module_args = dict(
        parameter_name=dict(type='str', required=True),
        another_parameter=dict(type='bool', required=False, default=True),
    )

    result = dict(
        changed=False,
        result=dict()
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    if module.check_mode:
        module.exit_json(**result)

    # Module logic here
    result['changed'] = True
    result['result'] = {'status': 'success'}

    module.exit_json(**result)

def main():
    run_module()

if __name__ == '__main__':
    main()
```

## Collection Plugins

### Filter Plugin Example

```python
# plugins/filter/custom_filters.py

from __future__ import absolute_import, division, print_function
__metaclass__ = type

class FilterModule(object):
    """Custom Jinja2 filters"""

    def filters(self):
        return {
            'custom_transform': self.custom_transform,
        }

    def custom_transform(self, value):
        """
        Transform value in custom way
        
        Args:
            value: Input value
            
        Returns:
            Transformed value
        """
        return value.upper()
```

## Testing Configuration

### .ansible-lint

```yaml
---
profile: production  # Strictest for collections

exclude_paths:
  - .git/
  - .github/
  - tests/output/
  - changelogs/

kinds:
  - playbook: "playbooks/*.yml"
  - tasks: "roles/*/tasks/*.yml"
  - vars: "roles/*/vars/*.yml"
  - meta: "roles/*/meta/main.yml"
```

### .yamllint

```yaml
---
extends: default

rules:
  line-length:
    max: 160
    level: warning
  indentation:
    spaces: 2
    indent-sequences: true
  comments:
    min-spaces-from-content: 1
```

## Building and Publishing

### Build Collection

```bash
# From collection root directory
ansible-galaxy collection build

# Creates: namespace-collection_name-1.0.0.tar.gz
```

### Publish to Ansible Galaxy

```bash
# Publish to Galaxy
ansible-galaxy collection publish namespace-collection_name-1.0.0.tar.gz --token <galaxy-token>
```

### Install Locally for Testing

```bash
# Install from tarball
ansible-galaxy collection install namespace-collection_name-1.0.0.tar.gz

# Or install in development mode
ansible-galaxy collection install -p ./collections /path/to/namespace/collection_name
```

## Changelog Management

Use `antsibull-changelog` for automated changelog generation:

```bash
# Initialize changelog
antsibull-changelog init .

# Add changelog fragment
cat > changelogs/fragments/feature-name.yml <<EOF
---
minor_changes:
  - Add new role for database management
bugfixes:
  - Fix idempotency issue in web_server role
EOF

# Generate changelog
antsibull-changelog release
```

## Collection Development Workflow

### 1. Initialize Collection

```bash
# Create collection skeleton
ansible-galaxy collection init namespace.collection_name

# Navigate to collection
cd namespace/collection_name
```

### 2. Add Roles

```bash
# Create role within collection
cd roles
ansible-galaxy role init role_name --init-path .

# Or use role-developer skill
# Add role following CoP standards
```

### 3. Add Modules/Plugins

```bash
# Create module
touch plugins/modules/module_name.py

# Create plugin
touch plugins/filter/custom_filters.py
```

### 4. Test

```bash
# Lint
ansible-lint

# Test roles
cd roles/role_name
molecule test

# Integration tests
ansible-test integration
```

### 5. Document

```bash
# Update README.md
# Add docs/ content
# Update galaxy.yml
```

### 6. Build

```bash
# Build collection
ansible-galaxy collection build

# Verify build
tar -tzf namespace-collection_name-1.0.0.tar.gz
```

### 7. Publish

```bash
# Publish to Galaxy
ansible-galaxy collection publish namespace-collection_name-1.0.0.tar.gz
```

## Best Practices

### Namespace Organization

**Recommended patterns:**

- **Company/Organization**: `company.infrastructure`, `company.security`
- **Team/Department**: `company.network_team`, `company.platform_ops`
- **Technology Stack**: `company.kubernetes`, `company.cloud_aws`

### Version Management

Follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Dependencies

Minimize external dependencies:
- Only depend on widely-used collections
- Document all dependencies in galaxy.yml
- Pin dependency versions for stability

### Documentation

**Must include:**
- Comprehensive README.md
- Role-level documentation
- Module DOCUMENTATION strings
- Example playbooks
- Getting started guide

## Common Pitfalls

### 1. Incorrect Naming

**Wrong:**
```
my-collection  # Dashes not allowed
MyCollection   # Capital letters not allowed
```

**Right:**
```
my_collection  # Underscores OK, lowercase
```

### 2. Missing galaxy.yml

Collection cannot build without galaxy.yml. Always include:
- namespace
- name
- version
- readme
- authors

### 3. Role Without Namespace

**Wrong:**
```yaml
roles:
  - role_name  # Missing namespace
```

**Right:**
```yaml
roles:
  - namespace.collection_name.role_name
```

### 4. Module Without FQCN

**Wrong:**
```yaml
- module_name:  # Ambiguous
```

**Right:**
```yaml
- namespace.collection_name.module_name:
```

## Output Format

When scaffolding a collection, create:

1. **Complete directory structure** with all standard directories
2. **galaxy.yml** with proper metadata
3. **README.md** with comprehensive documentation
4. **meta/runtime.yml** with Ansible version requirements
5. **Linting configuration** (.ansible-lint, .yamllint)
6. **Example role** following CoP standards
7. **LICENSE** file
8. **.gitignore** for collection development

Provide clear next steps for:
- Adding roles to the collection
- Creating custom modules
- Testing the collection
- Building and publishing

When asked to scaffold a collection, analyze requirements, create complete structure following Red Hat CoP standards, and provide comprehensive guidance for development and distribution.
