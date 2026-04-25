# Variable Naming Conventions - Red Hat CoP Standards

This guide explains the variable naming conventions required by Red Hat Communities of Practice.

## Core Principle

**ALL role variables MUST be prefixed with the role name.**

This prevents namespace collisions and makes it immediately clear where a variable comes from.

## Variable Types

### 1. External Variables (User-Facing)

These are variables users can and should override to configure the role.

**Location:** `defaults/main.yml`

**Naming Pattern:** `rolename_purpose_detail`

```yaml
---
# File: roles/apache_install/defaults/main.yml

# Good examples
apache_install_version: "2.4"
apache_install_listen_port: 80
apache_install_ssl_enabled: true
apache_install_document_root: "/var/www/html"
apache_install_modules:
  - ssl
  - rewrite
apache_install_vhost_config:
  server_name: "example.com"
  server_admin: "admin@example.com"

# Bad examples - avoid these
version: "2.4"                    # No role prefix
apache-port: 80                   # Dash instead of underscore
apacheInstallSSL: true            # CamelCase not allowed
ap_ssl: true                      # Abbreviation unclear
apache.ssl.enabled: true          # Dots not allowed
```

### 2. Internal Variables (Implementation Details)

These are variables used only within the role for internal logic.

**Location:** `vars/main.yml` or platform-specific files like `vars/RedHat.yml`

**Naming Pattern:** `__rolename_purpose_detail` (double underscore prefix)

```yaml
---
# File: roles/apache_install/vars/main.yml

# Good examples
__apache_install_package_name: "httpd"
__apache_install_service_name: "httpd"
__apache_install_config_dir: "/etc/httpd/conf.d"
__apache_install_temp_dir: "/tmp/apache_install"
__apache_install_required_facts:
  - ansible_os_family
  - ansible_distribution

# Bad examples
_apache_install_internal: "value"  # Single underscore not standard
apache_install_internal: "value"   # No underscore prefix (looks external)
__httpd_package: "httpd"           # Uses service name not role name
```

### 3. Registered Variables

Variables created by `register` directive should follow internal naming.

```yaml
---
# Good
- name: Check if Apache is installed
  ansible.builtin.stat:
    path: /usr/sbin/httpd
  register: __apache_install_binary_check

- name: Get Apache version
  ansible.builtin.command: httpd -v
  register: __apache_install_version_output
  changed_when: false

# Bad
- name: Check Apache
  ansible.builtin.stat:
    path: /usr/sbin/httpd
  register: apache_check  # No role prefix, not marked as internal
```

## Naming Components

### Structure: `rolename_category_subcategory_attribute`

Break down variable names logically:

```yaml
---
# Role: postgresql_install

# Basic structure
postgresql_install_version: "14"

# With category
postgresql_install_service_enabled: true
postgresql_install_service_state: "started"

# With subcategory
postgresql_install_connection_max_connections: 100
postgresql_install_connection_port: 5432

# Complex nested
postgresql_install_tuning_shared_buffers: "256MB"
postgresql_install_tuning_effective_cache_size: "1GB"
postgresql_install_logging_destination: "stderr"
postgresql_install_logging_level: "info"
```

### Avoid Abbreviations

**Clarity beats brevity.** Use full words.

```yaml
# Good - clear and descriptive
apache_install_configuration_file: "/etc/httpd/conf/httpd.conf"
apache_install_maximum_connections: 150
apache_install_enable_status_page: true
apache_install_document_root_directory: "/var/www/html"

# Bad - unclear abbreviations
apache_install_cfg_file: "/etc/httpd/conf/httpd.conf"
apache_install_max_conn: 150
apache_install_en_status: true
apache_install_doc_root_dir: "/var/www/html"
```

## Platform-Specific Variables

Use platform-specific variable files for OS differences.

```yaml
# File: vars/RedHat.yml
---
__apache_install_package_name: "httpd"
__apache_install_service_name: "httpd"
__apache_install_config_dir: "/etc/httpd/conf.d"
__apache_install_module_path: "/usr/lib64/httpd/modules"
__apache_install_user: "apache"
__apache_install_group: "apache"

# File: vars/Debian.yml
---
__apache_install_package_name: "apache2"
__apache_install_service_name: "apache2"
__apache_install_config_dir: "/etc/apache2/sites-available"
__apache_install_module_path: "/usr/lib/apache2/modules"
__apache_install_user: "www-data"
__apache_install_group: "www-data"
```

These are loaded in `tasks/main.yml`:

```yaml
- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"
  tags: ['always']
```

## Variable Documentation

Always document variables in `defaults/main.yml`:

