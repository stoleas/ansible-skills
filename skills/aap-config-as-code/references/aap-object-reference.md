# AAP Configuration Object Reference

Complete reference for all AAP objects manageable via infra.aap_configuration collection.

## Organizations

**Role:** `infra.aap_configuration.organizations`

**Variable:** `controller_organizations`

**Required Fields:**
- `name` - Organization name (unique)

**Optional Fields:**
- `description` - Organization description
- `max_hosts` - Maximum number of hosts (0 = unlimited)
- `galaxy_credentials` - List of Galaxy credentials
- `default_environment` - Default execution environment

**Example:**
```yaml
controller_organizations:
  - name: Engineering
    description: Engineering teams
    max_hosts: 500
    galaxy_credentials:
      - Ansible Galaxy
    default_environment: Default EE
```

---

## Teams

**Role:** `infra.aap_configuration.teams`

**Variable:** `controller_teams`

**Required Fields:**
- `name` - Team name
- `organization` - Parent organization

**Optional Fields:**
- `description` - Team description

**Example:**
```yaml
controller_teams:
  - name: Platform Team
    organization: Engineering
    description: Platform engineering team
```

---

## Users

**Role:** `infra.aap_configuration.users`

**Variable:** `controller_user_accounts`

**Required Fields:**
- `username` - Username (unique)
- `password` - User password (use vault!)

**Optional Fields:**
- `email` - Email address
- `first_name` - First name
- `last_name` - Last name
- `organization` - Default organization
- `is_superuser` - Superuser flag (boolean)
- `is_system_auditor` - Auditor flag (boolean)

**Example:**
```yaml
controller_user_accounts:
  - username: john.doe
    password: "{{ vault_john_password }}"
    email: john.doe@example.com
    first_name: John
    last_name: Doe
    organization: Engineering
    is_superuser: false
```

---

## Roles (RBAC)

**Role:** `infra.aap_configuration.roles`

**Variable:** `controller_roles`

**Required Fields:**
- `role` - Role type (see role types below)
- One of: `user`, `team`
- One of: `organization`, `project`, `inventory`, `job_template`, etc.

**Role Types:**
- `admin` - Full administrative access
- `execute` - Can execute job templates
- `read` - Read-only access
- `update` - Can modify object
- `use` - Can use resource (credentials, inventories)
- `member` - Organization/team member
- `auditor` - System auditor

**Examples:**
```yaml
controller_roles:
  # Organization roles
  - user: john.doe
    organization: Engineering
    role: admin

  - team: Platform Team
    organization: Engineering
    role: member

  # Project roles
  - user: jane.doe
    project: Infrastructure Automation
    role: update

  # Inventory roles
  - team: DevOps Team
    inventory: Production Servers
    role: use

  # Job template roles
  - user: operator
    job_template: Deploy Application
    role: execute
```

---

## Credential Types

**Role:** `infra.aap_configuration.credential_types`

**Variable:** `controller_credential_types`

**Required Fields:**
- `name` - Credential type name
- `kind` - Type kind (`cloud`, `net`, `scm`)
- `inputs` - Input field definitions
- `injectors` - How to inject into environment

**Example:**
```yaml
controller_credential_types:
  - name: HashiCorp Vault
    description: Vault API credentials
    kind: cloud
    inputs:
      fields:
        - id: vault_url
          type: string
          label: Vault URL
          help_text: URL to Vault server
        - id: vault_token
          type: string
          label: Vault Token
          secret: true
          help_text: Vault authentication token
      required:
        - vault_url
        - vault_token
    injectors:
      env:
        VAULT_ADDR: "{{ vault_url }}"
        VAULT_TOKEN: "{{ vault_token }}"
      extra_vars:
        vault_url: "{{ vault_url }}"
```

---

## Credentials

**Role:** `infra.aap_configuration.credentials`

**Variable:** `controller_credentials`

**Required Fields:**
- `name` - Credential name
- `organization` - Organization name
- `credential_type` - Type of credential

**Optional Fields:**
- `description` - Credential description
- `inputs` - Credential inputs (type-specific)

