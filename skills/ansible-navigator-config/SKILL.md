---
name: ansible-navigator-config
description: >
  Configure ansible-navigator for optimal workflow, execution environment integration, and
  troubleshooting. Use this skill when the user asks to: "configure ansible-navigator",
  "setup navigator", "navigator config", "ansible-navigator settings", "navigator ee integration",
  "navigator troubleshooting", "ansible-navigator.yml", "set up ansible navigator", or wants to
  configure or optimize their ansible-navigator workflow. Always invoke this skill for
  ansible-navigator configuration and usage guidance.
version: 1.0.0
allowed-tools: [Write, Read, Bash]
---

# Ansible Navigator Configuration Skill

Configure ansible-navigator for optimal workflow, execution environment integration, log management, and troubleshooting.

## What is ansible-navigator?

**ansible-navigator** is a text-based user interface (TUI) for Ansible that provides:
- **Interactive playbook execution** with real-time exploration
- **Execution environment integration** for containerized runs
- **Log replay** and analysis
- **Collection/inventory browsing**
- **Enhanced debugging** capabilities
- **Artifact generation** for CI/CD integration

**Key Benefits:**
- Consistent runtime environments (via EEs)
- Better visibility into playbook execution
- Improved troubleshooting workflow
- CI/CD friendly (stdout mode)
- Log replay for post-execution analysis

## Installation

```bash
# Install ansible-navigator
pip install ansible-navigator

# Verify installation
ansible-navigator --version

# Optional: Install execution environment support
pip install ansible-builder

# Container runtime (one of these)
# Podman (recommended)
sudo dnf install podman

# Or Docker
sudo apt-get install docker.io
```

## Configuration File: ansible-navigator.yml

Place in project root or home directory (`~/.ansible-navigator.yml`).

### Basic Configuration

```yaml
---
ansible-navigator:
  # Execution environment settings
  execution-environment:
    enabled: true
    image: quay.io/ansible/creator-ee:latest
    pull:
      policy: missing  # missing, always, never, tag
    container-engine: podman  # podman or docker
    
  # Mode settings
  mode: interactive  # interactive or stdout
  
  # Playbook execution settings
  playbook-artifact:
    enable: true
    replay: artifacts/
    save-as: "{playbook_dir}/artifacts/{playbook_name}-artifact-{time_stamp}.json"
  
  # Logging
  logging:
    level: info  # debug, info, warning, error, critical
    append: true
    file: ansible-navigator.log
  
  # Editor for interactive mode
  editor:
    command: vim {filename}
    console: true
  
  # Inventory settings
  inventories:
    - inventory/production
    - inventory/staging
```

### Advanced Configuration

```yaml
---
ansible-navigator:
  # Execution environment configuration
  execution-environment:
    enabled: true
    image: my-custom-ee:1.0.0
    
    pull:
      policy: missing
      arguments:
        - "--tls-verify=false"  # For internal registries
    
    container-engine: podman
    container-options:
      - "--net=host"           # Use host networking
      - "--privileged"         # If needed (use cautiously)
    
    environment-variables:
      set:
        ANSIBLE_CONFIG: /runner/project/ansible.cfg
        CUSTOM_VAR: value
      pass:
        - HTTP_PROXY
        - HTTPS_PROXY
    
    volume-mounts:
      - src: /local/path
        dest: /runner/local
        options: Z  # SELinux label
  
  # Ansible configuration
  ansible:
    config: ansible.cfg
    cmdline: "--forks 15 --timeout 60"
    inventories:
      - inventory/
  
  # Playbook configuration
  playbook-artifact:
    enable: true
    replay: artifacts/
    save-as: "artifacts/{playbook_name}-{time_stamp}.json"
  
  # Documentation settings
  documentation:
    plugin:
      name: shell
      type: module
  
  # Collection settings
  collection-doc-cache-path: ~/.cache/ansible-navigator/collection_doc_cache
  
  # Color settings
  color:
    enable: true
    osc4: true  # Terminal color change support
  
  # Display settings
  display-color:
    changed: yellow
    debug: dark_gray
    ok: green
    skip: cyan
  
  # Editor configuration
  editor:
    command: code -w {filename}  # VS Code
    console: false
  
  # Format settings
  format: yaml  # yaml or json
  
  # Logging
  logging:
    level: debug
    append: true
    file: ~/.ansible-navigator.log
  
  # Mode
  mode: interactive
  
  # Images
  images:
    details:
      - ansible_version
      - python_version
      - collections
  
  # Time zone
  time-zone: UTC
```

## Execution Environment Integration

### Using Custom EE

