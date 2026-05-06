# Container Registry

## 0. Why Choosing to Install in `gateway` Server?
The gateway already runs Nginx for all domains. Having the registry on the same box means Nginx proxies to localhost:5000 instead of reaching across the network to another server.

## 1. Creating `gateway.yml`
Create Ansible playbook named `gateway`. Inside it, we’ll install Docker and its dependencies, containerd, and python3-docker. We’ll also install registry:2 container after that to host private docker images.

```yaml
---
# =============================================================================
# gateway.yml — Task 4: Private Docker Registry
# =============================================================================
# Target host : gateway (16.79.152.201) defined in inventory.ini
# Run with    : ansible-playbook -i inventory.ini gateway.yml
# Purpose     : Install Docker, deploy a private registry container, and
#               configure Nginx as a reverse proxy for the registry domain.
# =============================================================================

- name: Gateway — Private Docker Registry (Task 4)
  hosts: gateway        # only runs on the gateway group from inventory.ini
  become: yes           # all tasks require root / sudo

  vars:
    # -------------------------------------------------------------------------
    # Registry settings
    # -------------------------------------------------------------------------
    registry_domain: "registry.rizal.studentdumbways.my.id"
    registry_port: 5000                     # internal port the container listens on
    registry_data_dir: /opt/docker-registry # persistent volume path on the host

  tasks:

    # =========================================================================
    # SECTION 1 — Install Docker
    # =========================================================================

    # Install packages required before we can add the Docker apt repository
    - name: Install Docker prerequisites
      apt:
        name:
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present
        update_cache: yes

    # Add Docker's official GPG key so apt can verify packages
    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    # Add the stable Docker apt repository for Ubuntu 22.04
    - name: Add Docker apt repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
        filename: docker

    # Install Docker Engine and the Compose plugin
    - name: Install Docker Engine
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
        state: present
        update_cache: yes

    # Make sure the Docker daemon is running and set to start on boot
    - name: Enable and start Docker service
      service:
        name: docker
        state: started
        enabled: yes

    # Required by the community.docker.docker_container module below.
    # Without this the playbook fails with "No module named 'docker'".
    - name: Install Docker Python SDK
      apt:
        name: python3-docker
        state: present

    - name: Add {{ new_user }} to docker group
      user:
        name: "{{ new_user }}"
        groups: docker
        append: yes

    - name: Remove insecure-registry config (no longer needed — SSL active)
      file:
        path: /etc/docker/daemon.json
        state: absent

    # =========================================================================
    # SECTION 2 — Deploy Private Registry Container
    # =========================================================================

    # Create the directory that will be bind-mounted into the container.
    # This ensures image layers are persisted even if the container is recreated.
    - name: Create registry data directory
      file:
        path: "{{ registry_data_dir }}"
        state: directory
        mode: "0755"

    # Pull and run the official registry:2 image.
    # --restart=always  → survives reboots
    # -v               → mounts host dir so image data is not lost
    # -p 5000:5000     → binds the container port to localhost only
    #                    (Nginx will proxy from the public domain to this)
    - name: Run Docker Registry container
      community.docker.docker_container:
        name: docker-registry
        image: registry:2
        state: started
        restart_policy: always
        ports:
          - "127.0.0.1:{{ registry_port }}:5000"   # bind to localhost only — Nginx proxies
        volumes:
          - "{{ registry_data_dir }}:/var/lib/registry"

    # =========================================================================
    # SECTION 3 — Install & Configure Nginx Reverse Proxy
    # =========================================================================

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    # Remove the default Nginx site to avoid conflicts
    - name: Remove default Nginx site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: Reload Nginx

    # Clean up old HTTP-only sites (consolidated into ssl-gateway in Task 8)
    - name: Remove old HTTP-only sites from previous runs
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - /etc/nginx/sites-enabled/docker-registry
        - /etc/nginx/sites-enabled/loadbalancer
        - /etc/nginx/sites-enabled/prometheus
      notify: Reload Nginx

    # Validate Nginx config before reloading — catches typos early
    - name: Test Nginx configuration syntax
      command: nginx -t
      changed_when: false

    # Make sure Nginx is running and will start on boot
    - name: Enable and start Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    # =========================================================================
    # SECTION 4 — Smoke-test the Registry
    # =========================================================================

    # Hit the v2 API root — a healthy registry returns HTTP 200 with {}
    # retries=5 / delay=5 gives the container a moment to fully start
    - name: Verify registry API is responding
      uri:
        url: "http://127.0.0.1:{{ registry_port }}/v2/"
        method: GET
        status_code: 200
      retries: 5
      delay: 5
      register: registry_check

    - name: Print registry health result
      debug:
        msg: "Registry API returned status: {{ registry_check.status }} — registry is healthy!"

    # =========================================================================
    # SECTION 5 — Load Balancer (Task 5 Challenge)
    # =========================================================================

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

    # =========================================================================
    # SECTION 7 — SSL / HTTPS Wildcard Cert (Task 8)
    # =========================================================================

    - name: Install certbot and Cloudflare DNS plugin
      apt:
        name:
          - certbot
          - python3-certbot-dns-cloudflare
        state: present
        update_cache: yes

    - name: Create Let's Encrypt directory
      file:
        path: /etc/letsencrypt
        state: directory
        mode: "0755"

    - name: Deploy Cloudflare credentials for certbot
      template:
        src: templates/cloudflare.ini.j2
        dest: /etc/letsencrypt/cloudflare.ini
        owner: root
        group: root
        mode: "0600"

    - name: Request wildcard SSL certificate (DNS-01 via Cloudflare)
      command: >
        certbot certonly
        --dns-cloudflare
        --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini
        -d "*.rizaladlan.studentdumbways.my.id"
        -d "rizaladlan.studentdumbways.my.id"
        --non-interactive
        --agree-tos
        --email admin@dumbmerch.com
      args:
        creates: /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem

    - name: Remove old HTTP-only registry site
      file:
        path: /etc/nginx/sites-enabled/docker-registry
        state: absent
      notify: Reload Nginx

    - name: Remove old HTTP-only loadbalancer site
      file:
        path: /etc/nginx/sites-enabled/loadbalancer
        state: absent
      notify: Reload Nginx

    - name: Remove old HTTP-only prometheus site
      file:
        path: /etc/nginx/sites-enabled/prometheus
        state: absent
      notify: Reload Nginx

    - name: Deploy SSL Gateway Nginx config
      template:
        src: templates/ssl-gateway.conf.j2
        dest: /etc/nginx/sites-available/ssl-gateway
        owner: root
        group: root
        mode: "0644"
      notify: Reload Nginx

    - name: Enable SSL Gateway site
      file:
        src: /etc/nginx/sites-available/ssl-gateway
        dest: /etc/nginx/sites-enabled/ssl-gateway
        state: link
      notify: Reload Nginx

    - name: Deploy certbot renewal script
      template:
        src: templates/cert-renewal.sh.j2
        dest: /usr/local/bin/cert-renewal.sh
        owner: root
        group: root
        mode: "0755"

    - name: Deploy certbot renewal cronjob
      copy:
        dest: /etc/cron.d/certbot-renewal
        content: |
          0 3 * * * root /usr/local/bin/cert-renewal.sh
        owner: root
        group: root
        mode: "0644"

    - name: Test Nginx configuration
      command: nginx -t
      changed_when: false

  # ===========================================================================
  # HANDLERS — only run when notified by a task
  # ===========================================================================
  handlers:

    # Gracefully reload Nginx without dropping active connections
    - name: Reload Nginx
      service:
        name: nginx
        state: reloaded

```

