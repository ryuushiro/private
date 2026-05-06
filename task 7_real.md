# Monitoring
## 1. Setup `monitoring.yml` Playbook
Create a playbook to install monitoring softwares in servers:
| Component | Port | Server |
|-----------|------|--------|
| Prometheus | 9090 | Appserver 1 |
| Grafana | 3000 | Appserver 1 |
| Node Exporter | 9100 | All 4 servers |
| Alertmanager | 9093 | Appserver 1 |
| cAdvisor | 8080 | Appserver 1 |

```yml
---
# =============================================================================
# monitoring.yml — Task 7: Monitoring Stack
# =============================================================================
# One playbook to rule them all. No manual server access required.
# Run: ansible-playbook -i inventory.ini monitoring.yml
# =============================================================================

# -----------------------------------------------------------------------------
# PLAY 1: Node Exporter on every server (all hosts)
# -----------------------------------------------------------------------------
- name: Monitoring — Node Exporter on all servers
  hosts: all
  become: yes
  tasks:
    - name: Allow Node Exporter port 9100 from monitoring server
      ufw:
        rule: allow
        port: "9100"
        proto: tcp
        from_ip: 108.137.128.226

    - name: Run Node Exporter container
      community.docker.docker_container:
        name: node-exporter
        image: prom/node-exporter:latest
        state: started
        restart_policy: always
        network_mode: host
        pid_mode: host
        command:
          - "--path.rootfs=/host"
        volumes:
          - "/:/host:ro,rslave"

# -----------------------------------------------------------------------------
# PLAY 2: Prometheus, Grafana, cAdvisor, Alertmanager on monitoring server
# -----------------------------------------------------------------------------
- name: Monitoring — Appserver 1 (full stack)
  hosts: monitoring
  become: yes
  tasks:
    # --- UFW ---
    - name: Remove old open Prometheus port 9090 rule
      ufw:
        rule: allow
        port: "9090"
        proto: tcp
        delete: yes

    - name: Allow Prometheus port 9090 (Gateway only — Nginx auth)
      ufw:
        rule: allow
        port: "9090"
        proto: tcp
        from_ip: 16.79.152.201

    - name: Allow Grafana port 3000
      ufw:
        rule: allow
        port: "3000"
        proto: tcp

    - name: Allow Alertmanager port 9093
      ufw:
        rule: allow
        port: "9093"
        proto: tcp

    - name: Allow cAdvisor port 8080
      ufw:
        rule: allow
        port: "8080"
        proto: tcp

    # --- cAdvisor ---
    - name: Run cAdvisor container
      community.docker.docker_container:
        name: cadvisor
        image: gcr.io/cadvisor/cadvisor:latest
        state: started
        restart_policy: always
        published_ports:
          - "8080:8080"
        volumes:
          - /:/rootfs:ro
          - /var/run:/var/run:ro
          - /sys:/sys:ro
          - /var/lib/docker/:/var/lib/docker:ro
          - /dev/disk/:/dev/disk:ro

    # --- Prometheus config ---
    - name: Create Prometheus config directory
      file:
        path: /home/finaltask-rizal/prometheus
        state: directory
        owner: finaltask-rizal
        mode: "0755"

    - name: Deploy prometheus.yml
      template:
        src: templates/prometheus.yml.j2
        dest: /home/finaltask-rizal/prometheus/prometheus.yml
        mode: "0644"

    - name: Deploy alerts.yml
      template:
        src: templates/alerts.yml.j2
        dest: /home/finaltask-rizal/prometheus/alerts.yml
        mode: "0644"

    - name: Run Prometheus container
      community.docker.docker_container:
        name: prometheus
        image: prom/prometheus:latest
        state: started
        restart_policy: always
        network_mode: host
        volumes:
          - /home/finaltask-rizal/prometheus:/etc/prometheus
        command:
          - "--config.file=/etc/prometheus/prometheus.yml"
          - "--storage.tsdb.retention.time=15d"
          - "--storage.tsdb.retention.size=500MB"
          - "--web.listen-address=0.0.0.0:9090"

    # --- Alertmanager ---
    - name: Deploy alertmanager.yml
      template:
        src: templates/alertmanager.yml.j2
        dest: /home/finaltask-rizal/prometheus/alertmanager.yml
        mode: "0644"

    - name: Run Alertmanager container
      community.docker.docker_container:
        name: alertmanager
        image: prom/alertmanager:latest
        state: started
        restart_policy: always
        published_ports:
          - "9093:9093"
        volumes:
          - /home/finaltask-rizal/prometheus/alertmanager.yml:/etc/alertmanager/alertmanager.yml

    # --- Grafana ---
    - name: Create Grafana data directory
      file:
        path: /home/finaltask-rizal/grafana
        state: directory
        owner: "472"        # Grafana container runs as UID 472
        mode: "0755"

    - name: Run Grafana container
      community.docker.docker_container:
        name: grafana
        image: grafana/grafana:latest
        state: started
        restart_policy: always
        network_mode: host
        volumes:
          - /home/finaltask-rizal/grafana:/var/lib/grafana
        env:
          GF_SECURITY_ADMIN_USER: admin
          GF_SECURITY_ADMIN_PASSWORD: "{{ grafana_admin_password }}"
```


