# Shell Command to Ansible Module Mapping

Quick reference for translating common shell commands to Ansible modules.

## Package Management

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `yum install PKG` | `ansible.builtin.yum` | `yum: name=httpd state=present` |
| `yum remove PKG` | `ansible.builtin.yum` | `yum: name=httpd state=absent` |
| `yum update` | `ansible.builtin.yum` | `yum: name=* state=latest` |
| `apt-get install PKG` | `ansible.builtin.apt` | `apt: name=apache2 state=present` |
| `apt-get remove PKG` | `ansible.builtin.apt` | `apt: name=apache2 state=absent` |
| `apt-get update` | `ansible.builtin.apt` | `apt: update_cache=yes` |
| Generic package manager | `ansible.builtin.package` | `package: name=httpd state=present` |
| `rpm -qa \| grep PKG` | `ansible.builtin.package_facts` | Use package_facts then filter ansible_facts.packages |
| `pip install PKG` | `ansible.builtin.pip` | `pip: name=requests state=present` |

## Service Management

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `systemctl start SVC` | `ansible.builtin.service` | `service: name=httpd state=started` |
| `systemctl stop SVC` | `ansible.builtin.service` | `service: name=httpd state=stopped` |
| `systemctl restart SVC` | `ansible.builtin.service` | `service: name=httpd state=restarted` |
| `systemctl reload SVC` | `ansible.builtin.service` | `service: name=httpd state=reloaded` |
| `systemctl enable SVC` | `ansible.builtin.service` | `service: name=httpd enabled=yes` |
| `systemctl disable SVC` | `ansible.builtin.service` | `service: name=httpd enabled=no` |
| `systemctl daemon-reload` | `ansible.builtin.systemd` | `systemd: daemon_reload=yes` |

## File Operations

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `cp SRC DEST` | `ansible.builtin.copy` | `copy: src=file dest=/dest` |
| `mv SRC DEST` | `ansible.builtin.command` or `copy` + `file` | See note below |
| `rm FILE` | `ansible.builtin.file` | `file: path=/file state=absent` |
| `rm -rf DIR` | `ansible.builtin.file` | `file: path=/dir state=absent` |
| `mkdir DIR` | `ansible.builtin.file` | `file: path=/dir state=directory` |
| `mkdir -p DIR` | `ansible.builtin.file` | `file: path=/dir state=directory` (default) |
| `touch FILE` | `ansible.builtin.file` | `file: path=/file state=touch` |
| `ln -s TARGET LINK` | `ansible.builtin.file` | `file: src=/target dest=/link state=link` |
| `chmod MODE FILE` | `ansible.builtin.file` | `file: path=/file mode='0644'` |
| `chown USER:GROUP FILE` | `ansible.builtin.file` | `file: path=/file owner=user group=group` |
| `echo "TEXT" > FILE` | `ansible.builtin.copy` | `copy: content="TEXT" dest=/file` |
| `cat > FILE <<EOF` | `ansible.builtin.copy` | `copy: content=\|...` (multiline) |

## Text Processing

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `sed -i 's/OLD/NEW/' FILE` | `ansible.builtin.lineinfile` or `replace` | See examples below |
| `grep -q PATTERN FILE` | `ansible.builtin.lineinfile` | `lineinfile: path=/file regexp=PATTERN state=present` |
| `echo "LINE" >> FILE` | `ansible.builtin.lineinfile` | `lineinfile: path=/file line="LINE"` |
| `sed -i '/PATTERN/d' FILE` | `ansible.builtin.lineinfile` | `lineinfile: path=/file regexp=PATTERN state=absent` |

### sed Examples

```bash
# Shell: Replace first occurrence
sed -i 's/old/new/' file

# Ansible: Replace all matching lines
- ansible.builtin.lineinfile:
    path: file
    regexp: '^.*old.*$'
    line: 'new'

# Shell: Replace all occurrences
sed -i 's/old/new/g' file

# Ansible: Replace within file (use replace module)
- ansible.builtin.replace:
    path: file
    regexp: 'old'
    replace: 'new'
```

## User and Group Management

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `useradd USER` | `ansible.builtin.user` | `user: name=alice state=present` |
| `useradd -r USER` | `ansible.builtin.user` | `user: name=alice system=yes` |
| `useradd -s SHELL USER` | `ansible.builtin.user` | `user: name=alice shell=/bin/bash` |
| `userdel USER` | `ansible.builtin.user` | `user: name=alice state=absent` |
| `usermod -aG GROUP USER` | `ansible.builtin.user` | `user: name=alice groups=wheel append=yes` |
| `groupadd GROUP` | `ansible.builtin.group` | `group: name=admins state=present` |
| `groupdel GROUP` | `ansible.builtin.group` | `group: name=admins state=absent` |
| `passwd USER` | `ansible.builtin.user` | `user: name=alice password={{ hash }}` |

