---
name: ansible-scaffold-ee
description: >
  Scaffold Ansible Execution Environments using ansible-builder following Red Hat best practices.
  Use this skill when the user asks to: "create execution environment", "scaffold ee", "build execution environment",
  "ansible-builder", "execution environment definition", "containerized ansible", "ansible ee", "create ansible container",
  or wants to create a containerized Ansible runtime environment. Always invoke this skill for execution
  environment scaffolding tasks.
version: 1.0.0
allowed-tools: [Write, Read, Bash]
---

# Ansible Execution Environment Scaffolding Skill

Scaffold complete Ansible Execution Environments (EE) using ansible-builder, following Red Hat best practices for containerized Ansible automation.

## What is an Execution Environment?

An **Execution Environment (EE)** is a containerized runtime for Ansible that includes:
- Ansible Core/Engine
- Ansible Collections
- Python dependencies
- System dependencies
- Custom modules and plugins
- Runtime configuration

**Benefits:**
- **Consistency** - Same environment everywhere (dev, test, prod)
- **Isolation** - Dependencies don't conflict with host system
- **Portability** - Works on any container platform
- **Reproducibility** - Version-controlled runtime
- **Speed** - Pre-built dependencies, faster execution

**Use Cases:**
- Ansible Automation Platform (AAP) / AWX
- CI/CD pipelines
- Multi-environment automation
- Complex dependency management
- Kubernetes/OpenShift automation

## Execution Environment Structure

### Core File: execution-environment.yml

This is the definition file for ansible-builder:

```yaml
---
version: 3  # EE definition schema version

# Container image configuration
images:
  base_image:
    name: quay.io/ansible/creator-ee:latest

# Ansible configuration
ansible_config: ansible.cfg

# Dependencies
dependencies:
  galaxy: requirements.yml          # Collections
  python: requirements.txt          # Python packages
  system: bindep.txt               # System packages

# Additional files to copy
additional_build_files:
  - src: custom_files/
    dest: configs

# Custom build steps
additional_build_steps:
  prepend_base:
    - RUN echo "Custom base prep"
  prepend_galaxy:
    - RUN echo "Before galaxy install"
  append_galaxy:
    - RUN echo "After galaxy install"
  prepend_builder:
    - RUN echo "Before builder steps"
  append_builder:
    - RUN echo "After builder steps"
  append_final:
    - RUN echo "Final customizations"
    - RUN chmod -R g+w /runner

# Build arguments
build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: "--pre"
  PKGMGR_PRESERVE_CACHE: always

options:
  package_manager_path: /usr/bin/microdnf
  relax_passwd_permissions: true
  skip_ansible_check: false
  workdir: /runner
```

### Supporting Files

**1. requirements.yml** - Ansible Collections

```yaml
---
collections:
  - name: ansible.posix
    version: ">=1.5.4"
  
  - name: community.general
    version: ">=7.0.0"
  
  - name: kubernetes.core
    version: ">=2.4.0"
  
  - name: amazon.aws
    version: ">=5.0.0"

# Or from Git
  - name: company.custom_collection
    source: https://github.com/company/custom_collection.git
    type: git
    version: main
```

**2. requirements.txt** - Python Dependencies

```txt
# Python packages needed by collections or custom modules
boto3>=1.26.0
botocore>=1.29.0
kubernetes>=28.0.0
openshift>=0.13.0
jmespath>=1.0.0
netaddr>=0.8.0
jinja2>=3.1.0
pyyaml>=6.0

# Specific versions for reproducibility
requests==2.31.0
urllib3==2.0.7
```

**3. bindep.txt** - System Dependencies

```txt
# Format: package_name [platform:distribution version]
# Common packages
git [platform:rpm]
git [platform:dpkg]
rsync [platform:rpm]
rsync [platform:dpkg]

# Network tools
openssh-clients [platform:rpm]
openssh-client [platform:dpkg]

# For specific collections
sshpass [platform:rpm]
sshpass [platform:dpkg]

# RedHat specific
python39-devel [platform:centos-8 platform:rhel-8]
python3-devel [platform:fedora]

# Debian specific
python3-dev [platform:ubuntu-20.04]
```

**4. ansible.cfg** - Ansible Configuration

```ini
[defaults]
inventory = /runner/inventory
roles_path = /runner/roles
collections_path = /runner/collections
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
callbacks_enabled = ansible.posix.profile_tasks

[privilege_escalation]
become = False

[persistent_connection]
command_timeout = 60
connect_timeout = 30
```

## Base Images

### Official Ansible Images

**Recommended base images from Red Hat/Ansible:**

1. **ansible/creator-ee** - Kitchen sink, has everything
   ```yaml
   base_image:
     name: quay.io/ansible/creator-ee:latest
   ```

2. **ansible/ansible-runner** - Minimal runner
   ```yaml
   base_image:
     name: quay.io/ansible/ansible-runner:latest
   ```

3. **ansible/awx-ee** - AWX execution environment
   ```yaml
   base_image:
     name: quay.io/ansible/awx-ee:latest
   ```