## 2. Setup `/template/...j2` files
### 2.1 Prometheus.yml.j2
Scrape targets for all 4 servers + cAdvisor

```python
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "/etc/prometheus/alerts.yml"

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets:
          - '16.79.152.201:9100'
          - '108.137.128.226:9100'
          - '108.137.104.154:9100'
          - '15.232.78.179:9100'

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

```

### 2.2 `alerts.yml.j2`
4 alert rules (CPU >80%, RAM >85%, Disk <15%, Network)

```python
{% raw %}
groups:
  - name: server_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"

      - alert: LowDiskSpace
        expr: (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 < 15
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"

      - alert: HighNetworkReceive
        expr: rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 > 100000000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High network receive on {{ $labels.instance }} ({{ $labels.device }})"
{% endraw %}

```

### 2.3 `alertmanager.yml.j2`
Telegram routing with bot token and chat ID

```python
global:
  resolve_timeout: 5m

route:
  receiver: 'telegram'
  group_by: ['alertname', 'instance']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 4h

receivers:
  - name: 'telegram'
    telegram_configs:
      - bot_token: '{{ telegram_bot_token }}'
        chat_id: {{ telegram_chat_id }}
        parse_mode: 'HTML'
{% raw %}
        message: |
          <b>{{ .Status | toUpper }}</b>: {{ .CommonAnnotations.summary }}
          {{ range .Alerts }}
          {{ .Annotations.summary }}
          {{ end }}
{% endraw %}

```


## 3. Setup Telegram Bot
### 3.1 Create a Bot and Get the Token
- Chat @BotFather on Telegram "/newbot". After that, give it the bot name for the project and also the Telegram handle (@). After that, you'd get your API token.
<img width="804" height="740" alt="image" src="https://github.com/user-attachments/assets/83fe10a0-e596-4510-a25a-99600309939a" />

### 3.2 Get a Chat ID from Your Bot
- After that, chat the new bot. Start a new conversation, anything can goes for a dummy message.
<img width="626" height="416" alt="image" src="https://github.com/user-attachments/assets/88425f11-7fd4-46a8-abb1-b8deffdcfbd5" />
<br>

- Then, to get your Chat ID, go to https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates and search for numbers after "update_id":
<img width="673" height="276" alt="image" src="https://github.com/user-attachments/assets/d675b454-8370-484a-ac9f-915ba46f4a2a" />


