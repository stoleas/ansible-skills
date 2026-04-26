---
name: aap-config-as-code
description: >
  Configure Ansible Automation Platform as code using infra.aap_configuration collection
  for infrastructure-as-code management of AAP components. Use this skill when the user asks to:
  "configure AAP as code", "aap configuration management", "configure automation controller",
  "manage AAP with ansible", "aap infrastructure as code", "configure automation hub",
  "configure eda controller", or wants to automate AAP platform configuration using the
  Red Hat CoP collections. Always invoke this skill for AAP configuration-as-code workflows.
version: 1.0.0
allowed-tools: [Write, Read, Bash, Glob]
---

# AAP Configuration as Code Skill

Manage Ansible Automation Platform configuration as infrastructure-as-code using Red Hat Communities of Practice `infra.aap_configuration` collection and related tools.

## What is AAP Configuration as Code?

**AAP Configuration as Code** enables declarative management of Ansible Automation Platform components through version-controlled YAML definitions instead of manual GUI configuration.

**Key Benefits:**
- **Version control** - Track all configuration changes in Git
- **Repeatability** - Deploy identical configurations across environments
- **Disaster recovery** - Rebuild AAP from configuration files
- **Multi-environment** - Manage dev/qa/prod with shared configurations
- **Automation** - CI/CD integration for config deployment
- **Audit trail** - Complete history of configuration changes
- **Collaboration** - Team-based configuration management

**What can be managed:**
- Organizations, teams, users, roles
- Credentials and credential types
- Projects and inventories
- Job templates and workflows
- Execution environments
- Instance groups and service clusters
- Notification templates and schedules
- Applications (OAuth2)
- Event-driven automation configurations
- Private Automation Hub content

## Installation

### Install Collections

```bash
# Install main AAP configuration collection
ansible-galaxy collection install infra.aap_configuration

# Install extended functionality
ansible-galaxy collection install infra.aap_configuration_extended

# Install required dependencies
ansible-galaxy collection install ansible.controller
ansible-galaxy collection install ansible.hub
ansible-galaxy collection install ansible.platform
ansible-galaxy collection install ansible.eda
```

### Verify Installation

```bash
# List installed collections
ansible-galaxy collection list | grep -E '(infra|ansible\.(controller|hub|platform|eda))'
```

## Project Structure

### Recommended Directory Layout

```
aap-config/
├── ansible.cfg                  # Ansible configuration
├── requirements.yml             # Collection dependencies
├── inventory/
│   └── hosts.yml               # AAP controller inventory
├── config/
│   ├── all/                    # Shared across all environments
│   │   ├── organizations.yml
│   │   ├── teams.yml
│   │   ├── credential_types.yml
│   │   └── execution_environments.yml
│   ├── dev/                    # Development environment
│   │   ├── credentials.yml
│   │   ├── projects.yml
│   │   ├── inventories.yml
│   │   ├── job_templates.yml
│   │   └── secrets.yml        # Vault-encrypted
│   ├── qa/                     # QA environment
│   │   ├── credentials.yml
│   │   ├── projects.yml
│   │   ├── inventories.yml
│   │   ├── job_templates.yml
│   │   └── secrets.yml
│   └── prod/                   # Production environment
│       ├── credentials.yml
│       ├── projects.yml
│       ├── inventories.yml
│       ├── job_templates.yml
│       └── secrets.yml
├── playbooks/
│   ├── aap_config.yml          # Main configuration playbook
│   ├── export_config.yml       # Export existing config
│   └── validate_config.yml     # Validate before applying
└── README.md
```

### Initialize Project

```bash
# Create project structure
mkdir -p aap-config/{inventory,config/{all,dev,qa,prod},playbooks}

# Initialize git repository
cd aap-config
git init

# Create .gitignore
cat > .gitignore <<EOF
*.retry
.vault_pass
config/*/secrets.yml
EOF
```

## Configuration Files

### ansible.cfg

```ini
[defaults]
inventory = inventory/hosts.yml
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
collections_paths = ~/.ansible/collections

[privilege_escalation]
become = False
```

### requirements.yml

```yaml
---
collections:
  - name: infra.aap_configuration
    version: ">=3.0.0"
  
  - name: infra.aap_configuration_extended
    version: ">=2.0.0"
  
  - name: ansible.controller
    version: ">=4.6.0"
  
  - name: ansible.hub
    version: ">=1.0.0"
  
  - name: ansible.platform
    version: ">=1.0.0"
  
  - name: ansible.eda
    version: ">=1.0.0"
```