4. **Red Hat Universal Base Image (UBI)**
   ```yaml
   base_image:
     name: registry.access.redhat.com/ubi9/ubi-minimal:latest
   ```

### Choosing Base Image

**Use ansible/creator-ee when:**
- Getting started
- Need comprehensive tooling
- Development/testing

**Use ansible/ansible-runner when:**
- Production minimalism
- Need smaller image
- Custom dependencies

**Use UBI when:**
- Red Hat environment
- Compliance requirements
- Full control over build

## Building Execution Environments

### Install ansible-builder

```bash
# Install ansible-builder
pip install ansible-builder

# Verify installation
ansible-builder --version
```

### Build Process

```bash
# Navigate to EE directory
cd execution-environment/

# Build the EE
ansible-builder build \
  --tag my-custom-ee:1.0.0 \
  --container-runtime podman \
  --verbosity 3

# Build options:
# --tag: Image name and tag
# --container-runtime: podman or docker
# --verbosity: 0-3 (detail level)
# --build-arg: Pass build arguments
# --prune-images: Clean up intermediate images
```

### Build Output

ansible-builder creates:
```
context/
├── _build/
│   ├── requirements.yml
│   ├── requirements.txt
│   ├── bindep.txt
│   └── ansible.cfg
├── Containerfile          # Generated Dockerfile
└── .dockerignore
```

### Multi-Stage Build

For smaller production images:

```yaml
---
version: 3

images:
  base_image:
    name: quay.io/ansible/ansible-runner:latest
  
additional_build_steps:
  # Use multi-stage build for smaller final image
  prepend_final:
    - FROM base as final
    - COPY --from=builder /usr /usr
    - COPY --from=builder /runner /runner
```

## Testing Execution Environments

### Run Locally

```bash
# Run interactive shell in EE
podman run -it --rm my-custom-ee:1.0.0 /bin/bash

# Run ansible command
podman run --rm my-custom-ee:1.0.0 ansible --version

# Run playbook
podman run --rm \
  -v $(pwd):/runner/project:Z \
  my-custom-ee:1.0.0 \
  ansible-playbook /runner/project/playbook.yml
```

### Test with ansible-navigator

```bash
# Install ansible-navigator
pip install ansible-navigator

# Run playbook with EE
ansible-navigator run playbook.yml \
  --execution-environment-image my-custom-ee:1.0.0 \
  --mode interactive

# Or set in ansible-navigator.yml
cat > ansible-navigator.yml <<EOF
---
ansible-navigator:
  execution-environment:
    image: my-custom-ee:1.0.0
    pull:
      policy: missing
  mode: interactive
EOF

# Then simply run
ansible-navigator run playbook.yml
```

### Validate Collections

```bash
# List installed collections
podman run --rm my-custom-ee:1.0.0 \
  ansible-galaxy collection list

# Verify specific collection
podman run --rm my-custom-ee:1.0.0 \
  ansible-galaxy collection verify ansible.posix
```

## Publishing Execution Environments

### Tag for Registry

```bash
# Tag for container registry
podman tag my-custom-ee:1.0.0 quay.io/myorg/my-custom-ee:1.0.0
podman tag my-custom-ee:1.0.0 quay.io/myorg/my-custom-ee:latest
```

### Push to Registry

```bash
# Login to registry
podman login quay.io

# Push image
podman push quay.io/myorg/my-custom-ee:1.0.0
podman push quay.io/myorg/my-custom-ee:latest
```

### Registry Options

**Popular registries:**
- **Quay.io** - Red Hat's container registry
- **Docker Hub** - Public/private images
- **GitHub Container Registry** - GitHub packages
- **Private Registry** - Self-hosted

## Advanced Patterns

### Custom Python Modules

Include custom modules in the EE:

```yaml
# execution-environment.yml
additional_build_files:
  - src: library/
    dest: /runner/library

additional_build_steps:
  append_final:
    - ENV ANSIBLE_LIBRARY=/runner/library
```

### Custom Plugins

```yaml
additional_build_files:
  - src: plugins/filter
    dest: /runner/plugins/filter
  - src: plugins/lookup
    dest: /runner/plugins/lookup

additional_build_steps:
  append_final:
    - ENV ANSIBLE_FILTER_PLUGINS=/runner/plugins/filter
    - ENV ANSIBLE_LOOKUP_PLUGINS=/runner/plugins/lookup
```

### SSL Certificates

```yaml
additional_build_files:
  - src: certs/ca-bundle.crt
    dest: /etc/pki/ca-trust/source/anchors/

additional_build_steps:
  append_final:
    - RUN update-ca-trust
```

### Proxy Configuration

```yaml
build_arg_defaults:
  HTTP_PROXY: "http://proxy.company.com:8080"
  HTTPS_PROXY: "http://proxy.company.com:8080"
  NO_PROXY: "localhost,127.0.0.1,.company.com"

additional_build_steps:
  prepend_base:
    - ENV HTTP_PROXY=${HTTP_PROXY}
    - ENV HTTPS_PROXY=${HTTPS_PROXY}
    - ENV NO_PROXY=${NO_PROXY}
```

### Non-Root User

