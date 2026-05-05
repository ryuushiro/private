# Task 6: CI/CD (ft. SonarCloud)

## Step 1: SonarCloud Project Setup + `.gitlab-ci.yml`

> Due to RAM constraints on the AWS server, SonarCloud is employed as the preferred solution. SonarCloud is the *SonarQube-as-a-Service* from the same company (SonarSource). Same sonar-scanner CLI, same analysis engine, same Quality Gates, same dashboard.

### 1.1 Create Organization

- Go to https://sonarcloud.io , then click "Log in"
  
  <img width="1176" height="145" alt="2026-05-05-10-59-54-image" src="https://github.com/user-attachments/assets/b9e2387d-d0fa-4d30-986c-d59861165d99" />
  
- In the login page, choose login with GitLab because the private fork of the repos are already there.
  
  <img width="455" height="874" alt="2026-05-05-11-01-09-image" src="https://github.com/user-attachments/assets/0e15c091-4ee7-4821-9d11-d865b256310c" />
  
- After logged in, look at the top right of the page then click on "+" besides the account avatar. Then click "Create new organization".
  
  <img width="222" height="261" alt="2026-05-05-11-03-09-image" src="https://github.com/user-attachments/assets/379f6c35-b556-4d8d-ba7d-005ebb17a94e" />
  
- In the next page, there are two choices, either import from GitLab or create a new one manually. Choose "Import from a DevOps platform - GitLab"
  
  <img width="1047" height="369" alt="image" src="https://github.com/user-attachments/assets/b8ffccae-165f-4f69-be1b-b932667f39c2" />