### inventory/hosts.yml

```yaml
---
all:
  hosts:
    automation_controller:
      ansible_host: controller.example.com
      ansible_connection: local  # Run on controller itself
  
  vars:
    # Controller connection
    controller_hostname: "{{ ansible_host }}"
    controller_username: admin
    controller_password: "{{ vault_controller_password }}"
    controller_validate_certs: true
    
    # Hub connection (if separate)
    ah_host: hub.example.com
    ah_username: admin
    ah_password: "{{ vault_ah_password }}"
    ah_validate_certs: true
    
    # EDA Controller connection
    eda_controller_hostname: eda.example.com
    eda_controller_username: admin
    eda_controller_password: "{{ vault_eda_password }}"
    eda_controller_validate_certs: true
```

## AAP Component Configuration

### Organizations

```yaml
# config/all/organizations.yml
---
controller_organizations:
  - name: Engineering
    description: Engineering teams
    galaxy_credentials:
      - Ansible Galaxy
  
  - name: Operations
    description: Operations teams
    max_hosts: 100
    
  - name: Security
    description: Security teams
    default_environment: Security EE
```

### Teams

```yaml
# config/all/teams.yml
---
controller_teams:
  - name: Platform Team
    organization: Engineering
    description: Platform engineering team
  
  - name: DevOps Team
    organization: Engineering
    description: DevOps automation team
  
  - name: Network Team
    organization: Operations
    description: Network operations team
```

### Users

```yaml
# config/all/users.yml
---
controller_user_accounts:
  - username: john.doe
    password: "{{ vault_john_password }}"
    email: john.doe@example.com
    first_name: John
    last_name: Doe
    organization: Engineering
    is_superuser: false
    is_system_auditor: false
  
  - username: jane.admin
    password: "{{ vault_jane_password }}"
    email: jane.admin@example.com
    first_name: Jane
    last_name: Admin
    organization: Operations
    is_superuser: true
```

### Role Assignments

```yaml
# config/all/roles.yml
---
controller_roles:
  # Organization roles
  - user: john.doe
    organization: Engineering
    role: member
  
  - team: Platform Team
    organization: Engineering
    role: admin
  
  # Project roles
  - user: jane.admin
    project: Infrastructure Automation
    role: admin
  
  # Inventory roles
  - team: DevOps Team
    inventory: Production Servers
    role: use
```

### Credential Types

```yaml
# config/all/credential_types.yml
---
controller_credential_types:
  - name: HashiCorp Vault
    description: Credential type for Vault integration
    kind: cloud
    inputs:
      fields:
        - id: vault_url
          type: string
          label: Vault URL
        - id: vault_token
          type: string
          label: Vault Token
          secret: true
      required:
        - vault_url
        - vault_token
    injectors:
      env:
        VAULT_ADDR: "{{ vault_url }}"
        VAULT_TOKEN: "{{ vault_token }}"
  
  - name: ServiceNow API
    description: ServiceNow API credentials
    kind: cloud
    inputs:
      fields:
        - id: snow_instance
          type: string
          label: Instance URL
        - id: snow_username
          type: string
          label: Username
        - id: snow_password
          type: string
          label: Password
          secret: true
    injectors:
      extra_vars:
        snow_instance: "{{ snow_instance }}"
        snow_username: "{{ snow_username }}"
        snow_password: "{{ snow_password }}"
```

### Credentials

```yaml
# config/dev/credentials.yml
---
controller_credentials:
  - name: Dev SSH Key
    organization: Engineering
    credential_type: Machine
    inputs:
      ssh_key_data: "{{ vault_dev_ssh_key }}"
      username: ansible
  
  - name: Dev AWS
    organization: Engineering
    credential_type: Amazon Web Services
    inputs:
      username: "{{ vault_aws_access_key }}"
      password: "{{ vault_aws_secret_key }}"
  
  - name: Dev GitHub
    organization: Engineering
    credential_type: Source Control
    inputs:
      username: git
      ssh_key_data: "{{ vault_github_ssh_key }}"
  
  - name: Dev Vault
    organization: Engineering
    credential_type: HashiCorp Vault
    inputs:
      vault_url: https://vault-dev.example.com
      vault_token: "{{ vault_hashicorp_token }}"
```

### Execution Environments

