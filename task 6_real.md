# Task 6: CI/CD (ft. SonarCloud)

## Step 1: SonarCloud Project Setup

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
  
  <img width="991" height="348" alt="image" src="https://github.com/user-attachments/assets/5631949e-6509-4677-b40a-383531812e1e" /><br>
  
  
  | Variable | Value | Protected | Masked |
  |----------|-------|-----------|--------|
  | `SONAR_TOKEN` | SonarCloud token (from step 4.2) | Yes | Yes |
  | `SONAR_HOST_URL` | `https://sonarcloud.io` | No | No |
  | `SSH_PRIVATE_KEY` | base64-encoded key (`base64 -w0 < ~/.ssh/id_rsa_final_task`) | Yes | Yes |
  | `ANSIBLE_VAULT_PASS` | Contents of `.ansible_vault_pass` | Yes | Yes |
  | `REGISTRY_URL` | `16.79.152.201:80` | No | No |
<br>

- Following the guide 2: update `.gitlab-ci.yml`
  
  This one is for BE.
  
  ```yaml
  stages:
    - build
    - test
    - push
    - deploy
  
  variables:
    IMAGE_TAG: $REGISTRY_URL/be-dumbmerch:Staging
  
  build:
    stage: build
    image: docker:latest
    services:
      - docker:dind
    script:
      - docker buildx build --platform linux/amd64 -t $IMAGE_TAG .
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
      - docker:dind
    before_script:
      - mkdir -p ~/.docker
      - echo '{"insecure-registries":["'"$REGISTRY_URL"'"]}' > ~/.docker/config.json
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
      - echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa
    script:
      - git clone --depth 1 git@gitlab.com:rizaladlan/infrastructure.git /tmp/infrastructure
      - echo "$ANSIBLE_VAULT_PASS" > /tmp/infrastructure/ansible/.ansible_vault_pass
      - cd /tmp/infrastructure/ansible
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
    IMAGE_TAG: $REGISTRY_URL/fe-dumbmerch:Staging
  
  build:
    stage: build
    image: docker:latest
    services:
      - docker:dind
    script:
      - docker buildx build --platform linux/amd64 -t $IMAGE_TAG .
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
      - docker:dind
    before_script:
      - mkdir -p ~/.docker
      - echo '{"insecure-registries":["'"$REGISTRY_URL"'"]}' > ~/.docker/config.json
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
      - echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa
    script:
      - git clone --depth 1 git@gitlab.com:rizaladlan/infrastructure.git /tmp/infrastructure
      - echo "$ANSIBLE_VAULT_PASS" > /tmp/infrastructure/ansible/.ansible_vault_pass
      - cd /tmp/infrastructure/ansible
      - ansible-playbook -i inventory.ini appserver.yml
    only:
      - Staging
  
  ```
  
- Following the guide 3: create `sonar-project.properties`
  
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
  
- s
