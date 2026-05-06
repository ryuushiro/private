# Web Server

## 1. Cloudflare Setting
Because we already set the DNS Records and save the Cloudflare API Token and Zone ID, we don't need to do that anymore.<br>
For reminder, here's the table for DNS records:

| Type | Name | Content | Proxy Status |
|------|------|---------|-------------|
| A | `api.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `api-staging.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `exporter.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `monitoring.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `prom.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `registry.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |
| A | `staging.rizaladlan` | 16.79.152.201 | DNS only (gray cloud) |

For now, prepare the API Token and Zone ID.

## 2. Nginx SSL Configuration
### 2.1 The Scripts
All 8 domains share a single wildcard certificate. The SSL config template is deployed at `/etc/nginx/sites-available/ssl-gateway`.

`templates/ssl-gateway.conf.j2`
```python
# =============================================================================
# SSL Gateway — Task 8
# Wildcard cert for *.rizaladlan.studentdumbways.my.id
# Consolidates: registry, loadbalancer, prometheus (all now HTTPS)
# =============================================================================

upstream frontend_pool {
    server 108.137.104.154:3000;
    server 15.232.78.179:3000;
}

upstream backend_pool {
    server 108.137.104.154:5000;
    server 15.232.78.179:5000;
}

# =============================================================================
# MONITORING: Prometheus — Basic Auth + proxy to Appserver 1:9090
# =============================================================================
server {
    listen 80;
    server_name prom.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name prom.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://108.137.128.226:9090;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# MONITORING: Grafana — proxy to Appserver 1:3000
# =============================================================================
server {
    listen 80;
    server_name monitoring.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name monitoring.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    location / {
        proxy_pass http://108.137.128.226:3000;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# MONITORING: Node Exporter — proxy to Appserver 1:9100
# =============================================================================
server {
    listen 80;
    server_name exporter.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name exporter.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    location / {
        proxy_pass http://108.137.128.226:9100;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# DOCKER REGISTRY — proxy to localhost:5000
# =============================================================================
server {
    listen 80;
    server_name registry.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name registry.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    client_max_body_size 2048m;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_buffering         off;
        proxy_request_buffering off;
    }
}

# =============================================================================
# STAGING: Frontend — Load Balancer → App 2/3:3000
# =============================================================================
server {
    listen 80;
    server_name staging.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name staging.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    location / {
        proxy_pass http://frontend_pool;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# STAGING: Backend API — Load Balancer → App 2/3:5000
# =============================================================================
server {
    listen 80;
    server_name api-staging.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api-staging.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# PRODUCTION: Frontend — Load Balancer → App 2/3:3000
# =============================================================================
server {
    listen 80;
    server_name rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    location / {
        proxy_pass http://frontend_pool;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# PRODUCTION: Backend API — Load Balancer → App 2/3:5000
# =============================================================================
server {
    listen 80;
    server_name api.rizaladlan.studentdumbways.my.id;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.rizaladlan.studentdumbways.my.id;

    ssl_certificate     /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rizaladlan.studentdumbways.my.id/privkey.pem;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

```

### 2.2 The Run
Run the Playbook with `--vault-password-file .ansible_vault_pass` attached so the terminal doesn't ask you for the password.
<img width="975" height="586" alt="image" src="https://github.com/user-attachments/assets/088219e1-8806-4388-b30d-e69f84eaedd6" />


# 3. SSL Certificate
## 3.1 Certbot
Certbot needs a Cloudflare credentials file. Template: `templates/cloudflare.ini.j2`
```ini
dns_cloudflare_api_token = {{ cloudflare_api_token }}
```
It'd be deployed to `/etc/letsencrypt/cloudflare.ini` with `chmod 600`.

## 3.2 Certificate Request
The playbook runs:
```bash
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d "*.rizaladlan.studentdumbways.my.id" \
  -d "rizaladlan.studentdumbways.my.id" \
  --non-interactive \
  --agree-tos \
  --email admin@dumbmerch.com
```

- `-d "*.rizaladlan.studentdumbways.my.id"` — covers all subdomains (prom, monitoring, staging, etc.)
- `-d "rizaladlan.studentdumbways.my.id"` — covers the apex domain
- `--dns-cloudflare` — uses DNS-01 challenge (required for wildcard)
- DNS-01 works by creating a temporary `_acme-challenge` TXT record in Cloudflare

## 3.3 Verify Certificate
Run `sudo certbot certificates` on the server that installed with it, in this case, gateway

```bash
ssh -t -i ~/.ssh/id_rsa_final_task gateway "sudo certbot certificates"
```
<img width="859" height="308" alt="image" src="https://github.com/user-attachments/assets/590fcb4f-119b-48eb-a678-2b9d86a35f2a" />

# 4. Cronjob
## 4.1 Renewal Script
Template: `templates/cert-renewal.sh.j2`

```sh
#!/bin/bash
# Certbot auto-renewal script for *.rizaladlan.studentdumbways.my.id
# Runs daily via cron. Renews if < 30 days remaining.

LOG="/var/log/certbot-renewal.log"

echo "[$(date)] Starting certbot renewal check..." >> "$LOG"

certbot renew --quiet --post-hook "systemctl reload nginx" >> "$LOG" 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] Renewal check complete." >> "$LOG"
else
    echo "[$(date)] Renewal failed! Check /var/log/letsencrypt/letsencrypt.log" >> "$LOG"
fi
```

## 4.2 Auto Renewal
Already planted inside `gateway.yml`
<img width="436" height="160" alt="image" src="https://github.com/user-attachments/assets/53554aef-c581-48b3-bad5-45d5c1c46d81" />

## 4.3 
