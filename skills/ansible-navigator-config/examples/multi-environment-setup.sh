#!/bin/bash
# Multi-Environment ansible-navigator Setup Example
# Demonstrates using different configurations for dev, staging, and production

# Development environment
echo "Running in DEVELOPMENT..."
ENV=dev ansible-navigator run playbook.yml \
  --mode interactive \
  --execution-environment-image quay.io/ansible/creator-ee:latest

# Staging environment (stdout mode for CI)
echo "Running in STAGING..."
ENV=staging NAVIGATOR_MODE=stdout ansible-navigator run playbook.yml \
  --execution-environment-image myorg/staging-ee:latest \
  -i inventory/staging

# Production environment (strict settings)
echo "Running in PRODUCTION..."
ENV=production ENV_TAG=1.0.0 NAVIGATOR_MODE=stdout \
  ansible-navigator run playbook.yml \
  --execution-environment-image myorg/production-ee:1.0.0 \
  --pull-policy always \
  -i inventory/production \
  --check  # Dry run first in production

# Replay production artifact for analysis
echo "Replaying production artifact..."
ansible-navigator replay artifacts/playbook-*-production.json