```yaml
options:
  user: 1000
  relax_passwd_permissions: true

additional_build_steps:
  append_final:
    - RUN chmod -R g+w /runner
    - USER 1000
```

## Project Structure

Recommended EE project structure:

```
execution-environment/
├── execution-environment.yml    # Main definition
├── requirements.yml             # Collections
├── requirements.txt             # Python packages
├── bindep.txt                  # System packages
├── ansible.cfg                 # Ansible config
├── custom_files/               # Additional files
│   ├── certs/
│   └── configs/
├── library/                    # Custom modules
├── plugins/                    # Custom plugins
│   ├── filter/
│   └── lookup/
├── README.md                   # Documentation
└── .gitignore
```

## Version Management

### Semantic Versioning

Use semantic versioning for EE images:

```
my-ee:1.0.0      # Major.Minor.Patch
my-ee:1.0        # Major.Minor (latest patch)
my-ee:1          # Major (latest minor)
my-ee:latest     # Latest version (use with caution)
```

### Changelog

Maintain changelog for EE versions:

```markdown
# my-custom-ee Changelog

## 1.1.0 - 2026-04-25
- Added kubernetes.core 2.4.0
- Updated ansible.posix to 1.5.4
- Added jmespath Python library
- Fixed SSL certificate handling

## 1.0.0 - 2026-04-01
- Initial release
- Ansible 2.15
- Core collections bundle
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/build-ee.yml
name: Build Execution Environment

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install ansible-builder
        run: pip install ansible-builder
      
      - name: Build EE
        run: |
          cd execution-environment
          ansible-builder build \
            --tag ghcr.io/${{ github.repository }}:${{ github.sha }} \
            --container-runtime docker
      
      - name: Push to registry
        if: startsWith(github.ref, 'refs/tags/')
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/${{ github.repository }}:${{ github.sha }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
build-ee:
  stage: build
  image: quay.io/ansible/creator-ee:latest
  services:
    - docker:dind
  script:
    - pip install ansible-builder
    - cd execution-environment
    - ansible-builder build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - main
    - tags
```

## Best Practices

### 1. Pin Versions

Always pin dependency versions for reproducibility:

```yaml
# requirements.yml
collections:
  - name: ansible.posix
    version: "1.5.4"  # Exact version

# requirements.txt
boto3==1.26.137       # Exact version
requests>=2.31.0,<3.0 # Range
```

### 2. Minimize Image Size

- Start with minimal base image
- Only include required dependencies
- Use multi-stage builds
- Clean up in same RUN layer

```dockerfile
RUN yum install -y package && \
    yum clean all && \
    rm -rf /var/cache/yum
```

### 3. Security Scanning

```bash
# Scan with trivy
trivy image my-custom-ee:1.0.0

# Scan with grype
grype my-custom-ee:1.0.0
```

### 4. Layer Optimization

Group related operations:

```yaml
additional_build_steps:
  append_final:
    # Good - single layer
    - RUN yum install -y pkg1 pkg2 && yum clean all
    
    # Bad - multiple layers
    # - RUN yum install -y pkg1
    # - RUN yum install -y pkg2
    # - RUN yum clean all
```

### 5. Documentation

Include comprehensive README:

```markdown
# Custom Execution Environment

## Contents
- Ansible 2.15.x
- Collections: ansible.posix, community.general, kubernetes.core
- Python: boto3, kubernetes, jmespath
- System: git, rsync, openssh-client

## Usage
\`\`\`bash
ansible-navigator run playbook.yml --ee-image my-custom-ee:1.0.0
\`\`\`

## Build
\`\`\`bash
ansible-builder build --tag my-custom-ee:1.0.0
\`\`\`
```

## Troubleshooting

### Build Failures

**Collection download fails:**
```bash
# Use pre-release flag
build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: "--pre"
```

**Python dependency conflicts:**
```bash
# Use specific versions in requirements.txt
# Check compatibility with: pip check
```

**System package not found:**
```bash
# Check bindep.txt syntax
# Verify package name for distro
# Test in base image first
```

### Runtime Issues

**Collection not found:**
```bash
# Verify collection installed
podman run --rm my-ee:1.0.0 ansible-galaxy collection list

# Check COLLECTIONS_PATH
podman run --rm my-ee:1.0.0 env | grep COLLECTIONS
```

**Permission denied:**
```yaml
# Fix permissions for non-root
options:
  relax_passwd_permissions: true

additional_build_steps:
  append_final:
    - RUN chmod -R g+w /runner
```

## Output Template

When scaffolding an EE, provide:

1. **execution-environment.yml** with appropriate base image
2. **requirements.yml** with essential collections
3. **requirements.txt** with Python dependencies
4. **bindep.txt** with system dependencies
5. **ansible.cfg** with sensible defaults
6. **README.md** with build and usage instructions
7. **.gitignore** for build artifacts
8. **Build and test commands**

Explain:
- Why each dependency is included
- How to build the EE
- How to test locally
- How to publish to registry
- How to use in automation

When asked to scaffold an execution environment, analyze requirements, create complete EE definition following Red Hat best practices, and provide comprehensive build and deployment guidance.
