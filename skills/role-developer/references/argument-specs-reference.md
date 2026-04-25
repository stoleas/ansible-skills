# Argument Specifications Reference - Red Hat CoP Standards

Argument specifications (`meta/argument_specs.yml`) provide parameter validation and documentation for Ansible roles (Ansible 2.11+).

## Why Use Argument Specs?

1. **Fail Fast:** Catch configuration errors before executing tasks
2. **Type Safety:** Validate parameter types automatically
3. **Documentation:** Machine-readable parameter documentation
4. **IDE Support:** Enable autocomplete in supported editors
5. **User Experience:** Clear error messages when parameters are wrong

## Basic Structure

```yaml
---
# File: meta/argument_specs.yml

argument_specs:
  main:  # Entry point name (usually "main")
    short_description: One-line description of the role
    description:
      - Detailed description line 1
      - Detailed description line 2
    author:
      - Your Name (@github_handle)
    options:
      parameter_name:
        description: What this parameter does
        type: str
        required: false
        default: "default_value"
```

## Supported Types

### String (`str`)

```yaml
apache_install_version:
  description: Apache version to install
  type: str
  required: false
  default: "2.4"

apache_install_server_name:
  description: Primary server name for Apache
  type: str
  required: true  # No default, must be provided
```

### Integer (`int`)

```yaml
apache_install_listen_port:
  description: Port number for Apache to listen on
  type: int
  required: false
  default: 80

apache_install_max_clients:
  description: Maximum number of concurrent clients
  type: int
  required: false
  default: 150
```

### Float (`float`)

```yaml
apache_install_timeout:
  description: Request timeout in seconds
  type: float
  required: false
  default: 30.5
```

### Boolean (`bool`)

```yaml
apache_install_ssl_enabled:
  description: Enable SSL/TLS support
  type: bool
  required: false
  default: false

apache_install_debug_mode:
  description: Enable debug logging
  type: bool
  required: false
  default: false
```

### List (`list`)

```yaml
apache_install_modules:
  description: List of Apache modules to enable
  type: list
  elements: str  # Type of list elements
  required: false
  default: []

apache_install_ports:
  description: List of ports to listen on
  type: list
  elements: int
  required: false
  default: [80]
```

### Dictionary (`dict`)

```yaml
apache_install_ssl_config:
  description: SSL configuration dictionary
  type: dict
  required: false
  default: {}
  options:
    certificate:
      description: Path to SSL certificate
      type: path
      required: true
    key:
      description: Path to SSL private key
      type: path
      required: true
    protocol:
      description: SSL/TLS protocol version
      type: str
      required: false
      default: "TLSv1.2"
```

### Path (`path`)

```yaml
apache_install_config_file:
  description: Path to main Apache configuration file
  type: path
  required: false
  default: "/etc/httpd/conf/httpd.conf"

apache_install_document_root:
  description: Document root directory
  type: path
  required: true
```

### Raw (`raw`)

Use sparingly - accepts any type without validation.

```yaml
apache_install_custom_config:
  description: Custom configuration (any format)
  type: raw
  required: false
```

## Advanced Features

### Choices (Enumeration)

Limit values to specific choices:

```yaml
apache_install_service_state:
  description: Desired state of Apache service
  type: str
  required: false
  default: "started"
  choices:
    - started
    - stopped
    - restarted
    - reloaded

apache_install_log_level:
  description: Apache logging level
  type: str
  required: false
  default: "warn"
  choices:
    - emerg
    - alert
    - crit
    - error
    - warn
    - notice
    - info
    - debug
```

### Nested Dictionaries

Define complex nested structures:

```yaml
apache_install_vhosts:
  description: Virtual host configurations
  type: list
  elements: dict
  required: false
  default: []
  options:
    server_name:
      description: Server name (domain)
      type: str
      required: true
    server_alias:
      description: Server aliases
      type: list
      elements: str
      required: false
      default: []
    document_root:
      description: Document root for this vhost
      type: path
      required: true
    ssl:
      description: SSL configuration for this vhost
      type: dict
      required: false
      options:
        enabled:
          description: Enable SSL for this vhost
          type: bool
          required: false
          default: false
        certificate:
          description: Path to SSL certificate
          type: path
          required: true
        key:
          description: Path to SSL key
          type: path
          required: true
```

Usage:

```yaml
apache_install_vhosts:
  - server_name: example.com
    server_alias:
      - www.example.com
    document_root: /var/www/example
    ssl:
      enabled: true
      certificate: /etc/ssl/certs/example.crt
      key: /etc/ssl/private/example.key

  - server_name: test.example.com
    server_alias: []
    document_root: /var/www/test
```

### Aliases

Provide alternative parameter names:

```yaml
apache_install_listen_port:
  description: Port to listen on
  type: int
  required: false
  default: 80
  aliases:
    - apache_install_port
    - apache_port

# Users can use any of these:
# apache_install_listen_port: 8080
# apache_install_port: 8080
# apache_port: 8080
```

