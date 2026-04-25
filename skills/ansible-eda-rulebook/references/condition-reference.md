# Condition Reference

Comprehensive guide to writing conditions in Ansible EDA rulebooks.

## Condition Syntax

Conditions use Jinja2-like expression syntax to match events.

### Basic Comparisons

```yaml
# Equality
condition: event.payload.status == "critical"
condition: event.payload.count == 100

# Inequality
condition: event.payload.status != "ok"

# Greater/Less than
condition: event.payload.cpu > 80
condition: event.payload.memory < 1024
condition: event.payload.value >= 90
condition: event.payload.threshold <= 100

# String matching (case-sensitive)
condition: event.payload.hostname == "web01"
condition: event.payload.environment != "development"
```

### Boolean Logic

```yaml
# AND (all conditions must be true)
condition: |
  event.payload.severity == "critical" and
  event.payload.environment == "production"

# OR (any condition must be true)
condition: |
  event.payload.severity == "critical" or
  event.payload.severity == "high"

# NOT (negate condition)
condition: not event.payload.is_test

# Complex combinations
condition: |
  (event.payload.severity == "critical" or event.payload.severity == "high") and
  event.payload.environment == "production" and
  not event.payload.maintenance_mode
```

### String Operations

```yaml
# String contains
condition: "'error' in event.payload.message"
condition: "'ERROR' in event.payload.log_line"

# String starts with
condition: event.payload.hostname.startswith("web-")
condition: event.payload.service.startswith("api")

# String ends with
condition: event.payload.hostname.endswith(".example.com")
condition: event.payload.file.endswith(".log")

# Case conversion
condition: event.payload.status.lower() == "critical"
condition: event.payload.environment.upper() == "PRODUCTION"

# String length
condition: event.payload.message | length > 100
```

### Regular Expressions

```yaml
# Match pattern
condition: event.payload.email is match(".*@example\\.com$")
condition: event.payload.ip is match("^192\\.168\\.")

# Search pattern (anywhere in string)
condition: event.payload.message is search("ERROR.*failed")

# Case-insensitive regex
condition: event.payload.message is match("(?i)error")
```

### List Operations

```yaml
# List membership
condition: event.payload.severity in ["critical", "high"]
condition: event.payload.service in ["web", "api", "database"]

# Check if item in list field
condition: "'production' in event.payload.environments"

# List length
condition: event.payload.tags | length > 0
```

### Dictionary/Object Access

```yaml
# Nested field access
condition: event.payload.metadata.environment == "prod"
condition: event.alert.labels.severity == "critical"

# Check if field exists
condition: event.payload.hostname is defined
condition: event.alert.annotations.runbook_url is defined

# Check if field is undefined/null
condition: event.payload.optional_field is not defined
condition: event.payload.value is none
```

### Numeric Operations

```yaml
# Arithmetic in conditions
condition: event.payload.value * 100 > 8000
condition: event.payload.usage / event.payload.capacity > 0.8

# Check if number
condition: event.payload.value is number

# Range checks
condition: event.payload.value > 80 and event.payload.value < 100
```

### Type Checks

```yaml
# Check type
condition: event.payload.value is string
condition: event.payload.count is number
condition: event.payload.data is mapping  # Dictionary
condition: event.payload.items is sequence  # List

# Check if defined
condition: event.payload.optional_field is defined
condition: event.payload.field is not defined
```

## Common Condition Patterns

### Multiple Event Types

```yaml
# Handle different severity levels
- name: Critical alerts
  condition: event.payload.severity == "critical"
  action: ...

- name: Warning alerts
  condition: event.payload.severity == "warning"
  action: ...

- name: Info alerts
  condition: event.payload.severity == "info"
  action: ...
```

### Environment-Specific

```yaml
# Production only
condition: |
  event.payload.environment == "production" and
  event.payload.severity in ["critical", "high"]

# Non-production
condition: event.payload.environment in ["dev", "staging", "test"]
```

### Time-Based (if timestamp in event)