**Common Credential Types:**
- `Machine` - SSH credentials
- `Source Control` - Git/SVN credentials
- `Amazon Web Services` - AWS credentials
- `Google Compute Engine` - GCP credentials
- `Microsoft Azure Resource Manager` - Azure credentials
- `Network` - Network device credentials
- `Vault` - Ansible Vault password

**Examples:**
```yaml
controller_credentials:
  # SSH Key
  - name: Production SSH Key
    organization: Engineering
    credential_type: Machine
    inputs:
      username: ansible
      ssh_key_data: "{{ vault_ssh_private_key }}"

  # AWS
  - name: AWS Production
    organization: Engineering
    credential_type: Amazon Web Services
    inputs:
      username: "{{ vault_aws_access_key }}"
      password: "{{ vault_aws_secret_key }}"

  # Git
  - name: GitHub
    organization: Engineering
    credential_type: Source Control
    inputs:
      username: git
      ssh_key_data: "{{ vault_github_ssh_key }}"

  # Vault Password
  - name: Ansible Vault
    organization: Engineering
    credential_type: Vault
    inputs:
      vault_password: "{{ vault_ansible_vault_password }}"

  # Custom Type
  - name: HashiCorp Vault Access
    organization: Engineering
    credential_type: HashiCorp Vault
    inputs:
      vault_url: https://vault.example.com
      vault_token: "{{ vault_hashicorp_token }}"
```

---

## Execution Environments

**Role:** `infra.aap_configuration.execution_environments`

**Variable:** `controller_execution_environments`

**Required Fields:**
- `name` - EE name
- `image` - Container image path

**Optional Fields:**
- `description` - EE description
- `organization` - Organization (optional)
- `credential` - Container registry credential
- `pull` - Pull policy (`always`, `missing`, `never`)

**Example:**
```yaml
controller_execution_environments:
  - name: Default EE
    image: quay.io/ansible/awx-ee:latest
    description: Default execution environment
    pull: missing

  - name: Custom App EE
    image: quay.io/myorg/custom-ee:1.0.0
    description: Custom EE with app collections
    credential: Container Registry
    pull: missing
    organization: Engineering
```

---

## Projects

**Role:** `infra.aap_configuration.projects`

**Variable:** `controller_projects`

**Required Fields:**
- `name` - Project name
- `organization` - Organization name
- `scm_type` - SCM type (`git`, `svn`, `archive`, `manual`)

**SCM-Specific Fields:**
- `scm_url` - Repository URL
- `scm_branch` - Branch/tag/commit
- `scm_credential` - SCM credential
- `scm_update_on_launch` - Update on launch (boolean)
- `scm_delete_on_update` - Clean repository (boolean)

**Optional Fields:**
- `description` - Project description
- `default_environment` - Default EE
- `allow_override` - Allow EE override (boolean)

**Example:**
```yaml
controller_projects:
  - name: Infrastructure Automation
    organization: Engineering
    description: Infrastructure automation playbooks
    scm_type: git
    scm_url: https://github.com/myorg/infra-automation.git
    scm_branch: main
    scm_credential: GitHub
    scm_update_on_launch: true
    scm_delete_on_update: true
    default_environment: Custom EE
    allow_override: true
```

---

## Inventories

**Role:** `infra.aap_configuration.inventories`

**Variable:** `controller_inventories`

**Required Fields:**
- `name` - Inventory name
- `organization` - Organization name

**Optional Fields:**
- `description` - Inventory description
- `variables` - Inventory variables (YAML/JSON)
- `kind` - Inventory kind (``, `smart`)
- `host_filter` - Smart inventory filter
- `instance_groups` - Instance groups

**Example:**
```yaml
controller_inventories:
  - name: Production Servers
    organization: Engineering
    description: Production server inventory
    variables:
      ansible_connection: ssh
      ansible_user: ansible
    instance_groups:
      - Production Instance Group

  # Smart inventory
  - name: Web Servers
    organization: Engineering
    kind: smart
    host_filter: "name__icontains=web"
```

---

## Inventory Sources

**Role:** `infra.aap_configuration.inventory_sources`

**Variable:** `controller_inventory_sources`

