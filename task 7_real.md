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
 -----------------------------------------------------------------------------
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
          - '--path.rootfs=/host'
        volumes:
          - '/:/host:ro,rslave'

# -----------------------------------------------------------------------------
# PLAY 2: Prometheus, Grafana, cAdvisor, Alertmanager on monitoring server
# -----------------------------------------------------------------------------
- name: Monitoring — Appserver 1 (full stack)
  hosts: monitoring
  become: yes
  tasks:
    # --- UFW ---
    - name: Allow Prometheus port 9090
      ufw:
        rule: allow
        port: "9090"
        proto: tcp

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
        published_ports:
          - "9090:9090"
        volumes:
          - /home/finaltask-rizal/prometheus:/etc/prometheus
        command:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.retention.time=15d'
          - '--storage.tsdb.retention.size=500MB'

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

# 3. Setup Telegram Bot
## 3.1 Create a Bot and Get the Token
- Chat @BotFather on Telegram "/newbot". After that, give it the bot name for the project and also the Telegram handle (@). After that, you'd get your API token.
<img width="804" height="740" alt="image" src="https://github.com/user-attachments/assets/83fe10a0-e596-4510-a25a-99600309939a" />

## 3.2 Get a Chat ID from Your Bot
- After that, chat the new bot. Start a new conversation, anything can goes for a dummy message.
<img width="626" height="416" alt="image" src="https://github.com/user-attachments/assets/88425f11-7fd4-46a8-abb1-b8deffdcfbd5" />
<br>

- Then, to get your Chat ID, go to https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates and search for numbers after "update_id":
<img width="673" height="276" alt="image" src="https://github.com/user-attachments/assets/d675b454-8370-484a-ac9f-915ba46f4a2a" />

# 4. Setup Vault (For Grafana Password and Telegram Token)
## Grafana
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

## Telegram
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

## Editing the Vault
First, run this:

```bash
cd ~/infrastructure/ansible
EDITOR=nano ansible-vault edit --vault-password-file .ansible_vault_pass group_vars/all/vault.yml
```


