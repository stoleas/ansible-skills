# Event Source Reference

Comprehensive reference for all Ansible EDA event source plugins.

## Built-in Event Sources

### ansible.eda.webhook

Listen for HTTP POST requests (webhooks).

**Configuration:**
```yaml
sources:
  - ansible.eda.webhook:
      host: 0.0.0.0              # Bind address
      port: 5000                  # Listen port
      token: "secret"             # Optional: Bearer token auth
      hmac_secret: "key"          # Optional: HMAC validation
      hmac_algo: sha256           # HMAC algorithm
      hmac_header: X-Signature    # Header containing HMAC
      hmac_format: hex            # hex or base64
```

**Event Structure:**
```yaml
event:
  payload: {...}         # Request body (JSON)
  meta:
    endpoint: "/path"    # Request path
    headers: {...}       # Request headers
```

**Use Cases:** Monitoring tools, CI/CD webhooks, custom integrations

---

### ansible.eda.alertmanager

Receive Prometheus Alertmanager webhooks.

**Configuration:**
```yaml
sources:
  - ansible.eda.alertmanager:
      host: 0.0.0.0
      port: 8000
      data_alerts_path: alerts    # Path to alerts in payload
```

**Event Structure:**
```yaml
event:
  alert:
    status: firing              # firing or resolved
    labels:
      alertname: HighCPU
      severity: critical
      instance: server01
    annotations:
      summary: "..."
      description: "..."
      value: "95%"
```

**Alertmanager Config:**
```yaml
receivers:
  - name: ansible-eda
    webhook_configs:
      - url: http://eda-server:8000/endpoint
        send_resolved: true
```

---

### ansible.eda.kafka

Consume events from Apache Kafka topics.

**Configuration:**
```yaml
sources:
  - ansible.eda.kafka:
      host: kafka.example.com
      port: 9092
      topic: events               # Topic to consume
      group_id: eda-consumer      # Consumer group
      offset: latest              # latest or earliest
      encoding: utf-8
```

**Event Structure:** Whatever is in the Kafka message (typically JSON)

**Requirements:** Java runtime, `aiokafka` Python package

**Use Cases:** Stream processing, real-time events, application events

---

### ansible.eda.aws_sqs_queue

Poll AWS SQS queue for messages.

**Configuration:**
```yaml
sources:
  - ansible.eda.aws_sqs_queue:
      region: us-east-1
      name: ansible-eda-queue
      delay_seconds: 0
```

**Requirements:** AWS credentials configured (env vars, ~/.aws/credentials, IAM role)

**Event Structure:** SQS message body (typically JSON from SNS)

**Use Cases:** AWS CloudWatch alarms, SNS notifications, AWS events

---

### ansible.eda.azure_service_bus

Receive messages from Azure Service Bus.

**Configuration:**
```yaml
sources:
  - ansible.eda.azure_service_bus:
      conn_str: "Endpoint=sb://..."
      queue_name: ansible-events
```

**Requirements:** Azure Service Bus connection string

**Event Structure:** Service Bus message body

**Use Cases:** Azure Monitor alerts, Azure events, application events

---

### ansible.eda.file

Watch file for changes (tail -f style).

**Configuration:**
```yaml
sources:
  - ansible.eda.file:
      path: /var/log/app.log
      encoding: utf-8
```

**Event Structure:**
```yaml
event:
  file: /var/log/app.log
  line: "2026-04-25 ERROR: Connection failed"
```

**Use Cases:** Log monitoring, configuration file changes

---

### ansible.eda.range

Generate periodic events (for testing or scheduled tasks).

**Configuration:**
```yaml
sources:
  - ansible.eda.range:
      limit: 100          # Number of events (omit for infinite)
      delay: 60           # Seconds between events
```

**Event Structure:**
```yaml
event:
  i: 0      # Event counter (0, 1, 2, ...)
```

**Use Cases:** Testing rulebooks, periodic health checks

---

### ansible.eda.url_check

Poll HTTP endpoints for availability or changes.

**Configuration:**
```yaml
sources:
  - ansible.eda.url_check:
      urls:
        - http://app1.example.com/health
        - http://app2.example.com/health
      delay: 30           # Check interval in seconds
```

**Event Structure:**
```yaml
event:
  url: http://app1.example.com/health
  status: 200
  body: {...}           # Response body
  error: null           # Or error message if failed
```

**Use Cases:** Endpoint monitoring, health checks

---

## Event Source Comparison

| Source | Use Case | Push/Pull | External Dependency |
|--------|----------|-----------|---------------------|
| webhook | General webhooks | Push | None |
| alertmanager | Prometheus alerts | Push | Alertmanager |
| kafka | Event streaming | Pull | Kafka cluster |
| aws_sqs_queue | AWS events | Pull | AWS SQS |
| azure_service_bus | Azure events | Pull | Azure Service Bus |
| file | Log monitoring | Pull | None |
| range | Testing/periodic | Generate | None |
| url_check | Endpoint monitoring | Pull | None |

## Authentication Patterns

### Token Authentication (webhook)

```yaml
sources:
  - ansible.eda.webhook:
      token: "{{ lookup('env', 'WEBHOOK_TOKEN') }}"
```

**Client Request:**
```bash
curl -H "Authorization: Bearer secret_token" \
  http://localhost:5000/endpoint
```

### HMAC Signature Validation (webhook)

```yaml
sources:
  - ansible.eda.webhook:
      hmac_secret: "{{ lookup('env', 'HMAC_SECRET') }}"
      hmac_algo: sha256
      hmac_header: X-Hub-Signature-256
      hmac_format: hex
```

**Client (Python):**
```python
import hmac
import hashlib
import requests

payload = '{"event": "data"}'
secret = "hmac_secret"
signature = hmac.new(
    secret.encode(),
    payload.encode(),
    hashlib.sha256
).hexdigest()

requests.post(
    "http://localhost:5000/endpoint",
    data=payload,
    headers={"X-Hub-Signature-256": f"sha256={signature}"}
)
```

## Custom Event Sources

Create custom event source plugins in collections:

**Directory structure:**
```
my_namespace/my_collection/
└── extensions/
    └── eda/
        └── plugins/
            └── event_source/
                └── my_source.py
```

**Basic plugin template:**
```python
"""
my_source.py - Custom EDA event source
"""

async def main(queue, args):
    """
    Event source main function
    
    Args:
        queue: asyncio.Queue to put events
        args: dict of source configuration
    """
    while True:
        # Generate or fetch event
        event = {"example": "data"}
        
        # Put event in queue
        await queue.put(event)
        
        # Delay before next event
        await asyncio.sleep(args.get("delay", 60))
```

**Usage:**
```yaml
sources:
  - my_namespace.my_collection.my_source:
      delay: 30
      custom_option: value
```