```yaml
---
ansible-navigator:
  execution-environment:
    enabled: true
    image: quay.io/myorg/my-custom-ee:1.0.0
    pull:
      policy: missing
    
    # Mount project directory
    volume-mounts:
      - src: "{project_dir}"
        dest: /runner/project
        options: Z
      
      # Mount SSH keys
      - src: ~/.ssh
        dest: /home/runner/.ssh
        options: ro,Z
      
      # Mount custom inventory
      - src: /etc/ansible/inventory
        dest: /runner/inventory
        options: ro,Z
```

### Environment Variables

```yaml
execution-environment:
  environment-variables:
    # Set variables
    set:
      ANSIBLE_VAULT_PASSWORD_FILE: /runner/.vault_pass
      ANSIBLE_FORCE_COLOR: "true"
      CUSTOM_API_KEY: "${API_KEY}"  # From host environment
    
    # Pass through from host
    pass:
      - AWS_ACCESS_KEY_ID
      - AWS_SECRET_ACCESS_KEY
      - HTTP_PROXY
      - HTTPS_PROXY
      - NO_PROXY
```

### Without Execution Environment

For local Ansible installation:

```yaml
---
ansible-navigator:
  execution-environment:
    enabled: false  # Use local Ansible
  
  ansible:
    config: ansible.cfg
    playbook: playbooks/site.yml
```

## Mode Configuration

### Interactive Mode (Development)

Best for development and troubleshooting:

```yaml
ansible-navigator:
  mode: interactive
  
  editor:
    command: vim {filename}
    console: true
  
  playbook-artifact:
    enable: true
    save-as: "artifacts/{playbook_name}-artifact.json"
```

**Features:**
- Navigate through playbook execution
- Drill into tasks, hosts, results
- Review documentation inline
- Replay from artifacts

**Usage:**
```bash
ansible-navigator run playbook.yml
# Interactive TUI launches
# Use arrow keys to navigate
# Press number keys to drill down
# Press ESC to go back
# Press :q to quit
```

### Stdout Mode (CI/CD)

Best for automation and CI/CD:

```yaml
ansible-navigator:
  mode: stdout
  
  playbook-artifact:
    enable: true
    save-as: "artifacts/{playbook_name}-{time_stamp}.json"
  
  logging:
    level: info
    file: ansible-navigator.log
```

**Features:**
- Standard output (like ansible-playbook)
- Artifact generation for later review
- CI/CD friendly
- Non-interactive

**Usage:**
```bash
ansible-navigator run playbook.yml --mode stdout
# Output goes to stdout like normal
# Artifact saved for replay
```

## Command Patterns

### Running Playbooks

```bash
# Interactive mode
ansible-navigator run playbook.yml

# Stdout mode (CI/CD)
ansible-navigator run playbook.yml --mode stdout

# With specific inventory
ansible-navigator run playbook.yml -i inventory/production

# With extra vars
ansible-navigator run playbook.yml -e "env=production"

# With tags
ansible-navigator run playbook.yml --tags install,configure

# Check mode
ansible-navigator run playbook.yml --check

# With custom EE
ansible-navigator run playbook.yml \
  --execution-environment-image my-ee:1.0.0

# Replay from artifact
ansible-navigator replay artifacts/site-artifact-2026-04-25.json
```

### Exploring Collections

```bash
# Browse collections
ansible-navigator collections

# View specific collection
ansible-navigator collections ansible.posix

# View module documentation
ansible-navigator doc ansible.builtin.copy

# Search modules
ansible-navigator doc -l | grep copy
```

### Exploring Inventory

```bash
# Browse inventory
ansible-navigator inventory

# View specific host
ansible-navigator inventory --host server01

# List all hosts
ansible-navigator inventory --list

# Graph view
ansible-navigator inventory --graph
```

### Exploring Images

```bash
# List EE images
ansible-navigator images

# Inspect specific image
ansible-navigator images my-custom-ee:1.0.0

# Show image details (collections, python version, etc.)
ansible-navigator images my-custom-ee:1.0.0 --details
```

### Configuration

```bash
# Show current configuration
ansible-navigator config

# Dump configuration
ansible-navigator config dump

# Show configuration sources
ansible-navigator config dump --mode stdout
```

## Artifact Analysis

Artifacts are JSON files containing complete playbook execution details.

### Artifact Structure

```json
{
  "version": "1.0",
  "plays": [
    {
      "play": {
        "name": "Configure web servers",
        "id": "uuid",
        "duration": {"start": "...", "end": "..."}
      },
      "tasks": [
        {
          "task": {
            "name": "Install Apache",
            "id": "uuid"
          },
          "hosts": {
            "server01": {
              "action": "ansible.builtin.package",
              "changed": true,
              "failed": false,
              "result": {...}
            }
          }
        }
      ]
    }
  ]
}
```

### Replay Artifacts