## 4. Setup Vault (For Grafana Password and Telegram Token)
### 4.1 Grafana
Inside `monitoring.yml`, Grafana's User's ID and Password is already set with variable `GF_SECURITY_ADMIN_USER` and `GF_SECURITY_ADMIN_PASSWORD`.
```yml
    # --- Grafana ---
    - name: Run Grafana container
      community.docker.docker_container:
        name: grafana
        image: grafana/grafana:latest
        state: started
        restart_policy: always
        published_ports:
          - "3000:3000"
        env:
          GF_SECURITY_ADMIN_USER: admin
          GF_SECURITY_ADMIN_PASSWORD: "{{ grafana_admin_password }}"
```

Now, the 'GF_SECURITY_ADMIN_PASSWORD` can be set inside Ansible Vault.<br>
For example:

```ini
vault_grafana_admin_password: admin123
```

### 4.2 Telegram
For Telegram, the variable `telegram_bot_token` and `telegram_chat_id` are mentioned inside `alertmanager.yml.j2`.

```python
receivers:
  - name: 'telegram'
    telegram_configs:
      - bot_token: '{{ telegram_bot_token }}'
        chat_id: {{ telegram_chat_id }}
        parse_mode: 'HTML'
```

Same as Grafana before, both of them can be set inside Ansible Vault.

```ini
vault_telegram_bot_token: PLACEHOLDER_BOT_TOKEN
vault_telegram_chat_id: "PLACEHOLDER_ID"
```

### 4.3 Editing the Vault
- First, run this:

  ```bash
  cd ~/infrastructure/ansible
  EDITOR=nano ansible-vault edit --vault-password-file .ansible_vault_pass group_vars/all/vault.yml
  ```
  <img width="714" height="71" alt="image" src="https://github.com/user-attachments/assets/21e587e7-3fb2-46a2-8fdf-b1e1e2ff5fac" />


- Then, fill the Vault with the password and tokens
  <img width="550" height="124" alt="image" src="https://github.com/user-attachments/assets/6782d419-3785-436e-be5d-adf41fc99433" />



## 5. Applying `monitoring.yml` to Install Apps
To continue to the next steps, `monitoring.yml` need to be applied to the servers.<br>
Run `ansible-playbook -i inventory.ini monitoring.yml`.
<img width="986" height="1011" alt="image" src="https://github.com/user-attachments/assets/94cc330f-29a4-4fd2-bf2e-e61fff4de6b8" />


## 6. Monitoring Apps
### 6.1 Grafana Connection
- Login to Grafana and click "Data Source" on the left panel.
  <img width="1850" height="988" alt="image" src="https://github.com/user-attachments/assets/aa7595f3-4d99-4bd1-99c3-f76defb9b570" />

- Inside the Data Source page, click "Add new data source"
  <img width="1550" height="149" alt="image" src="https://github.com/user-attachments/assets/cfadf6d9-82a8-415f-84ce-8d23ecdc6d45" />

- Pick "Premetheus"
  <img width="1543" height="262" alt="image" src="https://github.com/user-attachments/assets/da51892e-e405-4242-b0e7-463040e0d15c" />

- In the next page, put Premetheus' IP:PORT to Connection text-box, then click "Save & Test" at the bottom of the page.
  <img width="1534" height="686" alt="image" src="https://github.com/user-attachments/assets/5935cc76-82ee-4be3-88fa-65f4400a5170" />

### 6.2 Grafana Dashboard
- Go to Dashboard and click "New > New Dashboard" at the right side of the page, 
  <img width="1556" height="173" alt="image" src="https://github.com/user-attachments/assets/a5df5591-a6d2-46b9-928c-706f3dface8e" />

- In the New Dashboard page, click the blue "+" on the right side of the page and click "Add new panel"
  <img width="1580" height="746" alt="image" src="https://github.com/user-attachments/assets/db3d13fb-0750-4db9-b08c-7aacd1eb3410" />

- After that "Configure visualization"
  <img width="721" height="434" alt="image" src="https://github.com/user-attachments/assets/e309a824-d9c7-4c1f-930b-7106b46391ff" />

