---
name: ansible-eda-rulebook
description: >
  Create Event-Driven Ansible rulebooks and integrate with event sources for automated
  infrastructure response. Use this skill when the user asks to: "create eda rulebook",
  "event-driven ansible", "ansible rulebook", "eda event source", "webhook automation",
  "event automation", "create rulebook for", "integrate event source", or wants to build
  event-driven automation with Ansible. Always invoke this skill for EDA rulebook creation
  and event source integration.
version: 1.0.0
allowed-tools: [Write, Read, Bash]
---

# Ansible Event-Driven Automation (EDA) Rulebook Skill

Create comprehensive Event-Driven Ansible rulebooks that respond to events from various sources, enabling automated infrastructure response and self-healing systems.

## What is Ansible Event-Driven Automation?

**Ansible EDA** enables event-driven automation by listening for events from various sources and automatically executing Ansible content in response.

**Key Components:**
- **Rulebooks**: YAML files defining event sources, conditions, and actions
- **Event Sources**: Plugins that listen for events (webhooks, Kafka, alerts, etc.)
- **Conditions**: Patterns to match specific events
- **Actions**: Automated responses (run playbooks, modules, job templates)
- **ansible-rulebook**: CLI tool for running rulebooks
- **EDA Controller**: Enterprise platform for managing EDA at scale

**Use Cases:**
- Incident response and remediation
- Self-healing infrastructure
- Security event response
- CI/CD pipeline integration
- Alert-driven automation
- Application monitoring response
- Network event handling
- IoT device management

## Installation

```bash
# Install ansible-rulebook
pip install ansible ansible-rulebook

# Install event source plugins
ansible-galaxy collection install ansible.eda

# Verify installation
ansible-rulebook --version

# Optional: Install Java for some event sources (Kafka, etc.)
sudo dnf install java-11-openjdk  # RHEL/Fedora
sudo apt-get install openjdk-11-jre  # Ubuntu/Debian
```

## Rulebook Structure

### Basic Rulebook Anatomy

```yaml
---
- name: Rulebook Name
  hosts: all  # or specific host group
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
  
  rules:
    - name: Rule Name
      condition: event.payload.status == "critical"
      action:
        run_playbook:
          name: remediate.yml
```

**Required Fields:**
- `name`: Descriptive rulebook name
- `hosts`: Target hosts (like playbooks)
- `sources`: List of event source plugins
- `rules`: List of rules with conditions and actions

### Complete Rulebook Example

```yaml
---
- name: Infrastructure Monitoring Response
  hosts: all
  
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
        token: "{{ lookup('env', 'WEBHOOK_TOKEN') }}"
  
  rules:
    - name: Critical alert response
      condition: |
        event.payload.severity == "critical" and
        event.payload.service == "web"
      action:
        run_playbook:
          name: playbooks/restart_web_service.yml
          extra_vars:
            target_host: "{{ event.payload.hostname }}"
            alert_id: "{{ event.payload.alert_id }}"
    
    - name: Disk space warning
      condition: event.payload.metric == "disk_usage" and event.payload.value > 80
      action:
        run_playbook:
          name: playbooks/cleanup_disk.yml
          extra_vars:
            hostname: "{{ event.payload.hostname }}"
            threshold: "{{ event.payload.value }}"
    
    - name: Log all events
      condition: true
      action:
        debug:
          msg: "Event received: {{ event }}"
```

## Event Sources

### 1. Webhook Source

Listen for HTTP webhooks from monitoring tools, CI/CD systems, or custom applications.

```yaml
sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
      token: "secret_token"  # Optional authentication
      hmac_secret: "hmac_key"  # Optional HMAC validation
      hmac_algo: sha256
      hmac_header: X-Hub-Signature-256
      hmac_format: hex
```

**Webhook Request Example:**
```bash
curl -X POST http://localhost:5000/endpoint \
  -H "Content-Type: application/json" \
  -d '{
    "severity": "critical",
    "service": "database",
    "hostname": "db01.example.com",
    "message": "Connection pool exhausted"
  }'
```

**Event Structure:**
```yaml
event:
  payload:
    severity: "critical"
    service: "database"
    hostname: "db01.example.com"
    message: "Connection pool exhausted"
  meta:
    endpoint: "/endpoint"
    headers: {...}
```