1.	Installs Docker — adds Docker's GPG key and apt repo, installs docker-ce + CLI + compose + buildx plugins
2.	Applying User Permissions via Ansible
3. Installs python3-docker — so Ansible's docker_container module works
4. Configures insecure registry — writes /etc/docker/daemon.json allowing HTTP pushes to registry.rizal.studentdumbways.my.id, then restarts Docker
5. Deploys the registry container — runs registry:2 bound to 127.0.0.1:5000 with persistent storage at /opt/docker-registry
6. Sets up Nginx reverse proxy — installs Nginx, deploys the vhost from templates/registry.conf.j2, enables the site, removes the default site, validates config, starts the service


## 2. Create `/templates/...j2` files
-	Next, we're going to create some configuration files for Nginx, Prometheus, and other related app inside /templates/ directory. They use the .j2 extension which stands for Jinja2, a Python templating engine that Ansible uses.
Why are we doing it this way? Instead of a 15-line Nginx config buried inside gateway.yml, the config lives in its own file. The playbook says what to deploy; the template says how the config looks. Easier to scan both.

### 2.1 `templates/registry.conf.j2`

```python
# Nginx reverse proxy for Docker Registry — Task 4
server {
    listen 80;
    server_name {{ registry_domain }};

    # Increase body size limit — Docker image layers can be large
    client_max_body_size 2048m;

    location / {
        proxy_pass         http://127.0.0.1:{{ registry_port }};
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # Required for Docker registry v2 chunked uploads
        proxy_buffering         off;
        proxy_request_buffering off;
    }
}
```

### 2.2 `insecure-registries`
Until SSL certificates are deployed in Task 8, all Docker clients must be configured to trust this HTTP registry.

-	On Managed Servers (via Ansible): Added to gateway.yml right after Docker installation (before the registry container starts, so the restart doesn't disrupt it). Will be added to appserver.yml in Task 5 when Docker is installed there.
```yaml
{
  "insecure-registries": ["registry.rizal.studentdumbways.my.id"]
}
```

-	On Local WSL Machine: Run this bash commands after turning on docker.
```yaml
sudo tee /etc/docker/daemon.json <<'EOF'
{
	  "insecure-registries": ["registry.rizal.studentdumbways.my.id"]
	}	
EOF
sudo systemctl restart docker
```
<img width="854" height="347" alt="image" src="https://github.com/user-attachments/assets/6e0fb877-1f1b-4456-bc42-475f3bb5d805" />

## 3.	Run the Playbook
Run `ansible-playbook gateway.yml` to apply the change.
<img width="975" height="624" alt="image" src="https://github.com/user-attachments/assets/eaa999b2-e0c9-4a09-a987-02c7fc1635bd" />

-	Then, check if the registry already running with `curl -H "Host: registry.rizal.studentdumbways.my.id" http://16.79.152.201/v2/_catalog` Why we announce the Host first? Because we’re not set the domain with HTTPS for now (it’ll be added in task 8). So we need to trick the device and tell it that the IP is actually for the domain.
<img width="975" height="59" alt="image" src="https://github.com/user-attachments/assets/d81073c1-477f-4b0e-981c-3f165b4896ae" />

-	Now, we can check if we can push the images or not.
<img width="975" height="257" alt="image" src="https://github.com/user-attachments/assets/c5656a9b-f714-4fff-a927-0943defd9315" />

-	We can also check if we can pull from the registry
<img width="941" height="191" alt="image" src="https://github.com/user-attachments/assets/ea016bdf-48e1-4840-a11a-a1f9257879c4" />

