# Molecule Testing Guide

Molecule provides a comprehensive testing framework for Ansible roles following Red Hat CoP standards.

## Molecule Test Sequence

Molecule runs a complete test workflow:

```
dependency → cleanup → destroy → syntax → create → prepare → converge → idempotence → side_effect → verify → cleanup → destroy
```

### Test Phases Explained

1. **dependency** - Install role dependencies (via galaxy)
2. **cleanup** - Clean up from previous run
3. **destroy** - Destroy test instances
4. **syntax** - Check Ansible syntax
5. **create** - Create test instances
6. **prepare** - Prepare instances (optional setup)
7. **converge** - Run the role
8. **idempotence** - Run role again, should report 0 changes
9. **side_effect** - Run side effect playbook (optional)
10. **verify** - Run verification tests
11. **cleanup** - Clean up
12. **destroy** - Destroy instances

## Basic Commands

```bash
# Full test sequence
molecule test

# Individual commands
molecule create      # Create test instances
molecule converge    # Apply the role
molecule verify      # Run verification tests
molecule idempotence # Test idempotence
molecule login       # SSH into test instance
molecule destroy     # Clean up instances

# Development workflow
molecule converge    # Apply your changes
# Make code changes
molecule converge    # Reapply
molecule verify      # Test
molecule destroy     # Clean up
```

## Molecule Configuration

### molecule/default/molecule.yml

```yaml
---
dependency:
  name: galaxy  # Install dependencies from galaxy

driver:
  name: podman  # Or docker, vagrant, ec2, etc.

platforms:
  - name: rhel9-instance
    image: registry.access.redhat.com/ubi9/ubi-init:latest
    pre_build_image: true
    privileged: true  # Required for systemd
    command: /sbin/init
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    capabilities:
      - SYS_ADMIN

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
        rolename_variable: "value"
      debian12-instance:
        rolename_variable: "value"

verifier:
  name: ansible

lint: |
  set -e
  ansible-lint
  yamllint .
```

## Converge Playbook

### molecule/default/converge.yml

```yaml
---
- name: Converge
  hosts: all
  become: true

  tasks:
    - name: Include role
      ansible.builtin.include_role:
        name: rolename
```

## Verification Tests

### molecule/default/verify.yml

```yaml
---
- name: Verify
  hosts: all
  become: true
  gather_facts: true

  tasks:
    - name: Gather package facts
      ansible.builtin.package_facts:
        manager: auto

    - name: Verify package is installed
      ansible.builtin.assert:
        that:
          - "'httpd' in ansible_facts.packages"
        fail_msg: "Apache package not found"
        success_msg: "Apache package installed"

    - name: Gather service facts
      ansible.builtin.service_facts:

    - name: Verify service is running
      ansible.builtin.assert:
        that:
          - ansible_facts.services['httpd.service'] is defined
          - ansible_facts.services['httpd.service'].state == 'running'
        fail_msg: "Apache service not running"
        success_msg: "Apache service is active"

    - name: Verify configuration file
      ansible.builtin.stat:
        path: /etc/httpd/conf/httpd.conf
      register: config_file

    - name: Assert configuration exists
      ansible.builtin.assert:
        that:
          - config_file.stat.exists
          - config_file.stat.isreg
          - config_file.stat.mode == '0644'
        fail_msg: "Configuration file missing or wrong permissions"

    - name: Verify service is listening
      ansible.builtin.wait_for:
        port: 80
        timeout: 10
      ignore_errors: true
      register: port_check

    - name: Report port status
      ansible.builtin.debug:
        msg: "Apache {{ 'is' if port_check is succeeded else 'is not' }} listening on port 80"

    - name: Test HTTP response
      ansible.builtin.uri:
        url: "http://localhost:80"
        status_code: [200, 403]  # 403 acceptable if no content
      register: http_check
      ignore_errors: true

    - name: Verify directory structure
      ansible.builtin.stat:
        path: "{{ item }}"
      register: dir_check
      failed_when: not dir_check.stat.exists or not dir_check.stat.isdir
      loop:
        - /etc/httpd
        - /var/log/httpd
        - /var/www/html
```

## Idempotence Testing

Critical test for Red Hat CoP compliance - role must be idempotent.

```bash
molecule idempotence
```

**Expected output:**
```
Idempotence completed successfully.
```

**If it fails:**
```
CRITICAL Idempotence test failed because of the following tasks:
* [instance] => Task Name
```

### Common Idempotence Issues

1. **Commands without changed_when:**
   ```yaml
   # Bad
   - ansible.builtin.command: some_command

   # Good
   - ansible.builtin.command: some_command
     changed_when: false
   ```

2. **Templates with timestamps:**
   ```jinja2
   {# Bad #}
   Generated: {{ ansible_date_time.iso8601 }}

   {# Good #}
   Generated: {{ ansible_managed }}
   ```