### 2. Alertmanager Source

Integrate with Prometheus Alertmanager for metric-based automation.

```yaml
sources:
  - ansible.eda.alertmanager:
      host: 0.0.0.0
      port: 8000
      data_alerts_path: alerts  # Path in webhook payload
```

**Alertmanager Webhook Config:**
```yaml
# alertmanager.yml
receivers:
  - name: ansible-eda
    webhook_configs:
      - url: http://eda-server:8000/endpoint
        send_resolved: true
```

**Rule Example:**
```yaml
rules:
  - name: Handle firing alert
    condition: event.alert.status == "firing"
    action:
      run_playbook:
        name: handle_alert.yml
        extra_vars:
          alert_name: "{{ event.alert.labels.alertname }}"
          severity: "{{ event.alert.labels.severity }}"
          instance: "{{ event.alert.labels.instance }}"
```

### 3. Kafka Source

Stream events from Apache Kafka topics.

```yaml
sources:
  - ansible.eda.kafka:
      host: kafka.example.com
      port: 9092
      topic: infrastructure-events
      group_id: ansible-eda-consumer
      offset: latest  # or earliest
```

**Use Case:** Real-time event processing from application logs, metrics, or audit trails.

### 4. AWS SNS Source

Receive events from AWS Simple Notification Service.

```yaml
sources:
  - ansible.eda.aws_sqs_queue:
      region: us-east-1
      name: ansible-eda-queue
      delay_seconds: 0
```

**Integration:** Subscribe SNS topic to SQS queue, EDA polls queue for messages.

### 5. File Watcher Source

Monitor file changes for configuration drift or log events.

```yaml
sources:
  - ansible.eda.file:
      path: /var/log/application.log
      encoding: utf-8
```

**Use Case:** React to log entries, configuration changes, or file system events.

### 6. Range Source

Generate periodic events for scheduled automation.

```yaml
sources:
  - ansible.eda.range:
      limit: 10  # Number of events
      delay: 60  # Seconds between events
```

**Use Case:** Periodic health checks, scheduled maintenance tasks.

### 7. Azure Service Bus Source

Receive events from Azure Service Bus queues.

```yaml
sources:
  - ansible.eda.azure_service_bus:
      conn_str: "{{ lookup('env', 'AZURE_SERVICE_BUS_CONN_STR') }}"
      queue_name: ansible-events
```

### 8. URL Check Source

Monitor HTTP endpoints for availability or content changes.

```yaml
sources:
  - ansible.eda.url_check:
      urls:
        - http://app1.example.com/health
        - http://app2.example.com/health
      delay: 30  # Check interval in seconds
```

### 9. Generic Source

Create custom event sources using Python plugins.

```yaml
sources:
  - my_namespace.my_collection.custom_source:
      config_option: value
```

## Conditions

Conditions determine when a rule fires. They use Jinja2-like expressions.

### Simple Conditions

```yaml
# Equality check
condition: event.payload.status == "critical"

# Numeric comparison
condition: event.payload.cpu_usage > 90

# String matching
condition: event.payload.hostname.startswith("web-")

# Boolean check
condition: event.payload.is_production == true
```

### Complex Conditions

```yaml
# Multiple conditions (AND)
condition: |
  event.payload.severity == "critical" and
  event.payload.environment == "production" and
  event.payload.service in ["web", "api"]

# Multiple conditions (OR)
condition: |
  event.alert.labels.severity == "critical" or
  event.alert.labels.severity == "warning"

# Pattern matching
condition: event.payload.message is match("ERROR.*database.*")

# Nested field access
condition: event.payload.tags.environment == "prod"
```

### Condition Functions

```yaml
# String operations
condition: event.payload.hostname.lower() == "server01"
condition: event.payload.message.contains("error")
condition: event.payload.service.startswith("web")
condition: event.payload.id.endswith("prod")

# List operations
condition: "'critical' in event.payload.tags"
condition: "event.payload.service in ['web', 'api', 'db']"

# Regular expressions
condition: event.payload.message is match("ERROR: .* failed")
condition: event.payload.email is match(".*@example\\.com$")

# Type checks
condition: event.payload.value is number
condition: event.payload.data is defined
```

### Catch-All Condition

```yaml
# Match all events (useful for logging)
condition: true
```

## Actions

