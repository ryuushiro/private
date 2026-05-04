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

## Step 3: Setup `appserver.yml`

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