## Downloads and Archives

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `wget URL -O FILE` | `ansible.builtin.get_url` | `get_url: url=URL dest=/file` |
| `curl -o FILE URL` | `ansible.builtin.get_url` | `get_url: url=URL dest=/file` |
| `tar -xzf FILE -C DIR` | `ansible.builtin.unarchive` | `unarchive: src=file dest=/dir` |
| `unzip FILE -d DIR` | `ansible.builtin.unarchive` | `unarchive: src=file dest=/dir` |
| `tar -czf ARCHIVE DIR` | `ansible.builtin.archive` | `archive: path=/dir dest=archive.tar.gz` |

## Git Operations

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `git clone REPO DIR` | `ansible.builtin.git` | `git: repo=URL dest=/dir` |
| `git pull` | `ansible.builtin.git` | `git: repo=URL dest=/dir update=yes` |
| `git checkout BRANCH` | `ansible.builtin.git` | `git: repo=URL dest=/dir version=BRANCH` |

## Firewall Management

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `firewall-cmd --add-service=SVC` | `ansible.posix.firewalld` | `firewalld: service=http state=enabled` |
| `firewall-cmd --add-port=PORT` | `ansible.posix.firewalld` | `firewalld: port=8080/tcp state=enabled` |
| `firewall-cmd --reload` | `ansible.posix.firewalld` | `firewalld: state=enabled immediate=yes` |
| `ufw allow PORT` | `community.general.ufw` | `ufw: rule=allow port=22` |
| `iptables -A ...` | `ansible.builtin.iptables` | Complex - see iptables module docs |

## Cron Jobs

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `crontab -e` | `ansible.builtin.cron` | `cron: name=backup minute=0 hour=2 job=/backup.sh` |
| Add cron job | `ansible.builtin.cron` | `cron: name=job minute=*/5 job=/script.sh` |
| Remove cron job | `ansible.builtin.cron` | `cron: name=job state=absent` |

## Database Operations

| Shell Command | Ansible Module | Example |
|--------------|----------------|---------|
| `psql -c "CREATE DATABASE"` | `community.postgresql.postgresql_db` | `postgresql_db: name=mydb state=present` |
| `psql -c "CREATE USER"` | `community.postgresql.postgresql_user` | `postgresql_user: name=user password=pass` |
| `mysql -e "CREATE DATABASE"` | `community.mysql.mysql_db` | `mysql_db: name=mydb state=present` |
| `mysql -e "CREATE USER"` | `community.mysql.mysql_user` | `mysql_user: name=user password=pass` |

## System Information

| Shell Command | Ansible Module/Facts | Example |
|--------------|---------------------|---------|
| `hostname` | `ansible_hostname` | `{{ ansible_hostname }}` fact |
| `uname -r` | `ansible_kernel` | `{{ ansible_kernel }}` fact |
| `cat /etc/os-release` | `ansible_distribution` | `{{ ansible_distribution }}` fact |
| `ip addr` | `ansible_all_ipv4_addresses` | `{{ ansible_all_ipv4_addresses }}` fact |
| `df -h` | `ansible_mounts` | `{{ ansible_mounts }}` fact |
| `free -m` | `ansible_memory_mb` | `{{ ansible_memory_mb }}` fact |

## Conditionals and Loops

| Shell Pattern | Ansible Equivalent | Example |
|--------------|-------------------|---------|
| `if [ -f FILE ]; then` | `when: stat.exists` | Use `stat` module + `when` |
| `if [ "$VAR" = "value" ]; then` | `when: var == "value"` | Direct `when` condition |
| `for i in LIST; do` | `loop:` | `loop: ['item1', 'item2']` |
| `while read line; do` | `with_lines:` | `with_lines: cat /file` |

## Special Cases

### Move File (mv)
```yaml
# Shell: mv /source /dest
# Ansible: Use copy + remove
- name: Copy file
  ansible.builtin.copy:
    src: /source
    dest: /dest
    remote_src: true

- name: Remove source
  ansible.builtin.file:
    path: /source
    state: absent
```

### Check if Service is Running
```bash
# Shell
systemctl is-active httpd

# Ansible
- name: Get service facts
  ansible.builtin.service_facts:

- name: Check if Apache is running
  ansible.builtin.debug:
    msg: "Apache is {{ ansible_facts.services['httpd.service'].state }}"
```

### Environment Variables
```bash
# Shell
export VAR=value
command

# Ansible
- name: Run command with environment
  ansible.builtin.command: /command
  environment:
    VAR: value
```

## Tips for Choosing Modules

1. **Prefer specific modules over `command`/`shell`:**
   - `package` instead of `yum install`
   - `service` instead of `systemctl start`
   - `copy` instead of `cat > file`

2. **Use declarative modules when possible:**
   - They're naturally idempotent
   - Better error handling
   - Cross-platform support

3. **Use `command` only when no module exists:**
   - Add `creates` or `removes` for idempotency
   - Use `changed_when` for proper change detection

4. **Check Ansible Galaxy for collection modules:**
   - `ansible.posix.*` for POSIX utilities
   - `community.general.*` for many tools
   - `community.mysql.*`, `community.postgresql.*` for databases

## Quick Module Lookup

```bash
# Find modules
ansible-doc -l | grep package

# Get module documentation
ansible-doc ansible.builtin.package

# Get examples
ansible-doc ansible.builtin.service
```