Actions define what happens when a condition matches.

### 1. Run Playbook

Execute an Ansible playbook.

```yaml
action:
  run_playbook:
    name: playbooks/remediate.yml
    extra_vars:
      target_host: "{{ event.payload.hostname }}"
      severity: "{{ event.payload.severity }}"
    verbosity: 1  # -v level (0-4)
```

**Best Practice:** Keep playbooks idempotent and test thoroughly.

### 2. Run Module

Execute a single Ansible module.

```yaml
action:
  run_module:
    name: ansible.builtin.service
    module_args:
      name: httpd
      state: restarted
```

### 3. Run Job Template

Execute AWX/Controller job template (requires EDA Controller).

```yaml
action:
  run_job_template:
    name: "Restart Web Service"
    organization: "Default"
    job_args:
      extra_vars:
        target_host: "{{ event.payload.hostname }}"
```

### 4. Set Fact

Store data for use in subsequent rules.

```yaml
action:
  set_fact:
    fact:
      last_alert_time: "{{ event.payload.timestamp }}"
      alert_count: "{{ alert_count | default(0) + 1 }}"
```

### 5. Post Event

Generate a new event for other rules to process.

```yaml
action:
  post_event:
    event:
      type: processed
      original_event: "{{ event }}"
      processed_at: "{{ ansible_date_time.iso8601 }}"
```

### 6. Debug

Print event data (useful for development).

```yaml
action:
  debug:
    msg: "Received event: {{ event }}"
```

**Use Case:** Development, troubleshooting, logging.

### 7. None (No Action)

Match condition but take no action (useful for filtering).

```yaml
action:
  none: {}
```

### Multiple Actions

Execute multiple actions in sequence.

```yaml
action:
  - debug:
      msg: "Processing critical alert"
  
  - set_fact:
      fact:
        alert_processed: true
  
  - run_playbook:
      name: remediate.yml
      extra_vars:
        hostname: "{{ event.payload.hostname }}"
```

## Complete Rulebook Examples

### Example 1: Web Server Monitoring

```yaml
---
- name: Web Server Health Monitoring
  hosts: web_servers
  
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
  
  rules:
    - name: Service down - restart
      condition: |
        event.payload.status == "down" and
        event.payload.service == "httpd"
      action:
        run_playbook:
          name: playbooks/restart_httpd.yml
          extra_vars:
            target: "{{ event.payload.hostname }}"
    
    - name: High response time - scale up
      condition: |
        event.payload.metric == "response_time" and
        event.payload.value > 2000
      action:
        run_playbook:
          name: playbooks/scale_web_tier.yml
          extra_vars:
            scale_up_count: 2
    
    - name: SSL certificate expiring
      condition: |
        event.payload.alert == "ssl_expiry" and
        event.payload.days_remaining < 30
      action:
        run_playbook:
          name: playbooks/renew_ssl_cert.yml
          extra_vars:
            domain: "{{ event.payload.domain }}"
```

### Example 2: Prometheus Alertmanager Integration

```yaml
---
- name: Prometheus Alert Response
  hosts: all
  
  sources:
    - ansible.eda.alertmanager:
        host: 0.0.0.0
        port: 8000
  
  rules:
    - name: High CPU usage
      condition: |
        event.alert.status == "firing" and
        event.alert.labels.alertname == "HighCPU"
      action:
        run_playbook:
          name: playbooks/investigate_cpu.yml
          extra_vars:
            instance: "{{ event.alert.labels.instance }}"
            value: "{{ event.alert.annotations.value }}"
    
    - name: Disk space critical
      condition: |
        event.alert.status == "firing" and
        event.alert.labels.alertname == "DiskSpaceCritical"
      action:
        run_playbook:
          name: playbooks/cleanup_disk.yml
          extra_vars:
            instance: "{{ event.alert.labels.instance }}"
            filesystem: "{{ event.alert.labels.mountpoint }}"
    
    - name: Alert resolved - notification
      condition: event.alert.status == "resolved"
      action:
        run_module:
          name: ansible.builtin.debug
          module_args:
            msg: "Alert {{ event.alert.labels.alertname }} resolved"
```

### Example 3: Security Event Response