- Now, in this page, change from "Builder" to "Code" on the metric query search, then you can input the PromQL for the things that you want to show on the dashboard. 
  <img width="1574" height="914" alt="image" src="https://github.com/user-attachments/assets/6eca1d34-b086-416d-8bdd-6324f04da98b" />

- For example, with this one the PromQL Query shows how much RAM usage in percentage
  <img width="1572" height="916" alt="image" src="https://github.com/user-attachments/assets/e5bb730c-5691-463d-97d6-02b17ac8a2ab" />

- Here are the full dashboard according to the task
  <img width="1699" height="851" alt="image" src="https://github.com/user-attachments/assets/4e8c8d63-40af-4abb-83fd-9894a33da109" />

### 6.3 Telegram Alerts
Before, the telegram bot's API was already taken care of.

So, how it actually works?

The chain: Prometheus → alerts.yml → Alertmanager → alertmanager.yml → Telegram

  1. Prometheus scrapes metrics from all node_exporters every 15s (CPU, memory, disk, network).

  2. alerts.yml.j2 — Alert Rules (loaded by Prometheus)

  This file defines when to fire an alert. Four rules:
  - HighCPUUsage — avg CPU idle < 20% (i.e. usage > 80%) for 5 min → severity: warning
  - HighMemoryUsage — available memory < 15% for 5 min → severity: warning
  - LowDiskSpace — free disk < 15% for 5 min → severity: critical
  - HighNetworkReceive — receive rate > 100 Mbps for 5 min → severity: warning

  3. Alertmanager receives the alert from Prometheus when a rule fires.

  4. alertmanager.yml.j2 — Alert Routing (Alertmanager's config)

  This defines what to do with incoming alerts:
  - Groups alerts by alertname and instance (avoids flooding you with 4 separate messages for the same incident)
  - Waits 10s to collect grouped alerts, then sends
  - Repeats every 4 hours if the issue persists
  - Routes all alerts to the telegram receiver

**Manually test the alert:**
```bash
curl -s -X POST http://108.137.128.226:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "PipelineVerified",
      "instance": "Task7",
      "severity": "critical"
    },
    "annotations": {
      "summary": "Task 7 Monitoring Pipeline is fully operational! Alertmanager -> Telegram verified."
    },
    "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }]' -w "\nHTTP %{http_code}\n"
```

<img width="624" height="778" alt="image" src="https://github.com/user-attachments/assets/b418a8a7-a7e5-49b9-bd6e-30c135466d9d" />


## 7. Prometheus Gateway Challenge 

Add these to `gateway.yml`

```yaml
    # =========================================================================
    # SECTION 6 — Prometheus Basic Auth (Task 7 Challenge)
    # =========================================================================

    - name: Install apache2-utils for htpasswd
      apt:
        name: apache2-utils
        state: present

    - name: Create htpasswd for Prometheus Basic Auth
      shell:
        cmd: htpasswd -bc /etc/nginx/.htpasswd admin "{{ prometheus_auth_password }}"
        creates: /etc/nginx/.htpasswd

    - name: Deploy Prometheus Nginx config
      template:
        src: templates/prometheus-nginx.conf.j2
        dest: /etc/nginx/sites-available/prometheus
        owner: root
        group: root
        mode: "0644"
      notify: Reload Nginx

    - name: Enable Prometheus site
      file:
        src: /etc/nginx/sites-available/prometheus
        dest: /etc/nginx/sites-enabled/prometheus
        state: link
      notify: Reload Nginx

    - name: Test Nginx configuration
      command: nginx -t
      changed_when: false
```

Then create `prometheus-nginx.conf.j2

```python
server {
    listen 80;
    server_name prom.rizaladlan.studentdumbways.my.id;

    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://108.137.128.226:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Add the password for login in the Vault.

```python
vault_prometheus_auth_password: dumbways
```

<img width="975" height="201" alt="image" src="https://github.com/user-attachments/assets/d3670ef7-9d45-49e9-aa95-8390f5cd744d" />