```yaml
# config/all/execution_environments.yml
---
controller_execution_environments:
  - name: Default EE
    image: quay.io/ansible/awx-ee:latest
    pull: missing
  
  - name: Custom App EE
    image: quay.io/myorg/custom-ee:1.0.0
    description: Custom EE with app-specific collections
    pull: missing
    credential: Container Registry Credential
  
  - name: Network EE
    image: quay.io/ansible/network-ee:latest
    description: Network automation execution environment
    pull: missing
```

### Projects

```yaml
# config/dev/projects.yml
---
controller_projects:
  - name: Infrastructure Automation
    organization: Engineering
    scm_type: git
    scm_url: https://github.com/myorg/infra-automation.git
    scm_branch: develop
    scm_credential: Dev GitHub
    scm_update_on_launch: true
    scm_delete_on_update: true
    default_environment: Custom App EE
  
  - name: Network Automation
    organization: Operations
    scm_type: git
    scm_url: https://github.com/myorg/network-automation.git
    scm_branch: develop
    scm_credential: Dev GitHub
    default_environment: Network EE
    allow_override: true
```

### Inventories

```yaml
# config/dev/inventories.yml
---
controller_inventories:
  - name: Dev Servers
    organization: Engineering
    description: Development environment servers
  
  - name: AWS Dev
    organization: Engineering
    description: AWS development resources
    variables:
      ansible_connection: ssh
      ansible_user: ec2-user

# Inventory Sources
controller_inventory_sources:
  - name: AWS EC2 Dev
    inventory: AWS Dev
    source: ec2
    credential: Dev AWS
    update_on_launch: true
    overwrite: true
    source_vars:
      regions:
        - us-east-1
      filters:
        tag:Environment: dev
```

### Job Templates

```yaml
# config/dev/job_templates.yml
---
controller_templates:
  - name: Deploy Web App - Dev
    organization: Engineering
    inventory: Dev Servers
    project: Infrastructure Automation
    playbook: playbooks/deploy_webapp.yml
    credentials:
      - Dev SSH Key
      - Dev AWS
    execution_environment: Custom App EE
    ask_variables_on_launch: true
    extra_vars:
      environment: dev
    survey_enabled: true
    survey_spec:
      name: Deployment Survey
      description: Deployment options
      spec:
        - question_name: Application Version
          question_description: Version to deploy
          required: true
          type: text
          variable: app_version
          default: latest
        
        - question_name: Deploy Database
          question_description: Deploy database changes?
          required: false
          type: multiplechoice
          variable: deploy_database
          choices:
            - "yes"
            - "no"
          default: "no"
```

### Workflows

```yaml
# config/dev/workflows.yml
---
controller_workflows:
  - name: Full Stack Deployment - Dev
    organization: Engineering
    description: Complete application stack deployment
    inventory: Dev Servers
    extra_vars:
      environment: dev
    survey_enabled: true
    survey_spec:
      name: Deployment Survey
      spec:
        - question_name: Version
          required: true
          type: text
          variable: app_version
    
    workflow_nodes:
      - identifier: deploy_database
        unified_job_template: Deploy Database - Dev
        success_nodes:
          - deploy_application
      
      - identifier: deploy_application
        unified_job_template: Deploy Web App - Dev
        success_nodes:
          - run_smoke_tests
        credentials:
          - Dev SSH Key
      
      - identifier: run_smoke_tests
        unified_job_template: Smoke Tests - Dev
        success_nodes:
          - notify_success
        failure_nodes:
          - rollback_deployment
      
      - identifier: rollback_deployment
        unified_job_template: Rollback - Dev
        always_nodes:
          - notify_failure
      
      - identifier: notify_success
        unified_job_template: Send Notification
      
      - identifier: notify_failure
        unified_job_template: Send Notification
```

### Schedules

```yaml
# config/dev/schedules.yml
---
controller_schedules:
  - name: Nightly Backup - Dev
    unified_job_template: Backup Databases - Dev
    rrule: "DTSTART:20260101T020000Z RRULE:FREQ=DAILY;INTERVAL=1"
    description: Run nightly at 2 AM UTC
    enabled: true
  
  - name: Weekly Patching - Dev
    unified_job_template: Patch Servers - Dev
    rrule: "DTSTART:20260104T040000Z RRULE:FREQ=WEEKLY;BYDAY=SU"
    description: Run every Sunday at 4 AM UTC
    enabled: true
```

### Notification Templates