### Mutually Exclusive Options

Document options that cannot be used together:

```yaml
# In the top-level spec
argument_specs:
  main:
    short_description: Example role
    mutually_exclusive:
      - [apache_install_package, apache_install_source_install]

    options:
      apache_install_package:
        description: Install from package
        type: str
        required: false

      apache_install_source_install:
        description: Install from source
        type: bool
        required: false
```

### Required Together

Parameters that must be provided together:

```yaml
argument_specs:
  main:
    short_description: Example role
    required_together:
      - [apache_install_ssl_cert, apache_install_ssl_key]

    options:
      apache_install_ssl_cert:
        description: SSL certificate path
        type: path
        required: false

      apache_install_ssl_key:
        description: SSL key path
        type: path
        required: false
```

### Required One Of

At least one of these parameters must be provided:

```yaml
argument_specs:
  main:
    short_description: Example role
    required_one_of:
      - [apache_install_package_name, apache_install_source_url]

    options:
      apache_install_package_name:
        description: Package name to install
        type: str
        required: false

      apache_install_source_url:
        description: Source URL for compilation
        type: str
        required: false
```

## Complete Example

```yaml
---
# meta/argument_specs.yml for apache_install role

argument_specs:
  main:
    short_description: Install and configure Apache web server
    description:
      - This role installs Apache HTTP server from packages
      - Configures virtual hosts, SSL, and modules
      - Supports RHEL, Debian, and Ubuntu distributions
      - Ensures idempotent operation with proper configuration management
    author:
      - DevOps Team (@devops)

    # Relationship constraints
    required_together:
      - [apache_install_ssl_enabled, apache_install_ssl_cert_file, apache_install_ssl_key_file]

    # Parameter definitions
    options:
      # Version configuration
      apache_install_version:
        description:
          - Apache version to install
          - Must be available in the system repositories
        type: str
        required: false
        default: "2.4"

      # Service configuration
      apache_install_service_enabled:
        description: Whether to enable Apache service on boot
        type: bool
        required: false
        default: true

      apache_install_service_state:
        description: Desired state of the Apache service
        type: str
        required: false
        default: "started"
        choices:
          - started
          - stopped
          - restarted
          - reloaded

      # Network configuration
      apache_install_listen_port:
        description: Primary port for Apache to listen on
        type: int
        required: false
        default: 80

      apache_install_listen_ports:
        description: Additional ports for Apache to listen on
        type: list
        elements: int
        required: false
        default: []

      # Module configuration
      apache_install_modules:
        description:
          - List of Apache modules to enable
          - Modules must be available for the installed Apache version
        type: list
        elements: str
        required: false
        default:
          - ssl
          - rewrite

      # SSL/TLS configuration
      apache_install_ssl_enabled:
        description: Enable SSL/TLS support
        type: bool
        required: false
        default: false

      apache_install_ssl_cert_file:
        description:
          - Path to SSL certificate file
          - Required when apache_install_ssl_enabled is true
        type: path
        required: false

      apache_install_ssl_key_file:
        description:
          - Path to SSL private key file
          - Required when apache_install_ssl_enabled is true
        type: path
        required: false

      apache_install_ssl_protocol:
        description: SSL/TLS protocol version to use
        type: str
        required: false
        default: "TLSv1.2"
        choices:
          - TLSv1.2
          - TLSv1.3

      # Virtual hosts configuration
      apache_install_vhosts:
        description: List of virtual host configurations
        type: list
        elements: dict
        required: false
        default: []
        options:
          server_name:
            description: Primary server name (domain)
            type: str
            required: true

          server_alias:
            description: Additional server aliases
            type: list
            elements: str
            required: false
            default: []

          document_root:
            description: Document root directory for this vhost
            type: path
            required: true

          listen_port:
            description: Port for this virtual host
            type: int
            required: false
            default: 80

          ssl_enabled:
            description: Enable SSL for this vhost
            type: bool
            required: false
            default: false

      # Tuning parameters
      apache_install_max_clients:
        description: Maximum number of concurrent client connections
        type: int
        required: false
        default: 150

      apache_install_timeout:
        description: Request timeout in seconds
        type: int
        required: false
        default: 300

      # Logging configuration
      apache_install_log_level:
        description: Apache logging level
        type: str
        required: false
        default: "warn"
        choices:
          - emerg
          - alert
          - crit
          - error
          - warn
          - notice
          - info
          - debug

      apache_install_access_log:
        description: Path to access log file
        type: path
        required: false
        default: "/var/log/httpd/access_log"

      apache_install_error_log:
        description: Path to error log file
        type: path
        required: false
        default: "/var/log/httpd/error_log"

      # User and group
      apache_install_user:
        description: System user to run Apache as
        type: str
        required: false
        default: "apache"

      apache_install_group:
        description: System group for Apache
        type: str
        required: false
        default: "apache"

      # Advanced configuration
      apache_install_custom_config:
        description: Custom Apache configuration directives
        type: dict
        required: false
        default: {}