**Required Fields:**
- `name` - Source name
- `inventory` - Parent inventory
- `source` - Source type

**Source Types:**
- `scm` - Source control
- `ec2` - AWS EC2
- `gce` - Google Compute Engine
- `azure_rm` - Azure Resource Manager
- `vmware` - VMware vCenter
- `openstack` - OpenStack
- `satellite6` - Red Hat Satellite
- `controller` - Ansible Controller

**Example:**
```yaml
controller_inventory_sources:
  - name: AWS EC2 Production
    inventory: Production Servers
    source: ec2
    credential: AWS Production
    update_on_launch: true
    overwrite: true
    source_vars:
      regions:
        - us-east-1
        - us-west-2
      filters:
        tag:Environment: production
```

---

## Job Templates

**Role:** `infra.aap_configuration.job_templates`

**Variable:** `controller_templates`

**Required Fields:**
- `name` - Template name
- `organization` - Organization name
- `inventory` - Inventory name
- `project` - Project name
- `playbook` - Playbook path

**Optional Fields:**
- `description` - Template description
- `job_type` - `run` or `check`
- `credentials` - List of credentials
- `execution_environment` - EE name
- `forks` - Number of forks
- `limit` - Inventory limit pattern
- `verbosity` - Verbosity level (0-5)
- `extra_vars` - Extra variables (YAML/JSON)
- `job_tags` - Ansible tags
- `skip_tags` - Tags to skip
- `ask_*_on_launch` - Prompt for value (boolean)
- `survey_enabled` - Enable survey (boolean)
- `survey_spec` - Survey specification
- `concurrent_jobs_enabled` - Allow concurrent runs (boolean)
- `timeout` - Job timeout (seconds)

**Example:**
```yaml
controller_templates:
  - name: Deploy Web Application
    organization: Engineering
    description: Deploy web application to servers
    inventory: Production Servers
    project: Infrastructure Automation
    playbook: playbooks/deploy_webapp.yml
    job_type: run
    credentials:
      - Production SSH Key
      - AWS Production
    execution_environment: Custom App EE
    forks: 10
    verbosity: 0
    extra_vars:
      app_name: myapp
    ask_variables_on_launch: true
    ask_limit_on_launch: true
    survey_enabled: true
    survey_spec:
      name: Deployment Options
      description: Configure deployment
      spec:
        - question_name: Version
          required: true
          type: text
          variable: app_version
          default: latest
    concurrent_jobs_enabled: false
    timeout: 3600
```

---

## Workflow Job Templates

**Role:** `infra.aap_configuration.workflow_job_templates`

**Variable:** `controller_workflows`

**Required Fields:**
- `name` - Workflow name
- `organization` - Organization name

**Optional Fields:**
- `description` - Workflow description
- `inventory` - Default inventory
- `extra_vars` - Extra variables
- `survey_enabled` - Enable survey
- `survey_spec` - Survey specification
- `workflow_nodes` - Workflow node definitions

**Workflow Node Fields:**
- `identifier` - Unique node ID
- `unified_job_template` - Job/workflow template name
- `success_nodes` - Nodes to run on success
- `failure_nodes` - Nodes to run on failure
- `always_nodes` - Nodes to always run
- `credentials` - Node-specific credentials
- `extra_data` - Node-specific variables

**Example:**
```yaml
controller_workflows:
  - name: Application Deployment Pipeline
    organization: Engineering
    description: Complete deployment workflow
    inventory: Production Servers
    workflow_nodes:
      - identifier: backup
        unified_job_template: Backup Database
        success_nodes:
          - deploy
      
      - identifier: deploy
        unified_job_template: Deploy Application
        success_nodes:
          - test
        failure_nodes:
          - rollback
      
      - identifier: test
        unified_job_template: Run Tests
        success_nodes:
          - notify_success
        failure_nodes:
          - rollback
      
      - identifier: rollback
        unified_job_template: Rollback Deployment
        always_nodes:
          - notify_failure
```

---

## Schedules

**Role:** `infra.aap_configuration.schedules`

**Variable:** `controller_schedules`