```yaml
# config/all/notifications.yml
---
controller_notifications:
  - name: Slack - Engineering
    organization: Engineering
    notification_type: slack
    notification_configuration:
      token: "{{ vault_slack_token }}"
      channels:
        - "#engineering-alerts"
  
  - name: Email - Operations
    organization: Operations
    notification_type: email
    notification_configuration:
      host: smtp.example.com
      port: 587
      username: "{{ vault_smtp_username }}"
      password: "{{ vault_smtp_password }}"
      sender: automation@example.com
      recipients:
        - ops-team@example.com
      use_tls: true
  
  - name: PagerDuty - Production
    organization: Operations
    notification_type: pagerduty
    notification_configuration:
      token: "{{ vault_pagerduty_token }}"
      subdomain: mycompany
      service_key: "{{ vault_pagerduty_service_key }}"
```

## Main Configuration Playbook

### playbooks/aap_config.yml

```yaml
---
- name: Configure Ansible Automation Platform
  hosts: automation_controller
  connection: local
  gather_facts: false
  
  vars:
    # Environment to configure (dev, qa, prod)
    target_environment: "{{ lookup('env', 'AAP_ENV') | default('dev') }}"
  
  pre_tasks:
    - name: Load environment-specific secrets
      ansible.builtin.include_vars:
        file: "config/{{ target_environment }}/secrets.yml"
      tags: always
  
  roles:
    # Organizations and access control
    - role: infra.aap_configuration.organizations
      vars:
        controller_configuration_organizations_secure_logging: true
      tags: [organizations, access]
    
    - role: infra.aap_configuration.teams
      tags: [teams, access]
    
    - role: infra.aap_configuration.users
      vars:
        controller_configuration_users_secure_logging: true
      tags: [users, access]
    
    - role: infra.aap_configuration.roles
      tags: [roles, access]
    
    # Credentials
    - role: infra.aap_configuration.credential_types
      tags: [credentials, credential_types]
    
    - role: infra.aap_configuration.credentials
      vars:
        controller_configuration_credentials_secure_logging: true
      tags: [credentials]
    
    # Execution environments
    - role: infra.aap_configuration.execution_environments
      tags: [execution_environments, ee]
    
    # Projects and inventories
    - role: infra.aap_configuration.projects
      tags: [projects]
    
    - role: infra.aap_configuration.inventories
      tags: [inventories]
    
    - role: infra.aap_configuration.inventory_sources
      tags: [inventories, inventory_sources]
    
    # Job templates and workflows
    - role: infra.aap_configuration.job_templates
      tags: [job_templates, templates]
    
    - role: infra.aap_configuration.workflow_job_templates
      tags: [workflows, templates]
    
    # Notifications and schedules
    - role: infra.aap_configuration.notification_templates
      tags: [notifications]
    
    - role: infra.aap_configuration.schedules
      tags: [schedules]
  
  post_tasks:
    - name: Display configuration summary
      ansible.builtin.debug:
        msg: |
          AAP Configuration Complete for {{ target_environment }}
          
          Organizations: {{ controller_organizations | default([]) | length }}
          Teams: {{ controller_teams | default([]) | length }}
          Users: {{ controller_user_accounts | default([]) | length }}
          Projects: {{ controller_projects | default([]) | length }}
          Job Templates: {{ controller_templates | default([]) | length }}
          Workflows: {{ controller_workflows | default([]) | length }}
```

## Running Configuration

### Apply Configuration

```bash
# Configure development environment
AAP_ENV=dev ansible-playbook playbooks/aap_config.yml

# Configure production environment
AAP_ENV=prod ansible-playbook playbooks/aap_config.yml

# Configure specific components with tags
ansible-playbook playbooks/aap_config.yml --tags projects,templates

# Dry run (check mode)
ansible-playbook playbooks/aap_config.yml --check --diff
```

### With Vault-Encrypted Secrets

```bash
# Create vault password file
echo "my-vault-password" > .vault_pass
chmod 600 .vault_pass

# Add to ansible.cfg
echo "vault_password_file = .vault_pass" >> ansible.cfg

# Run with vault
ansible-playbook playbooks/aap_config.yml
```

## Exporting Existing Configuration

### Export Current AAP Config

```yaml
# playbooks/export_config.yml
---
- name: Export AAP Configuration
  hosts: automation_controller
  connection: local
  gather_facts: false
  
  tasks:
    - name: Export controller configuration
      ansible.controller.export:
        all: true
      register: export_result
    
    - name: Save exported configuration
      ansible.builtin.copy:
        content: "{{ export_result.assets | to_nice_yaml }}"
        dest: "exports/aap_export_{{ ansible_date_time.date }}.yml"
    
    - name: Display export location
      ansible.builtin.debug:
        msg: "Configuration exported to exports/aap_export_{{ ansible_date_time.date }}.yml"
```