```yaml
# Business hours (example - requires timestamp parsing)
condition: |
  event.payload.hour >= 9 and
  event.payload.hour <= 17 and
  event.payload.weekday not in [6, 7]
```

### Alertmanager-Specific

```yaml
# Firing alerts only
condition: event.alert.status == "firing"

# Specific alert by name
condition: |
  event.alert.status == "firing" and
  event.alert.labels.alertname == "HighCPU"

# Alert severity
condition: event.alert.labels.severity in ["critical", "warning"]

# Resolved alerts
condition: event.alert.status == "resolved"
```

### Kafka Event Patterns

```yaml
# Event type routing
condition: event.event_type == "user.signup"
condition: event.event_type.startswith("payment.")

# Event versioning
condition: |
  event.event_type == "order.created" and
  event.version == "2.0"
```

### Webhook Patterns

```yaml
# GitHub push to main
condition: |
  event.payload.ref == "refs/heads/main" and
  event.payload.repository.name == "my-app"

# GitHub pull request opened
condition: |
  event.payload.pull_request is defined and
  event.payload.action == "opened"

# GitLab pipeline failed
condition: |
  event.object_kind == "pipeline" and
  event.object_attributes.status == "failed"
```

### Threshold-Based

```yaml
# Single threshold
condition: event.payload.cpu_usage > 90

# Multiple thresholds
- name: Critical threshold
  condition: event.payload.value > 95
  action: ...

- name: Warning threshold
  condition: event.payload.value > 80 and event.payload.value <= 95
  action: ...

- name: Normal
  condition: event.payload.value <= 80
  action: ...
```

### Compound Conditions

```yaml
# Complex business logic
condition: |
  (
    event.payload.severity == "critical" and
    event.payload.environment == "production"
  ) or (
    event.payload.severity == "high" and
    event.payload.customer_tier == "premium"
  ) or (
    event.payload.service == "billing" and
    event.payload.error_rate > 10
  )
```

## Debugging Conditions

### Always-Match Rule

```yaml
# Use to see event structure
- name: Debug - show all events
  condition: true
  action:
    debug:
      msg: "{{ event | to_nice_yaml }}"
```

### Conditional Debug

```yaml
# Debug specific events
- name: Debug critical events
  condition: event.payload.severity == "critical"
  action:
    debug:
      msg: |
        Critical event received:
        Hostname: {{ event.payload.hostname }}
        Service: {{ event.payload.service }}
        Message: {{ event.payload.message }}
        Full event: {{ event | to_json }}
```

## Best Practices

### 1. Be Specific

```yaml
# Good - specific conditions
condition: |
  event.payload.severity == "critical" and
  event.payload.service == "database" and
  event.payload.environment == "production"

# Bad - too broad
condition: event.payload.severity == "critical"
```

### 2. Handle Undefined Fields

```yaml
# Good - check if defined
condition: |
  event.payload.optional_field is defined and
  event.payload.optional_field == "value"

# Bad - may cause errors if field missing
condition: event.payload.optional_field == "value"
```

### 3. Use Multi-line for Readability

```yaml
# Good - readable
condition: |
  event.alert.status == "firing" and
  event.alert.labels.severity == "critical" and
  event.alert.labels.environment == "production"

# Bad - hard to read
condition: event.alert.status == "firing" and event.alert.labels.severity == "critical" and event.alert.labels.environment == "production"
```

### 4. Order Rules by Specificity

```yaml
rules:
  # Most specific first
  - name: Critical production database
    condition: |
      event.payload.severity == "critical" and
      event.payload.service == "database" and
      event.payload.environment == "production"
    action: ...
  
  # Less specific
  - name: Critical production
    condition: |
      event.payload.severity == "critical" and
      event.payload.environment == "production"
    action: ...
  
  # Catch-all last
  - name: All other events
    condition: true
    action: ...
```

### 5. Test Conditions

```bash
# Use print-events to see event structure
ansible-rulebook --rulebook test.yml --print-events

# Send test events
curl -X POST http://localhost:5000/endpoint \
  -H "Content-Type: application/json" \
  -d '{"severity": "critical", "service": "test"}'
```