**Required Fields:**
- `name` - Schedule name
- `unified_job_template` - Job/workflow template
- `rrule` - Recurrence rule (RFC 5545)

**Optional Fields:**
- `description` - Schedule description
- `enabled` - Enable schedule (boolean)
- `extra_data` - Schedule variables

**RRULE Examples:**
- Daily: `DTSTART:20260101T000000Z RRULE:FREQ=DAILY;INTERVAL=1`
- Weekly: `DTSTART:20260101T000000Z RRULE:FREQ=WEEKLY;BYDAY=MO`
- Monthly: `DTSTART:20260101T000000Z RRULE:FREQ=MONTHLY;BYMONTHDAY=1`

**Example:**
```yaml
controller_schedules:
  - name: Nightly Backup
    unified_job_template: Backup Servers
    rrule: "DTSTART:20260101T020000Z RRULE:FREQ=DAILY;INTERVAL=1"
    description: Run every night at 2 AM UTC
    enabled: true
    extra_data:
      backup_type: full
```

---

## Notification Templates

**Role:** `infra.aap_configuration.notification_templates`

**Variable:** `controller_notifications`

**Required Fields:**
- `name` - Notification name
- `organization` - Organization name
- `notification_type` - Type of notification
- `notification_configuration` - Type-specific config

**Notification Types:**
- `email` - Email
- `slack` - Slack
- `pagerduty` - PagerDuty
- `webhook` - Generic webhook
- `irc` - IRC
- `grafana` - Grafana

**Example:**
```yaml
controller_notifications:
  - name: Slack Engineering
    organization: Engineering
    notification_type: slack
    notification_configuration:
      token: "{{ vault_slack_token }}"
      channels:
        - "#engineering"
        - "#alerts"

  - name: Email Ops Team
    organization: Operations
    notification_type: email
    notification_configuration:
      host: smtp.example.com
      port: 587
      username: "{{ vault_smtp_user }}"
      password: "{{ vault_smtp_password }}"
      sender: automation@example.com
      recipients:
        - ops@example.com
      use_tls: true
```

---

## Instance Groups

**Role:** `infra.aap_configuration.instance_groups`

**Variable:** `controller_instance_groups`

**Required Fields:**
- `name` - Instance group name

**Optional Fields:**
- `credential` - Container group credential
- `is_container_group` - Container group flag
- `max_forks` - Maximum forks
- `max_concurrent_jobs` - Maximum concurrent jobs
- `pod_spec_override` - Kubernetes pod spec

**Example:**
```yaml
controller_instance_groups:
  - name: Production Instances
    max_forks: 100
    max_concurrent_jobs: 50

  - name: Kubernetes Container Group
    is_container_group: true
    credential: Kubernetes Credential
    pod_spec_override: |
      apiVersion: v1
      kind: Pod
      metadata:
        namespace: ansible-automation
      spec:
        containers:
          - image: quay.io/ansible/awx-ee:latest
            name: worker
```

---

## Applications (OAuth2)

**Role:** `infra.aap_configuration.applications`

**Variable:** `controller_applications`

**Required Fields:**
- `name` - Application name
- `organization` - Organization name
- `authorization_grant_type` - Grant type
- `client_type` - Client type

**Grant Types:**
- `authorization-code` - Authorization code
- `password` - Resource owner password-based

**Client Types:**
- `confidential` - Confidential client
- `public` - Public client

**Example:**
```yaml
controller_applications:
  - name: CI/CD Integration
    organization: Engineering
    description: OAuth2 app for CI/CD pipeline
    authorization_grant_type: password
    client_type: confidential
    redirect_uris: https://ci.example.com/callback
```

---

## Configuration Order

To avoid dependency issues, configure objects in this order:

1. Organizations
2. Teams
3. Users
4. Roles (RBAC)
5. Credential Types
6. Credentials
7. Execution Environments
8. Instance Groups
9. Projects
10. Inventories
11. Inventory Sources
12. Hosts/Groups
13. Job Templates
14. Workflow Templates
15. Notification Templates
16. Schedules
17. Applications

This order ensures parent objects exist before child objects reference them.
