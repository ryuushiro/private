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