```yaml
---
- name: Security Incident Response
  hosts: all
  
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
        token: "{{ lookup('env', 'SECURITY_WEBHOOK_TOKEN') }}"
  
  rules:
    - name: Failed login attempts - block IP
      condition: |
        event.payload.event_type == "auth_failure" and
        event.payload.attempt_count > 5
      action:
        run_playbook:
          name: playbooks/security/block_ip.yml
          extra_vars:
            source_ip: "{{ event.payload.source_ip }}"
            duration: 3600
    
    - name: Malware detected - isolate host
      condition: |
        event.payload.event_type == "malware_detected" and
        event.payload.severity == "critical"
      action:
        - run_playbook:
            name: playbooks/security/isolate_host.yml
            extra_vars:
              target_host: "{{ event.payload.hostname }}"
        
        - run_module:
            name: ansible.builtin.uri
            module_args:
              url: "https://siem.example.com/api/incident"
              method: POST
              body_format: json
              body:
                type: "malware_isolation"
                host: "{{ event.payload.hostname }}"
    
    - name: Privilege escalation - alert
      condition: event.payload.event_type == "privilege_escalation"
      action:
        run_playbook:
          name: playbooks/security/alert_security_team.yml
          extra_vars:
            user: "{{ event.payload.user }}"
            command: "{{ event.payload.command }}"
```

### Example 4: CI/CD Pipeline Integration

```yaml
---
- name: CI/CD Deployment Automation
  hosts: localhost
  
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
        hmac_secret: "{{ lookup('env', 'GITHUB_WEBHOOK_SECRET') }}"
        hmac_header: X-Hub-Signature-256
        hmac_algo: sha256
  
  rules:
    - name: Deploy on main branch push
      condition: |
        event.payload.ref == "refs/heads/main" and
        event.payload.repository.name == "my-app"
      action:
        run_playbook:
          name: playbooks/deploy_production.yml
          extra_vars:
            git_commit: "{{ event.payload.after }}"
            deployer: "{{ event.payload.pusher.name }}"
    
    - name: Run tests on pull request
      condition: |
        event.payload.action == "opened" or
        event.payload.action == "synchronize"
      action:
        run_playbook:
          name: playbooks/run_tests.yml
          extra_vars:
            pr_number: "{{ event.payload.number }}"
            branch: "{{ event.payload.pull_request.head.ref }}"
    
    - name: Rollback on deployment failure
      condition: |
        event.payload.state == "failure" and
        event.payload.context == "production-deploy"
      action:
        run_playbook:
          name: playbooks/rollback_deployment.yml
          extra_vars:
            failed_commit: "{{ event.payload.commit.sha }}"
```

### Example 5: Kafka Event Stream Processing

```yaml
---
- name: Application Event Processing
  hosts: all
  
  sources:
    - ansible.eda.kafka:
        host: kafka.example.com
        port: 9092
        topic: application-events
        group_id: ansible-eda
  
  rules:
    - name: User signup - provision resources
      condition: event.event_type == "user.signup"
      action:
        run_playbook:
          name: playbooks/provision_user_resources.yml
          extra_vars:
            user_id: "{{ event.user_id }}"
            tier: "{{ event.subscription_tier }}"
    
    - name: Payment failed - suspend account
      condition: |
        event.event_type == "payment.failed" and
        event.retry_count > 3
      action:
        run_playbook:
          name: playbooks/suspend_account.yml
          extra_vars:
            user_id: "{{ event.user_id }}"
            reason: "payment_failure"
    
    - name: High error rate - alert
      condition: |
        event.event_type == "error.rate" and
        event.value > 100
      action:
        run_playbook:
          name: playbooks/alert_oncall.yml
          extra_vars:
            service: "{{ event.service }}"
            error_rate: "{{ event.value }}"
```

## Testing and Debugging

### Running Rulebooks

```bash
# Basic execution
ansible-rulebook --rulebook rulebook.yml --inventory inventory.yml

# With verbosity
ansible-rulebook --rulebook rulebook.yml -i inventory.yml -v
ansible-rulebook --rulebook rulebook.yml -i inventory.yml -vv

# With extra vars
ansible-rulebook --rulebook rulebook.yml -i inventory.yml \
  --vars '{"environment": "production"}'

# Print events only (no actions)
ansible-rulebook --rulebook rulebook.yml -i inventory.yml --print-events

# Specific source collection
ansible-rulebook --rulebook rulebook.yml -i inventory.yml \
  --source-dir ./my_event_sources
```