### Convert Export to Config-as-Code Format

```bash
# Run export
ansible-playbook playbooks/export_config.yml

# Review exported file
cat exports/aap_export_*.yml

# Manually organize into config/ structure
# Or use infra.aap_configuration_extended.filetree_create role
```

## Multi-Environment Management

### Environment-Specific Variables

```yaml
# config/dev/main.yml
---
# Load all dev configuration files
controller_organizations: "{{ lookup('file', 'config/all/organizations.yml') | from_yaml }}"
controller_teams: "{{ lookup('file', 'config/all/teams.yml') | from_yaml }}"
controller_credentials: "{{ lookup('file', 'config/dev/credentials.yml') | from_yaml }}"
controller_projects: "{{ lookup('file', 'config/dev/projects.yml') | from_yaml }}"
controller_inventories: "{{ lookup('file', 'config/dev/inventories.yml') | from_yaml }}"
controller_templates: "{{ lookup('file', 'config/dev/job_templates.yml') | from_yaml }}"
```

### Shared vs Environment-Specific

**Shared (config/all/):**
- Organizations
- Teams  
- Credential types
- Execution environments (base images)

**Environment-Specific (config/dev, config/qa, config/prod/):**
- Credentials (different per environment)
- Projects (different branches)
- Inventories (different hosts)
- Job templates (different variables)
- Schedules (different frequencies)

## Secrets Management

### Encrypting Secrets

```bash
# Create secrets file
cat > config/dev/secrets.yml <<EOF
---
vault_controller_password: admin123
vault_aws_access_key: AKIA...
vault_aws_secret_key: secret...
vault_github_ssh_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
EOF

# Encrypt with ansible-vault
ansible-vault encrypt config/dev/secrets.yml

# Edit encrypted file
ansible-vault edit config/dev/secrets.yml

# Decrypt (temporary)
ansible-vault decrypt config/dev/secrets.yml
```

### Using Vault Variables

```yaml
# Reference vault variables with vault_ prefix
controller_credentials:
  - name: AWS Dev
    credential_type: Amazon Web Services
    inputs:
      username: "{{ vault_aws_access_key }}"
      password: "{{ vault_aws_secret_key }}"
```

## CI/CD Integration

### GitLab CI Example

```yaml
# .gitlab-ci.yml
---
stages:
  - validate
  - deploy

variables:
  ANSIBLE_FORCE_COLOR: "true"

validate_dev:
  stage: validate
  script:
    - ansible-galaxy collection install -r requirements.yml
    - ansible-playbook playbooks/aap_config.yml --syntax-check
    - ansible-lint playbooks/aap_config.yml
  only:
    - merge_requests

deploy_dev:
  stage: deploy
  script:
    - ansible-galaxy collection install -r requirements.yml
    - AAP_ENV=dev ansible-playbook playbooks/aap_config.yml
  only:
    - develop

deploy_prod:
  stage: deploy
  script:
    - ansible-galaxy collection install -r requirements.yml
    - AAP_ENV=prod ansible-playbook playbooks/aap_config.yml
  only:
    - main
  when: manual
```

### GitHub Actions Example

```yaml
# .github/workflows/aap-config.yml
name: Deploy AAP Configuration

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Ansible
        run: pip install ansible
      
      - name: Install collections
        run: ansible-galaxy collection install -r requirements.yml
      
      - name: Syntax check
        run: ansible-playbook playbooks/aap_config.yml --syntax-check
      
      - name: Lint
        run: ansible-lint playbooks/aap_config.yml
  
  deploy_dev:
    needs: validate
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Dev
        env:
          AAP_ENV: dev
          VAULT_PASSWORD: ${{ secrets.VAULT_PASSWORD }}
        run: |
          echo "$VAULT_PASSWORD" > .vault_pass
          ansible-galaxy collection install -r requirements.yml
          ansible-playbook playbooks/aap_config.yml
```

## Best Practices

### 1. Version Control Everything

```bash
# Initialize git repository
git init
git add .
git commit -m "Initial AAP configuration"

# Create branches for environments
git branch develop
git branch qa
git branch production
```

### 2. Use Tags for Selective Configuration

