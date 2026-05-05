# Task 5: Deployment
## Step 0 : Switch to Staging (because I want to use staging branch for now)
Run these commands in your WSL terminal:
   1. Enter the Backend directory and switch:
    -	cd ~/dumbmerch/be-dumbmerch
    -	git checkout Staging

   2. Enter the Frontend directory and switch:
    -	cd ~/dumbmerch/fe-dumbmerch
    -	git checkout Staging
    <img width="841" height="256" alt="image" src="https://github.com/user-attachments/assets/c6540e02-e650-4ef1-8fed-2be357edc9d2" />

## Step 1: BE Containerization
-	First, exclude .env file (the one that has been created from task 2) from docker so that the file not get pushed.
  ```bash
  echo ".env" > .dockerignore
  cat .dockerignore
  ```
 	
  <img width="874" height="133" alt="image" src="https://github.com/user-attachments/assets/fd3a2a4e-1db9-45b5-b329-6ba7dffce211" /><br>

-	Then create a multi-stage Dockerfile. What does it mean? The Dockerfile will be filled with two stages; build and run. I do this to reduce the size of the images.
  <img width="531" height="309" alt="image" src="https://github.com/user-attachments/assets/b7792644-cdab-4c5f-b9aa-b9747ebcbd33" />*I use `–platform=linux/arm64` flags because I’m building it in an ARM laptop and the server’s os is AMD64 one so I can’t run the docker on that if I don’t change it.*
  <br>
  
-	After that, build the docker image with `docker build --platform linux/amd64 -t 16.79.152.201:80/be-dumbmerch:Staging .` Why `--platform linux/amd64`? My laptop is ARM64, but the AWS servers are x86_64. Without that flag, the image would fail with exec format
  error on the servers.
  <img width="975" height="569" alt="image" src="https://github.com/user-attachments/assets/73c9476d-f55e-4cd7-aa7f-4415c96e372a" /><br>

-	When the image already built, push it with `docker push 16.79.152.201:80/be-dumbmerch:Staging`
    <img width="975" height="173" alt="image" src="https://github.com/user-attachments/assets/797b5c2d-2fb9-4529-ac33-405ffefe0964" />

## Step 2: FE Containerization
- It'll be almost the same as BE. First, exclude .env file.
  <img width="880" height="150" alt="image" src="https://github.com/user-attachments/assets/956ef316-bb58-4cca-817c-3f169b2287f7" />

- Then create the Dockerfile
  <img width="536" height="298" alt="image" src="https://github.com/user-attachments/assets/1df84f0c-35b4-4b95-9de1-11cfa9b9052d" />

- Then build the image
  <img width="975" height="464" alt="image" src="https://github.com/user-attachments/assets/f930e8ee-5896-4685-8331-cec5b81bf04f" />

- After that, push it.
  <img width="975" height="315" alt="image" src="https://github.com/user-attachments/assets/27f5ddc6-9e5b-4c38-b738-46bec4816b80" />

## Step 3: Setup `appserver.yml` and `be.env.j2`

Inside `appserver.yml`, there are two plays/stages.
   - Play 1: Docker Setup
     - Installs Docker CE, CLI, containerd, buildx, compose plugin, python3-docker
     - Adds the finaltask-rizal user to the docker group
     - Configures insecure-registries for the private registry
     - Restarts Docker to apply the registry config
   - Play 2: Deploy Containers <br>
      What it does:
      | Task | Detail |
      |------|--------|
      | Docker network | Creates `dumbmerch-network` bridge |
      | UFW rules | Opens ports 3000, 5000, 5432 |
      | PostgreSQL | `postgres:15-alpine`, volume at `/home/finaltask-rizal/db-data`, env vars for user/password/db |
      | Backend .env | Deploys from Jinja2 template with DB credentials |
      | Backend container | Pulls `16.79.152.201:80/be-dumbmerch:Staging`, mounts `.env` as read-only |
      | Frontend container | Pulls `16.79.152.201:80/fe-dumbmerch:Staging`, serves on port 3000 |
      | Smoke tests | Verifies FE returns 200, BE returns 200/404 |
     
      <img width="529" height="465" alt="image" src="https://github.com/user-attachments/assets/7d8993b1-a118-4f17-80eb-6420ddae3876" />*Example of installing PostgreSQL on top of Docker*.