### Testing with Webhooks

```bash
# Send test webhook
curl -X POST http://localhost:5000/endpoint \
  -H "Content-Type: application/json" \
  -d '{
    "severity": "critical",
    "service": "test-service",
    "hostname": "test-host"
  }'

# Test with authentication
curl -X POST http://localhost:5000/endpoint \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer secret_token" \
  -d '{"test": "data"}'

# Test HMAC signature
echo -n '{"test":"data"}' | \
  openssl dgst -sha256 -hmac "secret_key" | \
  awk '{print $2}'
```

### Debugging Rulebooks

```yaml
# Add debug rule to see all events
rules:
  - name: Debug all events
    condition: true
    action:
      debug:
        msg: |
          Event received:
          {{ event | to_nice_yaml }}
```

### Validating Rulebook Syntax

```bash
# Syntax check (if available)
ansible-rulebook --check --rulebook rulebook.yml

# YAML validation
yamllint rulebook.yml

# Manual validation
python -c "import yaml; yaml.safe_load(open('rulebook.yml'))"
```

## EDA Controller Integration

### Running Rulebooks in EDA Controller

**Decision Environment:**
Container image with ansible-rulebook and dependencies.

```yaml
# execution-environment.yml
version: 3
images:
  base_image:
    name: quay.io/ansible/ansible-runner:latest

dependencies:
  galaxy:
    collections:
      - ansible.eda
      - community.general
  
  python:
    - ansible-rulebook
    - aiokafka  # For Kafka source
  
  system:
    - git
```

**Rulebook Activation:**
EDA Controller concept for deploying and managing rulebooks.

```yaml
# Project structure
my-eda-project/
├── rulebooks/
│   ├── monitoring.yml
│   ├── security.yml
│   └── cicd.yml
├── playbooks/
│   └── remediation/
└── inventory/
```

### Job Template Actions

```yaml
rules:
  - name: Execute Controller job template
    condition: event.payload.severity == "critical"
    action:
      run_job_template:
        name: "Emergency Remediation"
        organization: "IT Operations"
        job_args:
          extra_vars:
            target: "{{ event.payload.hostname }}"
            incident_id: "{{ event.payload.id }}"
```

## Best Practices

### 1. Rulebook Organization

```yaml
# Good - specific, descriptive names
- name: Production Database High CPU Response
  hosts: prod_databases
  sources: [...]
  rules: [...]

# Bad - generic, unclear
- name: Database Stuff
  hosts: all
  sources: [...]
  rules: [...]
```

### 2. Condition Clarity

```yaml
# Good - clear, readable conditions
condition: |
  event.payload.environment == "production" and
  event.payload.severity in ["critical", "high"] and
  event.payload.service == "database"

# Bad - complex, hard to read
condition: event.payload.environment == "production" and (event.payload.severity == "critical" or event.payload.severity == "high") and event.payload.service == "database"
```

### 3. Event Source Security

```yaml
# Good - use authentication
sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
      token: "{{ lookup('env', 'WEBHOOK_TOKEN') }}"
      hmac_secret: "{{ lookup('env', 'HMAC_SECRET') }}"

# Bad - no authentication
sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
```

### 4. Playbook Idempotency

Ensure all playbooks called from rules are idempotent:

```yaml
# remediate.yml - idempotent playbook
---
- name: Remediate web service
  hosts: "{{ target_host }}"
  tasks:
    - name: Check service status
      ansible.builtin.service_facts:
    
    - name: Restart service only if not running
      ansible.builtin.service:
        name: httpd
        state: restarted
      when: ansible_facts.services['httpd.service'].state != 'running'
```

### 5. Error Handling

```yaml
# Add error handling in playbooks
- name: Error handling example
  hosts: all
  tasks:
    - name: Attempt remediation
      block:
        - name: Restart service
          ansible.builtin.service:
            name: httpd
            state: restarted
      
      rescue:
        - name: Alert on failure
          ansible.builtin.uri:
            url: https://alert.example.com/api
            method: POST
            body_format: json
            body:
              message: "Remediation failed for {{ inventory_hostname }}"
```

### 6. Logging and Auditing