3. **Downloads without checksum:**
   ```yaml
   # Bad
   - ansible.builtin.get_url:
       url: https://example.com/file
       dest: /tmp/file

   # Good
   - ansible.builtin.get_url:
       url: https://example.com/file
       dest: /tmp/file
       checksum: "sha256:abc123..."
   ```

## Multi-Platform Testing

Test on multiple OS distributions:

```yaml
platforms:
  # RedHat family
  - name: rhel8
    image: registry.access.redhat.com/ubi8/ubi-init:latest
  - name: rhel9
    image: registry.access.redhat.com/ubi9/ubi-init:latest

  # Debian family
  - name: debian11
    image: debian:11
  - name: debian12
    image: debian:12

  # Ubuntu
  - name: ubuntu2004
    image: ubuntu:20.04
  - name: ubuntu2204
    image: ubuntu:22.04
```

## Scenario-Based Testing

Create multiple test scenarios:

```bash
# Create new scenario
molecule init scenario --driver-name podman centos9

# Test specific scenario
molecule test -s centos9

# List scenarios
molecule list
```

### Directory structure:
```
molecule/
├── default/
│   ├── molecule.yml
│   ├── converge.yml
│   └── verify.yml
├── centos9/
│   ├── molecule.yml
│   ├── converge.yml
│   └── verify.yml
└── ubuntu/
    ├── molecule.yml
    ├── converge.yml
    └── verify.yml
```

## Prepare Playbook

Run setup tasks before converging (installing dependencies, etc.):

### molecule/default/prepare.yml

```yaml
---
- name: Prepare
  hosts: all
  become: true

  tasks:
    - name: Update package cache (Debian)
      ansible.builtin.apt:
        update_cache: true
      when: ansible_os_family == "Debian"

    - name: Install dependencies
      ansible.builtin.package:
        name:
          - python3
          - python3-pip
        state: present

    - name: Install Python packages
      ansible.builtin.pip:
        name:
          - PyYAML
        state: present
```

## Debugging Molecule Tests

### View Logs

```bash
# Verbose output
molecule --debug test

# Keep instances after failure
molecule test --destroy=never

# Login to instance
molecule login
molecule login -h instance-name
```

### Common Issues

#### Podman/Docker not available
```bash
# Check driver is installed
podman --version
docker --version

# Use different driver
molecule test --driver-name docker
```

#### Container init issues
```yaml
# Ensure privileged mode for systemd
platforms:
  - name: instance
    privileged: true
    command: /sbin/init
```

#### Connection issues
```yaml
# Increase timeout
provisioner:
  name: ansible
  config_options:
    defaults:
      timeout: 60
```

## Linting Integration

Integrate ansible-lint with Molecule:

```yaml
# molecule/default/molecule.yml
lint: |
  set -e
  ansible-lint
  yamllint .
```

Run linting:
```bash
molecule lint
```

## CI/CD Integration

### GitLab CI

```yaml
# .gitlab-ci.yml
molecule-test:
  stage: test
  image: python:3.9
  services:
    - docker:dind
  before_script:
    - pip install molecule molecule-docker ansible-lint
  script:
    - molecule test
```

### GitHub Actions

```yaml
# .github/workflows/molecule.yml
name: Molecule
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
      - name: Install dependencies
        run: |
          pip install molecule molecule-docker ansible-lint
      - name: Run Molecule
        run: molecule test
```

## Best Practices

### 1. Test All Supported Platforms

```yaml
platforms:
  - name: rhel9
  - name: debian12
  - name: ubuntu2204
```

### 2. Write Comprehensive Verify Tests

Test not just that tasks run, but that desired state is achieved:
- Packages installed
- Services running
- Files present with correct permissions
- Ports listening
- HTTP responses correct

### 3. Always Test Idempotence

```bash
molecule idempotence  # Must pass
```

### 4. Use Prepare for Dependencies

Don't install test dependencies in main role - use prepare playbook.

### 5. Clean Up After Tests

```bash
molecule destroy  # Clean up instances
```

## Quick Reference

```bash
# Full test
molecule test

# Development cycle
molecule create && molecule converge
molecule verify
molecule destroy

# Debug
molecule --debug converge
molecule login

# Specific scenario
molecule test -s scenario_name

# Keep instances on failure
molecule test --destroy=never

# List instances
molecule list

# Cleanup
molecule cleanup
molecule destroy
```

## Resources

- Molecule documentation: https://molecule.readthedocs.io/
- Ansible testing strategies: https://docs.ansible.com/ansible/latest/reference_appendices/test_strategies.html
- Red Hat CoP testing: https://redhat-cop.github.io/automation-good-practices/