```bash
# Replay in interactive mode
ansible-navigator replay artifacts/playbook-artifact.json

# Extract specific information with jq
jq '.plays[0].tasks[] | select(.task.name == "Install Apache")' \
  artifacts/playbook-artifact.json

# Count changed tasks
jq '[.plays[].tasks[].hosts[] | select(.changed == true)] | length' \
  artifacts/playbook-artifact.json

# List failed tasks
jq -r '.plays[].tasks[] | select(.hosts[].failed == true) | .task.name' \
  artifacts/playbook-artifact.json
```

## Logging and Debugging

### Log Configuration

```yaml
ansible-navigator:
  logging:
    level: debug  # For troubleshooting
    append: true
    file: ~/.ansible-navigator/navigator.log
```

### Log Analysis

```bash
# View recent logs
tail -f ~/.ansible-navigator/navigator.log

# Search for errors
grep -i error ~/.ansible-navigator/navigator.log

# Filter by log level
grep "ERROR\|CRITICAL" ~/.ansible-navigator/navigator.log
```

### Debug Output

```bash
# Run with increased verbosity
ansible-navigator run playbook.yml -vvv

# Debug mode in config
ansible-navigator:
  logging:
    level: debug
  ansible:
    cmdline: "-vvv"
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Run Ansible Playbook

on:
  push:
    branches: [main]

jobs:
  ansible:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install ansible-navigator
        run: pip install ansible-navigator
      
      - name: Run playbook
        run: |
          ansible-navigator run playbook.yml \
            --mode stdout \
            --pull-policy always \
            --execution-environment-image my-ee:latest
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playbook-artifact
          path: artifacts/*.json
```

### GitLab CI

```yaml
ansible-playbook:
  stage: deploy
  image: quay.io/ansible/creator-ee:latest
  script:
    - pip install ansible-navigator
    - |
      ansible-navigator run site.yml \
        --mode stdout \
        --execution-environment-image ${CI_REGISTRY_IMAGE}/ansible-ee:latest \
        --pull-policy always
  artifacts:
    paths:
      - artifacts/*.json
    when: always
```

### Jenkins

```groovy
pipeline {
  agent any
  
  stages {
    stage('Run Ansible') {
      steps {
        sh '''
          pip install ansible-navigator
          ansible-navigator run playbook.yml \
            --mode stdout \
            --execution-environment-image my-ee:1.0.0
        '''
      }
    }
  }
  
  post {
    always {
      archiveArtifacts artifacts: 'artifacts/*.json'
    }
  }
}
```

## Troubleshooting

### Common Issues

#### 1. EE Image Not Found

**Problem:**
```
Error: image not found: my-custom-ee:1.0.0
```

**Solutions:**
```yaml
# Pull the image first
execution-environment:
  pull:
    policy: always  # Force pull

# Or use full registry path
execution-environment:
  image: quay.io/myorg/my-custom-ee:1.0.0
```

```bash
# Manually pull image
podman pull my-custom-ee:1.0.0

# Check available images
podman images
```

#### 2. Volume Mount Permission Denied

**Problem:**
```
Error: Permission denied accessing /runner/project
```

**Solutions:**
```yaml
# Add SELinux label (on RHEL/Fedora)
volume-mounts:
  - src: "{project_dir}"
    dest: /runner/project
    options: Z  # Relabel for container

# Or run with privileged
container-options:
  - "--privileged"  # Use cautiously
```

#### 3. SSH Key Access

**Problem:**
```
Error: SSH key not accessible in container
```

**Solutions:**
```yaml
# Mount SSH directory
volume-mounts:
  - src: ~/.ssh
    dest: /home/runner/.ssh
    options: ro,Z

# Or use ssh-agent forwarding
environment-variables:
  set:
    SSH_AUTH_SOCK: /run/user/1000/ssh-agent.sock

volume-mounts:
  - src: /run/user/1000/ssh-agent.sock
    dest: /run/user/1000/ssh-agent.sock
```

#### 4. Inventory Not Found

**Problem:**
```
Error: Unable to find inventory
```

**Solutions:**
```yaml
# Specify inventory explicitly
ansible:
  inventories:
    - inventory/production

# Or mount external inventory
volume-mounts:
  - src: /etc/ansible/inventory
    dest: /runner/inventory
    options: ro,Z
```

#### 5. Collection Not Found in EE

**Problem:**
```
Error: collection not found in execution environment
```

**Solutions:**
```bash
# Verify collections in EE
ansible-navigator images my-ee:1.0.0 --details

# Or run with local collections
execution-environment:
  volume-mounts:
    - src: ~/.ansible/collections
      dest: /runner/collections
      options: ro,Z
```

## Project Configuration Examples

### Development Setup

