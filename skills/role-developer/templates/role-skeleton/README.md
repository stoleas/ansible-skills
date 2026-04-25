# Ansible Role: [rolename]

## Description

[Detailed description of what this role does, its purpose, and when to use it]

## Requirements

- Ansible 2.11 or higher
- Supported platforms: RHEL 8/9, Debian 11/12, Ubuntu 20.04/22.04
- [Any additional requirements]

## Role Variables

### Required Variables

Variables that MUST be defined:

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `[rolename]_required_var` | string | [Description] | `"value"` |

### Optional Variables

Variables with defaults that can be overridden:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `[rolename]_package_name` | string | `"example-package"` | Package to install |
| `[rolename]_service_enabled` | boolean | `true` | Enable service on boot |
| `[rolename]_service_state` | string | `"started"` | Desired service state |
| `[rolename]_listen_port` | integer | `8080` | Port to listen on |
| `[rolename]_enabled_features` | list | `[]` | Features to enable |

See `defaults/main.yml` for the complete list with detailed documentation.

## Dependencies

None.

## Example Playbook

```yaml
---
- name: Example using [rolename]
  hosts: servers
  become: true

  roles:
    - role: namespace.collection.[rolename]
      [rolename]_package_name: "custom-package"
      [rolename]_listen_port: 9090
      [rolename]_enabled_features:
        - feature1
        - feature2
```

## Capabilities

- [Capability 1: Install and configure the service]
- [Capability 2: Multi-platform support (RHEL, Debian, Ubuntu)]
- [Capability 3: Idempotent operation]
- [Capability 4: Check mode support]

## Idempotency

**Idempotent:** Yes

This role is fully idempotent. Running it multiple times on the same host will produce the same result without unnecessary changes.

## Rollback

**Rollback supported:** [Yes/Partial/No]

[Describe rollback capabilities or explain why rollback is not supported]

Example rollback (if supported):
```yaml
- role: namespace.collection.[rolename]
  [rolename]_state: absent
```

## Check Mode

**Check mode supported:** Yes

This role fully supports check mode (`--check`) for dry-run validation.

## Testing

```bash
# Lint the role
ansible-lint

# Run Molecule tests
molecule test

# Test idempotence
molecule converge
molecule idempotence
```

## Supported Platforms

- Red Hat Enterprise Linux 8, 9
- CentOS 8, 9
- Debian 11 (Bullseye), 12 (Bookworm)
- Ubuntu 20.04 LTS (Focal), 22.04 LTS (Jammy)

## License

MIT

## Author

[Author Name]
[GitHub: @username]

## Contributing

Contributions welcome. Please:
1. Follow Red Hat CoP standards
2. Test with ansible-lint (moderate profile)
3. Ensure Molecule tests pass
4. Update documentation