- On the next page, you need to fill the text-boxes with gitlab group key and personal access token. For the tutorial of them, you can look at [Importing GitLab group | SonarQube Cloud | Sonar Documentation](https://docs.sonarsource.com/sonarqube-cloud/administering-sonarcloud/managing-organization/creating-organization/importing-gitlab-group)
  
  <img width="573" height="617" alt="image" src="https://github.com/user-attachments/assets/b23ec73e-17f8-4d27-8cd5-9d31a246fc93" />

  
- After filled the first two text-boxes with the right group key and token, a new page gonna be shown below it and pick the free plan. After that, click the "Create organization" button.
  
  <img width="763" height="1045" alt="image" src="https://github.com/user-attachments/assets/28d604f4-9b4d-430c-82bc-bf38047cc01c" />
  

### 1.2 Create Projects

- After creating the organization, a new page gonna be shown. In that organization page, click "Analyze a new project".
  
  <img width="1919" height="1199" alt="image" src="https://github.com/user-attachments/assets/371c4bee-3d4d-406b-a6e2-6ecd3ff52627" />
  
- In the "Analyze projects" page, the "Organization" will be automatically picked, then the repos will be shown below it. Select both BE and FE repos then click "Set Up" button on the right side.
  
  <img width="1187" height="541" alt="image" src="https://github.com/user-attachments/assets/326ab4ca-0493-4cac-b436-c2599f6a366f" />
  
- Back to the organization page, now that there are two projects, click "Configure analysis" on one of them for now.
  
  <img width="1907" height="1192" alt="image" src="https://github.com/user-attachments/assets/24b3ce17-f2f8-4ee7-b11e-58c5b861910f" />
  
- When prompted for analysis method, choose GitLab CI
  
  <img width="1441" height="348" alt="image" src="https://github.com/user-attachments/assets/a891d2d5-5eb5-4b27-a90f-251594a8c72b" />
  
- Then, follow the guides from the next page.
  
  <img width="1659" height="829" alt="image" src="https://github.com/user-attachments/assets/07c696c7-d58c-45af-a2b8-377c28edd4e8" />
  
  <img width="1665" height="714" alt="image" src="https://github.com/user-attachments/assets/92d2792c-7baa-418d-ad1d-8495ec71cf11" />

  <img width="1187" height="451" alt="image" src="https://github.com/user-attachments/assets/0a1e33d9-c614-4080-abca-46b6e2f6d0e2" /><br>
  
- Following the guide 1: add env. variables (add both to BE and FE project)
  
  <img width="985" height="356" alt="image" src="https://github.com/user-attachments/assets/a5cd5740-4891-4188-8864-75a3d3d4e599" /><br>
  
  
  | Variable | Value | Protected | Masked |
  |----------|-------|-----------|--------|
  | `SONAR_TOKEN` | SonarCloud token (from step 4.2) | No | Yes |
  | `SONAR_HOST_URL` | `https://sonarcloud.io` | No | No |
  | `SSH_PRIVATE_KEY` | `~/.ssh/id_rsa_final_task` | Yes | No |
  | `ANSIBLE_VAULT_PASS` | Contents of `.ansible_vault_pass` | Yes | Yes |
  | `REGISTRY_URL` | `16.79.152.201:80` | No | No |
<br>

## Step 2: GitLab Pipeline
### 2.1 Following the guide from SonarCloud 2: update `.gitlab-ci.yml`
  
  This one is for BE.
  
  ```yaml
  stages:
    - build
    - test
    - push
    - deploy
  
  variables:
    DOCKER_TLS_CERTDIR: ""
    DOCKER_HOST: tcp://docker:2375
    IMAGE_TAG: $REGISTRY_URL/be-dumbmerch:Staging
  
  build:
    stage: build
    image: docker:latest
    services:
      - name: docker:dind
        command: ["--insecure-registry=16.79.152.201:80"]
    script:
      - docker build --platform linux/amd64 -t $IMAGE_TAG .
      - docker save -o image.tar $IMAGE_TAG
    artifacts:
      paths:
        - image.tar
    only:
      - Staging
  
  sonarqube-check:
    stage: test
    image: sonarsource/sonar-scanner-cli:latest
    script:
      - sonar-scanner
        -Dsonar.projectKey=rizaladlan_be-dumbmerch
        -Dsonar.organization=rizaladlan
        -Dsonar.host.url=$SONAR_HOST_URL
        -Dsonar.token=$SONAR_TOKEN
    only:
      - Staging
  
  push:
    stage: push
    image: docker:latest
    services:
      - name: docker:dind
        command: ["--insecure-registry=16.79.152.201:80"]
    script:
      - docker load -i image.tar
      - docker push $IMAGE_TAG
    only:
      - Staging
  
  deploy:
    stage: deploy
    image: ubuntu:latest
    before_script:
      - apt-get update && apt-get install -y ansible openssh-client git
      - mkdir -p ~/.ssh
      - echo "$SSH_PRIVATE_KEY" | tr -d '\r' > ~/.ssh/id_rsa_final_task
      - chmod 600 ~/.ssh/id_rsa_final_task
      - cp ~/.ssh/id_rsa_final_task ~/.ssh/id_rsa
      - chmod 600 ~/.ssh/id_rsa
    script:
      - export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
      - git clone --depth 1 git@gitlab.com:rizaladlan/infrastructure.git /tmp/infrastructure
      - echo "$ANSIBLE_VAULT_PASS" > /tmp/infrastructure/ansible/.ansible_vault_pass
      - cd /tmp/infrastructure/ansible
      - ansible-galaxy collection install community.docker
      - ansible-playbook -i inventory.ini appserver.yml
    only:
      - Staging
  ```
  
- This one is for FE
  
```yaml
  stages:
    - build
    - test
    - push
    - deploy
  
  variables:
    DOCKER_TLS_CERTDIR: ""
    DOCKER_HOST: tcp://docker:2375
    IMAGE_TAG: $REGISTRY_URL/fe-dumbmerch:Staging
  
  build:
    stage: build
    image: docker:latest
    services:
      - name: docker:dind
        command: ["--insecure-registry=16.79.152.201:80"]
    script:
      - docker build --platform linux/amd64 -t $IMAGE_TAG .
      - docker save -o image.tar $IMAGE_TAG
    artifacts:
      paths:
        - image.tar
    only:
      - Staging
  
  sonarqube-check:
    stage: test
    image: sonarsource/sonar-scanner-cli:latest
    script:
      - sonar-scanner
        -Dsonar.projectKey=rizaladlan_fe-dumbmerch
        -Dsonar.organization=rizaladlan
        -Dsonar.host.url=$SONAR_HOST_URL
        -Dsonar.token=$SONAR_TOKEN
    only:
      - Staging
  
  push:
    stage: push
    image: docker:latest
    services:
      - name: docker:dind
        command: ["--insecure-registry=16.79.152.201:80"]
    script:
      - docker load -i image.tar
      - docker push $IMAGE_TAG
    only:
      - Staging
  
  deploy:
    stage: deploy
    image: ubuntu:latest
    before_script:
      - apt-get update && apt-get install -y ansible openssh-client git
      - mkdir -p ~/.ssh
      - echo "$SSH_PRIVATE_KEY" | tr -d '\r' > ~/.ssh/id_rsa_final_task
      - chmod 600 ~/.ssh/id_rsa_final_task
      - cp ~/.ssh/id_rsa_final_task ~/.ssh/id_rsa
      - chmod 600 ~/.ssh/id_rsa
    script:
      - export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
      - git clone --depth 1 git@gitlab.com:rizaladlan/infrastructure.git /tmp/infrastructure
      - echo "$ANSIBLE_VAULT_PASS" > /tmp/infrastructure/ansible/.ansible_vault_pass
      - cd /tmp/infrastructure/ansible
      - ansible-galaxy collection install community.docker
      - ansible-playbook -i inventory.ini appserver.yml
    only:
      - Staging

  ```

### 2.2 Pipeline Summary
| Stage | Job | What it does |
|-------|-----|-------------|
| build | `build` | Builds Docker image with `docker:latest` + `docker:dind`, saves as `image.tar` artifact |
| test | `sonarqube-check` | `sonar-scanner` analyzes code and uploads results to SonarCloud |
| push | `push` | Loads artifact, pushes to `16.79.152.201:80` (HTTP registry, insecure) |
| deploy | `deploy` | Clones infra repo, installs Ansible + community.docker, runs `appserver.yml` to SSH/pull/redeploy |
  
### 2.3 Following the guide 3: create `sonar-project.properties`
  
  This one is for BE
  
  ```ini
  sonar.projectKey=rizaladlan_be-dumbmerch
  sonar.organization=rizaladlan
  sonar.sources=.
  sonar.exclusions=**/*_test.go,**/vendor/**
  sonar.go.coverage.reportPaths=coverage.out  
  ```
  
  This one is for FE
  
  ```ini
  sonar.projectKey=rizaladlan_fe-dumbmerch
  sonar.organization=rizaladlan
  sonar.sources=src
  sonar.exclusions=**/*.test.js,**/node_modules/**
  ```

### 2.4 Infrastructure Repository

The deploy stage needs Ansible playbooks. These live in a separate repository at `rizaladlan/infrastructure.git` containing only the `ansible/` directory:

```
infrastructure/
  ansible/
    inventory.ini
    appserver.yml
    ansible.cfg
    common.yml
    gateway.yml
    site.yml
    group_vars/
      all/
        all.yml
        vault.yml
      appservers/
        vars.yml
      gateway/
        vars.yml
    templates/
      be.env.j2
      loadbalancer.conf.j2
      registry.conf.j2
```

Sensitive files excluded via `.gitignore`: `.ansible_vault_pass`, `terraform.tfstate`, `.terraform/`. The vault password is injected via CI/CD variable `ANSIBLE_VAULT_PASS` at runtime.

### 2.5 Push both BE and FE to GitLab
<img width="832" height="811" alt="image" src="https://github.com/user-attachments/assets/90c9e619-acd3-4661-ae5b-65c7edc58d0c" />

### 2.6 Watch Pipeline in GitLab
1. Go to GitLab → Build → Pipelines
2. Click the pipeline to see all 4 stages
3. If any stage fails, click the failed job to see logs

<img width="1257" height="626" alt="image" src="https://github.com/user-attachments/assets/9c47e5df-7d61-4903-9578-992d2abab83e" />*BE Staging Branch's Pipeline showing what's running*

<img width="1246" height="620" alt="image" src="https://github.com/user-attachments/assets/4d1537a6-7004-4caf-87e3-e3b1ceae64c1" />*FE Staging Branch's Pipeline showing what's running*

## 3. Verification
### 3.1 Pipeline Status
The CI/CD pipline will be tagged as "Passed" when clearing all 4 stages.
<img width="1047" height="126" alt="image" src="https://github.com/user-attachments/assets/f21a25a9-ca67-4b1e-b3c4-b187d59462ba" />
<img width="1252" height="582" alt="image" src="https://github.com/user-attachments/assets/0ab12bc8-0be2-46da-8f93-b8bc49eb3869" />

### 3.2 SonarCloud Quality Gate
Open each project on SonarCloud and verify the scan results appear with a passing Quality Gate.
<img width="1201" height="656" alt="image" src="https://github.com/user-attachments/assets/a7050c96-0d84-4f15-9989-71818634a4b4" />

### 3.3 Deploy Verification
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://108.137.104.154:3000/
curl -s -o /dev/null -w "%{http_code}\n" http://15.232.78.179:3000/
curl -s -o /dev/null -w "%{http_code}\n" http://108.137.104.154:5000/api/v1/products
curl -s -o /dev/null -w "%{http_code}\n" http://15.232.78.179:5000/api/v1/products
# Expected: 200 on all four
```
<img width="940" height="166" alt="image" src="https://github.com/user-attachments/assets/7b9d5f0b-ffff-4e8b-90d9-480a46ee74db" />

### 3.4 App Crawl (wget spider)
```bash
wget --spider --recursive --level=2 --no-verbose http://108.137.104.154:3000/
```

The spider crawls all linked pages recursively and confirms they return 200. Expected "broken links" (favicon.ico, logo192.png) are cosmetic React boilerplate — not real issues.
<img width="1126" height="428" alt="image" src="https://github.com/user-attachments/assets/8dff8e08-9322-41cd-bf7d-5c0baaee8b55" />