```yaml
# Always include logging rule
rules:
  - name: Log all events
    condition: true
    action:
      - debug:
          msg: "Event: {{ event }}"
      
      - run_module:
          name: ansible.builtin.lineinfile
          module_args:
            path: /var/log/eda-events.log
            line: "{{ ansible_date_time.iso8601 }} - {{ event | to_json }}"
            create: yes
```

### 7. Testing Before Production

```bash
# Test in development first
ansible-rulebook --rulebook rulebook.yml -i dev-inventory.yml

# Use print-events to verify conditions
ansible-rulebook --rulebook rulebook.yml --print-events

# Test with sample events
curl -X POST http://localhost:5000/endpoint \
  -d @test-event.json
```

## Troubleshooting

### Issue 1: Rulebook Not Starting

**Problem:**
```
Error: Failed to load rulebook
```

**Solutions:**
```bash
# Check YAML syntax
yamllint rulebook.yml

# Validate with Python
python -c "import yaml; yaml.safe_load(open('rulebook.yml'))"

# Check event source plugin availability
ansible-galaxy collection list | grep ansible.eda
```

### Issue 2: Events Not Triggering Rules

**Problem:** Webhook received but no action executed

**Debug:**
```yaml
# Add debug rule at the top
rules:
  - name: Debug all events
    condition: true
    action:
      debug:
        msg: "Event structure: {{ event | to_nice_yaml }}"
```

**Check condition syntax:**
```yaml
# Verify event structure matches condition
# Common mistake: event.payload.field vs event.field
```

### Issue 3: Playbook Execution Fails

**Problem:**
```
Error executing playbook: File not found
```

**Solutions:**
```yaml
# Use absolute paths
action:
  run_playbook:
    name: /path/to/playbooks/remediate.yml

# Or ensure working directory is correct
ansible-rulebook --rulebook rulebook.yml \
  --project-dir /path/to/project
```

### Issue 4: Event Source Connection Failed

**Kafka Example:**
```bash
# Test Kafka connectivity
kafka-console-consumer --bootstrap-server kafka:9092 \
  --topic infrastructure-events \
  --from-beginning

# Check DNS resolution
nslookup kafka.example.com

# Verify port accessibility
telnet kafka.example.com 9092
```

## Quick Reference

### Common Event Source Patterns

```yaml
# Webhook
- ansible.eda.webhook:
    host: 0.0.0.0
    port: 5000

# Alertmanager
- ansible.eda.alertmanager:
    host: 0.0.0.0
    port: 8000

# Kafka
- ansible.eda.kafka:
    host: kafka.example.com
    port: 9092
    topic: events

# File watcher
- ansible.eda.file:
    path: /var/log/app.log

# URL check
- ansible.eda.url_check:
    urls:
      - http://app.example.com/health
    delay: 30
```

### Common Condition Patterns

```yaml
# Exact match
condition: event.payload.status == "critical"

# Numeric comparison
condition: event.payload.value > 80

# String contains
condition: "'error' in event.payload.message.lower()"

# List membership
condition: event.payload.service in ["web", "api"]

# Regex match
condition: event.payload.email is match(".*@example\\.com$")

# Multiple conditions
condition: |
  event.payload.severity == "high" and
  event.payload.environment == "production"
```

### Common Action Patterns

```yaml
# Run playbook
action:
  run_playbook:
    name: playbooks/fix.yml
    extra_vars:
      target: "{{ event.payload.hostname }}"

# Run module
action:
  run_module:
    name: ansible.builtin.service
    module_args:
      name: httpd
      state: restarted

# Multiple actions
action:
  - debug:
      msg: "Processing event"
  - run_playbook:
      name: remediate.yml
```

## Output Template

When creating EDA rulebooks, provide:

1. **Complete rulebook** with appropriate event sources
2. **Explanation** of how the rulebook works
3. **Testing instructions** for validating the rulebook
4. **Event source configuration** if external system setup needed
5. **Playbook stubs** referenced by actions (if applicable)

Explain:
- Which event sources to use and why
- How conditions match events
- What actions will be triggered
- How to test the rulebook
- Security considerations (authentication, secrets)
- Integration with existing infrastructure

When asked to create an EDA rulebook, analyze requirements, recommend appropriate event sources, generate the rulebook with proper conditions and actions, and provide comprehensive testing and deployment guidance.