```bash
# Update only credentials
ansible-playbook playbooks/aap_config.yml --tags credentials

# Update projects and templates
ansible-playbook playbooks/aap_config.yml --tags projects,templates

# Skip notifications
ansible-playbook playbooks/aap_config.yml --skip-tags notifications
```

### 3. Validate Before Applying

```yaml
# playbooks/validate_config.yml
---
- name: Validate AAP Configuration
  hosts: automation_controller
  connection: local
  gather_facts: false
  
  tasks:
    - name: Validate YAML syntax
      ansible.builtin.include_vars:
        file: "{{ item }}"
      loop:
        - config/all/organizations.yml
        - config/dev/credentials.yml
        - config/dev/projects.yml
      
    - name: Check required variables
      ansible.builtin.assert:
        that:
          - controller_hostname is defined
          - controller_username is defined
          - controller_password is defined
        fail_msg: "Missing required controller connection variables"
```

### 4. Use Secure Logging

```yaml
# Prevent passwords from appearing in logs
roles:
  - role: infra.aap_configuration.credentials
    vars:
      controller_configuration_credentials_secure_logging: true
```

### 5. Implement Change Control

```yaml
# Only allow production changes from main branch
- name: Verify production deployment
  assert:
    that:
      - lookup('env', 'CI_COMMIT_BRANCH') == 'main'
    fail_msg: "Production deployments only from main branch"
  when: target_environment == 'prod'
```

## Troubleshooting

### Issue: Authentication Failed

```bash
# Test controller connection
curl -k -u admin:password https://controller.example.com/api/v2/ping/

# Verify credentials in inventory
ansible-inventory --host automation_controller

# Test with ansible ad-hoc
ansible automation_controller -m ansible.controller.controller_api -a "endpoint=ping"
```

### Issue: Object Already Exists

**Symptom:** "Object already exists with different parameters"

**Solution:**
- Collections update existing objects by name
- Ensure name matching is exact
- Use `state: absent` to remove before recreating

```yaml
# Remove then recreate
controller_projects:
  - name: Old Project
    state: absent
  
  - name: New Project
    scm_url: https://github.com/newrepo.git
```

### Issue: Circular Dependencies

**Symptom:** "Cannot create X because Y doesn't exist yet"

**Solution:** Use proper role ordering in playbook

```yaml
# Correct order
roles:
  - organizations      # First
  - teams             # After orgs
  - credentials       # Before projects
  - projects          # Before templates
  - inventories       # Before templates
  - job_templates     # Last
```

## Quick Reference

### Common Commands

```bash
# Install collections
ansible-galaxy collection install -r requirements.yml

# Configure environment
AAP_ENV=dev ansible-playbook playbooks/aap_config.yml

# Export configuration
ansible-playbook playbooks/export_config.yml

# Validate configuration
ansible-playbook playbooks/validate_config.yml

# Update specific components
ansible-playbook playbooks/aap_config.yml --tags projects

# Check mode (dry run)
ansible-playbook playbooks/aap_config.yml --check --diff
```

### Available Roles

```
infra.aap_configuration.organizations
infra.aap_configuration.teams
infra.aap_configuration.users
infra.aap_configuration.roles
infra.aap_configuration.credential_types
infra.aap_configuration.credentials
infra.aap_configuration.execution_environments
infra.aap_configuration.projects
infra.aap_configuration.inventories
infra.aap_configuration.inventory_sources
infra.aap_configuration.hosts
infra.aap_configuration.groups
infra.aap_configuration.job_templates
infra.aap_configuration.workflow_job_templates
infra.aap_configuration.notification_templates
infra.aap_configuration.schedules
infra.aap_configuration.labels
infra.aap_configuration.instance_groups
infra.aap_configuration.applications
```

## Output Template

When helping users configure AAP as code, provide:

1. **Project structure** with recommended directory layout
2. **Configuration files** for the specific AAP components they need
3. **Main playbook** using appropriate infra.aap_configuration roles
4. **Secrets management** guidance with vault examples
5. **Execution instructions** for applying configuration
6. **CI/CD integration** examples if applicable

Explain:
- Why specific configuration structure is recommended
- How to organize multi-environment configuration
- Security best practices for credentials
- How to export existing configuration
- Validation and testing approach before production

When asked to configure AAP as code, analyze requirements, design configuration structure, generate YAML definitions for AAP objects, create playbooks using infra.aap_configuration roles, and provide comprehensive deployment and management guidance.
