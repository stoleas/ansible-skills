# Beginner Walkthrough: Your First Ansible Project

Complete example of interactive development from scratch to working deployment.

## Scenario

You need to automate the deployment of a web application to three Ubuntu servers:
- 1 development server
- 2 production servers

## Phase 1: Environment Check

**Current state:** Fresh Ubuntu workstation with nothing installed

**Step 1:** Install Ansible
```bash
sudo apt update
sudo apt install -y ansible

# Verify
ansible --version
# Expected: ansible [core 2.15+]
```

**Step 2:** Generate SSH key (if you don't have one)
```bash
ssh-keygen -t ed25519 -C "ansible-automation"
# Press Enter to accept defaults
```

**Step 3:** Copy SSH key to target servers
```bash
ssh-copy-id user@dev-server
ssh-copy-id user@prod-server-01
ssh-copy-id user@prod-server-02

# Test SSH access
ssh user@dev-server "echo 'Connected successfully'"
```

✅ **Validation:** Can SSH to all servers without password

---

## Phase 2: Project Setup

**Step 1:** Create project structure
```bash
mkdir webapp-deployment
cd webapp-deployment

mkdir -p {inventory,group_vars,host_vars,roles,playbooks,files,templates}

git init
```

**Step 2:** Create ansible.cfg
```ini
# ansible.cfg
[defaults]
inventory = inventory/hosts.yml
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml

[privilege_escalation]
become = True
become_method = sudo
become_user = root
```

**Step 3:** Create inventory
```yaml
# inventory/hosts.yml
---
all:
  children:
    development:
      hosts:
        dev-server:
          ansible_host: 192.168.1.10
          ansible_user: ubuntu
    
    production:
      hosts:
        prod-server-01:
          ansible_host: 192.168.1.20
          ansible_user: ubuntu
        
        prod-server-02:
          ansible_host: 192.168.1.21
          ansible_user: ubuntu
```

**Step 4:** Verify structure
```bash
tree -L 2
```

✅ **Validation:** Directory structure matches standard layout

---

## Phase 3: Connectivity Test

**Step 1:** Test ping
```bash
ansible all -m ping
```

**Expected output:**
```yaml
dev-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
prod-server-01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
prod-server-02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**Step 2:** Gather OS information
```bash
ansible all -m setup -a "filter=ansible_distribution*"
```

**Step 3:** Test sudo
```bash
ansible all -m shell -a "whoami" --become
```

**Expected:** All hosts return "root"

✅ **Validation:** All 3 hosts respond successfully

---

## Phase 4: First Playbook

**Step 1:** Create test playbook
```yaml
# playbooks/hello_ansible.yml
---
- name: Hello Ansible
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Display welcome message
      ansible.builtin.debug:
        msg: |
          Hello from {{ ansible_hostname }}!
          Running {{ ansible_distribution }} {{ ansible_distribution_version }}
    
    - name: Create test file
      ansible.builtin.file:
        path: /tmp/ansible-was-here
        state: touch
        mode: '0644'
      become: yes
    
    - name: Verify file created
      ansible.builtin.stat:
        path: /tmp/ansible-was-here
      register: test_file
    
    - name: Show result
      ansible.builtin.debug:
        msg: "Test file exists: {{ test_file.stat.exists }}"
```

**Step 2:** Validate syntax
```bash
ansible-playbook playbooks/hello_ansible.yml --syntax-check
```

**Step 3:** Run in check mode
```bash
ansible-playbook playbooks/hello_ansible.yml --check
```

**Step 4:** Execute
```bash
ansible-playbook playbooks/hello_ansible.yml
```

✅ **Validation:** Playbook runs successfully, test file created

---

## Phase 5: Real Application Deployment

**Step 1:** Define application requirements
```yaml
# group_vars/all.yml
---
app_name: mywebapp
app_port: 8080
app_user: webapp
app_directory: /opt/{{ app_name }}

required_packages:
  - nginx
  - python3
  - python3-pip
  - git
```

**Step 2:** Create deployment playbook
```yaml
# playbooks/deploy_webapp.yml
---
- name: Deploy web application
  hosts: all
  become: yes
  
  tasks:
    - name: Install required packages
      ansible.builtin.apt:
        name: "{{ required_packages }}"
        state: present
        update_cache: yes
    
    - name: Create application user
      ansible.builtin.user:
        name: "{{ app_user }}"
        system: yes
        create_home: no
        shell: /bin/false
    
    - name: Create application directory
      ansible.builtin.file:
        path: "{{ app_directory }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'
    
    - name: Deploy application files
      ansible.builtin.copy:
        src: ../files/app/
        dest: "{{ app_directory }}/"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
      notify: Restart application
  
  handlers:
    - name: Restart application
      ansible.builtin.systemd:
        name: "{{ app_name }}"
        state: restarted
```

**Step 3:** Test on development first
```bash
ansible-playbook playbooks/deploy_webapp.yml --limit development --check
ansible-playbook playbooks/deploy_webapp.yml --limit development
```

**Step 4:** Deploy to production
```bash
ansible-playbook playbooks/deploy_webapp.yml --limit production
```

✅ **Validation:** Application deployed to all servers

---

## Phase 6: Convert to Role

**Step 1:** Create role structure
```bash
ansible-galaxy role init roles/webapp_deploy
```

**Step 2:** Move tasks to role
```yaml
# roles/webapp_deploy/tasks/main.yml
---
- name: Include OS-specific variables
  ansible.builtin.include_vars: "{{ ansible_distribution }}.yml"

- name: Install packages
  ansible.builtin.package:
    name: "{{ webapp_deploy_packages }}"
    state: present

- name: Create app user
  ansible.builtin.user:
    name: "{{ webapp_deploy_user }}"
    system: yes

- name: Setup application
  ansible.builtin.import_tasks: setup_app.yml

- name: Configure Nginx
  ansible.builtin.import_tasks: configure_nginx.yml
```

**Step 3:** Define role variables
```yaml
# roles/webapp_deploy/defaults/main.yml
---
webapp_deploy_app_name: mywebapp
webapp_deploy_app_port: 8080
webapp_deploy_user: webapp
webapp_deploy_directory: /opt/{{ webapp_deploy_app_name }}
```

**Step 4:** Create simplified playbook
```yaml
# playbooks/site.yml
---
- name: Deploy web application
  hosts: all
  become: yes
  
  roles:
    - role: webapp_deploy
      tags: ['webapp', 'deploy']
```

**Step 5:** Test role
```bash
ansible-playbook playbooks/site.yml --limit development
```

✅ **Validation:** Role-based deployment works

---

## Phase 7: Add Testing

**Step 1:** Install ansible-lint
```bash
pip install ansible-lint
```

**Step 2:** Lint playbooks
```bash
ansible-lint playbooks/site.yml
ansible-lint roles/webapp_deploy/
```

**Step 3:** Fix any issues reported

**Step 4:** Test idempotency
```bash
# Run twice - second run should show no changes
ansible-playbook playbooks/site.yml --limit development
ansible-playbook playbooks/site.yml --limit development
```

✅ **Validation:** No lint errors, idempotent execution

---

## Phase 8: Production Deployment

**Step 1:** Create pre-deployment checklist
- [x] All lint checks pass
- [x] Tested on development
- [x] Idempotency verified
- [x] Rollback plan ready
- [ ] Backup taken

**Step 2:** Take backups
```bash
ansible production -m shell -a "tar -czf /tmp/backup-$(date +%Y%m%d).tar.gz /opt/mywebapp" --become
```

**Step 3:** Deploy to production
```bash
# Check mode first
ansible-playbook playbooks/site.yml --limit production --check --diff

# Deploy
ansible-playbook playbooks/site.yml --limit production
```

**Step 4:** Verify deployment
```bash
ansible production -m uri -a "url=http://localhost:8080 return_content=yes"
```

✅ **Validation:** Production deployment successful

---

## Summary

You've successfully:
1. ✅ Set up development environment
2. ✅ Created Ansible project structure
3. ✅ Verified connectivity to all hosts
4. ✅ Created and tested first playbook
5. ✅ Deployed real application
6. ✅ Converted playbook to reusable role
7. ✅ Added testing and validation
8. ✅ Deployed to production

## Next Steps

- Set up CI/CD pipeline for automated testing
- Add Molecule tests for role validation
- Create additional roles for database, monitoring
- Implement secrets management with Ansible Vault
- Set up dynamic inventory for cloud environments