Then, as written above, the .env file need to be imported from `templates/be.env.j2`.
<img width="428" height="106" alt="image" src="https://github.com/user-attachments/assets/a592d26f-60d7-4eab-baef-03231a9e58b0" />
So, for that, create the file.
<img width="390" height="139" alt="image" src="https://github.com/user-attachments/assets/b3b3ddd4-5a64-4e2b-8e70-067fbac4a47d" />

## Step 4: Run appserver playbook
Run `ansible-playbook -i inventory.ini appserver.yml`
<img width="1264" height="729" alt="image" src="https://github.com/user-attachments/assets/c2a0fabf-1726-44ee-b2b0-bb6306650aff" />
<img width="1255" height="902" alt="image" src="https://github.com/user-attachments/assets/9def709b-e5ac-4204-856b-14e3ea46530e" />
<img width="1260" height="83" alt="image" src="https://github.com/user-attachments/assets/385c012e-80d1-4b5a-8441-264eb5396197" />

## Step 5: Verification

### 5.1 Frontend

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://108.137.104.154:3000/
curl -s -o /dev/null -w "%{http_code}\n" http://15.232.78.179:3000/
# Expected: 200 on all two
```
<img width="845" height="104" alt="image" src="https://github.com/user-attachments/assets/954e4e40-ebc1-4a2b-85dc-3e1382f8544e" /><br>
<img width="1919" height="1151" alt="image" src="https://github.com/user-attachments/assets/471234e9-e98d-45ef-8346-665bad88b211" />

### 5.2 Backend API

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://108.137.104.154:5000/api/v1/products
curl -s -o /dev/null -w "%{http_code}\n" http://15.232.78.179:5000/api/v1/products
# Expected: 200 on all two
```

<img width="941" height="98" alt="image" src="https://github.com/user-attachments/assets/4fd309e2-6eaa-4242-9bfa-73f36e584594" />

### 5.3 Database

```bash
# SSH into any appserver and run:
docker exec dumbmerch-db psql -U rizaladlan -d dumbmerch -c '\dt'
```
<img width="781" height="743" alt="image" src="https://github.com/user-attachments/assets/cf0a9f47-0872-4545-a6f8-16cff5af5529" />

## Step 6: Load Balancing Challenge

### 6.1 Create the Loadbalancer Config Template
 Create `/home/rzl/infrastructure/ansible/templates/loadbalancer.conf.j2`:

   ```.py
   # Nginx Load Balancer — Task 5 Challenge
   # Distributes traffic across app_nodes (Appserver 2 & 3)
   
   upstream frontend_pool {
       server 108.137.104.154:3000;
       server 15.232.78.179:3000;
   }
   
   upstream backend_pool {
       server 108.137.104.154:5000;
       server 15.232.78.179:5000;
   }
   
   server {
       listen 80;
       server_name staging.rizaladlan.studentdumbways.my.id;
   
       location / {
           proxy_pass http://frontend_pool;
           proxy_set_header Host              $host;
           proxy_set_header X-Real-IP         $remote_addr;
           proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
       }
   }
   
   server {
       listen 80;
       server_name api.staging.rizaladlan.studentdumbways.my.id;
   
       location / {
           proxy_pass http://backend_pool;
           proxy_set_header Host              $host;
           proxy_set_header X-Real-IP         $remote_addr;
           proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
       }
   }
   
   ```
### 6.2 Add Tasks to `gateway.yml`
<img width="698" height="459" alt="image" src="https://github.com/user-attachments/assets/a4ec24e4-37f1-459f-9d24-0cd14beb4937" />

### 6.3 RUN
<img width="1257" height="1035" alt="image" src="https://github.com/user-attachments/assets/a545a91d-4195-4bfd-826d-34d78fc97317" />
<img width="1239" height="311" alt="image" src="https://github.com/user-attachments/assets/8d85a04e-f4f6-46f9-a920-75166ec775fe" />