```yaml
---
# defaults/main.yml for apache_install

# Apache version configuration
# Type: string
# Description: Apache version to install (e.g., "2.4")
# Default: "2.4"
# Required: No
apache_install_version: "2.4"

# Service configuration
# Type: boolean
# Description: Whether to enable Apache service on system boot
# Default: true
# Required: No
apache_install_service_enabled: true

# Type: string
# Description: Desired state of Apache service
# Default: "started"
# Required: No
# Choices: started, stopped, restarted, reloaded
apache_install_service_state: "started"

# Network configuration
# Type: integer
# Description: Port number for Apache to listen on
# Default: 80
# Required: No
# Valid range: 1-65535 (recommend 1024-65535 for non-root)
apache_install_listen_port: 80

# SSL/TLS configuration
# Type: boolean
# Description: Enable SSL/TLS support
# Default: false
# Required: No
apache_install_ssl_enabled: false

# Type: string
# Description: Path to SSL certificate file
# Default: ""
# Required: Yes (if apache_install_ssl_enabled is true)
apache_install_ssl_cert_file: ""

# Module configuration
# Type: list of strings
# Description: List of Apache modules to enable
# Default: []
# Required: No
# Example: ['ssl', 'rewrite', 'headers']
apache_install_modules: []
```

## Common Patterns

### Boolean Variables

Use descriptive boolean names:

```yaml
# Good - clear intent
apache_install_ssl_enabled: true
apache_install_compression_enabled: false
apache_install_status_page_enabled: true
apache_install_debug_logging_enabled: false

# Avoid - ambiguous
apache_install_ssl: true  # Is this enabled? A path? A version?
apache_install_compress: false  # Verb form unclear for boolean
```

### List Variables

Use plural names for lists:

```yaml
# Good
apache_install_modules:
  - ssl
  - rewrite
apache_install_virtual_hosts:
  - name: example.com
  - name: test.com

# Acceptable alternative with explicit _list suffix
apache_install_module_list:
  - ssl
  - rewrite
```

### Dictionary Variables

Use clear naming for dictionary variables:

```yaml
# Good
apache_install_ssl_config:
  certificate: "/path/to/cert.pem"
  key: "/path/to/key.pem"
  protocol: "TLSv1.2"

apache_install_tuning_parameters:
  max_connections: 150
  timeout: 300
  keepalive: true
```

## Variable Precedence Reminder

Understanding precedence helps name variables appropriately:

1. **Role defaults** (`defaults/main.yml`) - Lowest precedence, easily overridden
2. **Inventory variables** - Where users should define infrastructure state
3. **Facts** - System-discovered information
4. **Role vars** (`vars/main.yml`) - Higher precedence, hard to override
5. **Play vars** - Defined in playbook
6. **Block/task vars** - Scoped variables
7. **Extra vars** (`-e`) - Highest precedence, explicit overrides

**Rule of thumb:**
- User-configurable options → `defaults/main.yml` (external naming)
- Internal constants/logic → `vars/main.yml` (internal naming with __)

## Anti-Patterns to Avoid

### 1. Generic Variable Names

```yaml
# Bad - too generic
enabled: true
version: "2.4"
port: 80

# Good - role-prefixed and specific
apache_install_service_enabled: true
apache_install_version: "2.4"
apache_install_listen_port: 80
```

### 2. Inconsistent Naming

```yaml
# Bad - inconsistent patterns
apache_install_sslEnabled: true
apache_install_ssl-cert: "/path"
apache_InstallSSLKey: "/path"

# Good - consistent snake_case with role prefix
apache_install_ssl_enabled: true
apache_install_ssl_certificate: "/path"
apache_install_ssl_key: "/path"
```

### 3. Special Characters

```yaml
# Bad - special characters cause issues
apache-install.ssl.enabled: true
apache_install@port: 80
apache/install/version: "2.4"

# Good - only underscores
apache_install_ssl_enabled: true
apache_install_listen_port: 80
apache_install_version: "2.4"
```

### 4. Role Name Mismatches

```yaml
# Role name: apache_install

# Bad - uses different name
httpd_version: "2.4"  # Should use apache_install prefix
web_server_port: 80   # Should use apache_install prefix

# Good - consistent with role name
apache_install_version: "2.4"
apache_install_listen_port: 80
```

## Quick Reference

### External Variables Checklist
- [ ] Prefix with role name
- [ ] Use snake_case
- [ ] No abbreviations
- [ ] Documented in defaults/main.yml
- [ ] Include type, description, default, required status

### Internal Variables Checklist
- [ ] Prefix with `__rolename_`
- [ ] Use snake_case
- [ ] Define in vars/main.yml or platform-specific files
- [ ] Never override in inventory (use defaults for that)

### Platform Variables Checklist
- [ ] Use internal naming (`__prefix`)
- [ ] Separate files per OS family (RedHat.yml, Debian.yml)
- [ ] Loaded via include_vars in tasks/main.yml
- [ ] Document differences in comments