```yaml
---
# ansible-navigator.yml (development)
ansible-navigator:
  execution-environment:
    enabled: true
    image: quay.io/ansible/creator-ee:latest
    pull:
      policy: missing
    volume-mounts:
      - src: "{project_dir}"
        dest: /runner/project
        options: Z
  
  mode: interactive
  
  editor:
    command: code -w {filename}
    console: false
  
  playbook-artifact:
    enable: true
    save-as: "artifacts/{playbook_name}-artifact.json"
  
  logging:
    level: info
    file: navigator.log
```

### Production/CI Setup

```yaml
---
# ansible-navigator.yml (production)
ansible-navigator:
  execution-environment:
    enabled: true
    image: quay.io/myorg/prod-ee:1.0.0
    pull:
      policy: always
    
    environment-variables:
      pass:
        - VAULT_PASSWORD
        - AWS_ACCESS_KEY_ID
        - AWS_SECRET_ACCESS_KEY
  
  mode: stdout
  
  ansible:
    config: ansible.cfg
    cmdline: "--forks 20"
  
  playbook-artifact:
    enable: true
    save-as: "artifacts/{playbook_name}-{time_stamp}.json"
  
  logging:
    level: warning
    file: /var/log/ansible-navigator.log
```

### Multi-Environment Setup

```yaml
---
# ansible-navigator.yml (multi-env)
ansible-navigator:
  execution-environment:
    enabled: true
    image: my-ee:${ENV_TAG:-latest}  # Environment-specific tag
    
    volume-mounts:
      - src: "{project_dir}"
        dest: /runner/project
        options: Z
      - src: "inventory/${ENV:-dev}"
        dest: /runner/inventory
        options: ro,Z
  
  ansible:
    inventories:
      - inventory/${ENV:-dev}
  
  mode: ${NAVIGATOR_MODE:-interactive}
```

Usage:
```bash
# Development
ENV=dev ansible-navigator run playbook.yml

# Staging
ENV=staging NAVIGATOR_MODE=stdout ansible-navigator run playbook.yml

# Production
ENV=production ENV_TAG=1.0.0 NAVIGATOR_MODE=stdout \
  ansible-navigator run playbook.yml
```

## Best Practices

### 1. Always Use Artifacts

```yaml
playbook-artifact:
  enable: true
  save-as: "artifacts/{playbook_name}-{time_stamp}.json"
```

**Benefits:**
- Post-execution analysis
- Debugging failed runs
- Audit trail
- CI/CD integration

### 2. Pin EE Versions in Production

```yaml
# Good - specific version
execution-environment:
  image: my-ee:1.2.3

# Bad - unpredictable
execution-environment:
  image: my-ee:latest
```

### 3. Use Appropriate Mode

- **Development**: `mode: interactive`
- **CI/CD**: `mode: stdout`
- **Debugging**: `mode: interactive` + `logging.level: debug`

### 4. Organize Artifacts

```bash
artifacts/
├── development/
├── staging/
└── production/
```

```yaml
playbook-artifact:
  save-as: "artifacts/${ENV}/{playbook_name}-{time_stamp}.json"
```

### 5. Secure Sensitive Data

```yaml
# Never commit passwords
# Use environment variables
environment-variables:
  pass:
    - VAULT_PASSWORD
    - API_TOKEN
    - AWS_SECRET_ACCESS_KEY

# Mount secrets securely
volume-mounts:
  - src: ~/.vault_pass
    dest: /runner/.vault_pass
    options: ro,Z
```

## Quick Reference

### Common Commands

```bash
# Run playbook interactively
ansible-navigator run playbook.yml

# Run in CI/CD mode
ansible-navigator run playbook.yml --mode stdout

# Replay artifact
ansible-navigator replay artifacts/playbook-artifact.json

# Browse collections
ansible-navigator collections

# View documentation
ansible-navigator doc ansible.builtin.copy

# Check inventory
ansible-navigator inventory --list

# Inspect EE image
ansible-navigator images my-ee:1.0.0

# Show config
ansible-navigator config dump
```

### Interactive Mode Keys

- **Arrow keys**: Navigate
- **Number keys**: Drill down (0-9)
- **ESC**: Go back
- **:** : Command mode
- **:q**: Quit
- **:help**: Show help
- **:o**: Open in editor
- **:f**: Filter
- **:write**: Save output

## Output Template

When configuring ansible-navigator, provide:

1. **ansible-navigator.yml** with appropriate settings
2. **Explanation** of key configuration choices
3. **Usage examples** for common scenarios
4. **Troubleshooting** guidance for likely issues
5. **Integration** examples (CI/CD if applicable)

Explain:
- Why specific settings were chosen
- How to run in different modes
- How to analyze artifacts
- How to troubleshoot common issues
- How to integrate with workflows

When asked to configure ansible-navigator, analyze requirements, generate appropriate configuration, and provide comprehensive usage and troubleshooting guidance.
