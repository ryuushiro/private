# Task 1: Provisioning (Infrastructure as Code)
## Checking Terraform and Ansible Availability
-	Check Terraform version
 <img width="683" height="98" alt="image" src="https://github.com/user-attachments/assets/2861221b-453d-4214-9d10-3c62a2c35e20" /><br>

-	Check Ansible version
    <img width="975" height="209" alt="image" src="https://github.com/user-attachments/assets/ad53d565-aa38-432d-8ea5-265ecc632a36" />

## Create AWS access key
1. We can create a new IAM Account in AWS so that Terraform can access our EC2.
   
   - First, click on IAM > IAM users > Create user. On the first page (*Specify user details*) you can fill the *user name* as needed. For this one, I filled it with `terraform-user`. After that, click *Next*.
     
     <img width="975" height="289" alt="image" src="https://github.com/user-attachments/assets/27f1f019-6c85-432a-a6b6-4be7561d4ea3" />

   - In the *Set permissions* page, choose "*Attach policies directly*" and search for ***"AmazonEC2FullAccess"*** (this is chosen so that Terraform can manage EC2 instances on AWS). After that, click *Next* button and on the next page just click *Create account*.
     
     <img width="975" height="458" alt="image" src="https://github.com/user-attachments/assets/8c6fb2bf-a87c-4bd1-b40b-6be3e1c3060c" />
   
   - In the *IAM users* page, click on the new account that was just been made.
     
     <img width="975" height="321" alt="image" src="https://github.com/user-attachments/assets/f7718a57-2aa5-44a4-8be3-47850e4263af" />
   
   - Once inside, click “Create access key” (highlighted below).

     <img width="975" height="532" alt="image" src="https://github.com/user-attachments/assets/0e953cce-305d-4462-9e6e-d22095d8baef" />

   - On the “*Access key best practice & alternatives*” page, select the use case for ***Command Line Interface (CLI)*** and check the confirmation box below it, then click the *Next* button.
     
     <img width="975" height="709" alt="image" src="https://github.com/user-attachments/assets/9341d53b-fab9-44f8-ab1c-2099f3eb4666" />
   
   - On the next page, you could enter a description of the access key that you'll create, then click “*Create access key*”. In this case, I fill it with "*terraform-access*".
     
     <img width="975" height="238" alt="image" src="https://github.com/user-attachments/assets/409f73fb-d32b-4633-af52-eb8159461b39" />
   
   - Next, a page will appear informing us that the access key has been created. ***SAVE THE ACCESS KEY BY CLICKING "download .csv file"! BECAUSE THIS ACCESS KEY WILL ONLY BE DISPLAYED ONCE!*** Once done, click the "*Done*" button.
     
     <img width="975" height="470" alt="image" src="https://github.com/user-attachments/assets/ed4f78a8-a9ca-420d-b807-2e533e36e64e" />

2. We then setup AWS CLI V2. 
   
   - Because I'm using an `aarch64` device, I'll install that version.
     
     ```bash
     sudo apt-get update && sudo apt-get install curl unzip -y
     curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
     unzip awscliv2.zip
     sudo ./aws/install
     # Verify installation
     aws --version
     ```
     
     <img width="672" height="71" alt="image" src="https://github.com/user-attachments/assets/95060b32-5137-46a2-bf31-c0e307050394" />
   
   - After that, run `aws configure` to connect this device to AWS. Fill the information from the access key that just created.
     
     ```plaintext
     AWS Access Key ID: (Enter your Key ID)
     AWS Secret Access Key: (Enter your Secret Key)
     Default region name: ap-southeast-3 (Jakarta) or ap-southeast-1 (Singapore)
     Default output format: (just press enter)
     ```
   
   - Then, run `aws sts get-caller-identity` to verify.
     <img width="469" height="126" alt="image" src="https://github.com/user-attachments/assets/845d2598-ef3d-4b6e-87da-6c1384113875" />

3. Instead of creating the key pair manually in AWS Console, we generate it locally.
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_final_task -N ""
   ```
   <img width="949" height="48" alt="image" src="https://github.com/user-attachments/assets/040834bf-9884-48aa-919c-797a085e831a" />
   <img width="936" height="127" alt="image" src="https://github.com/user-attachments/assets/6c90e865-854e-4fce-8f2a-4158d336ddc8" />

## Create Cloudflare's API Token for DNS Records.

 > **Note on Architecture Strategy:** Even though these domains are officially listed as requirements for later tasks like Task 4 and Task 8, I am provisioning them declaratively here in Task 1. This ensures that as soon as the Gateway server spins up, the DNS routes are instantly mapped. This creates a clean, blocker-free pipeline for the subsequent Nginx reverse proxy and Docker Registry setups without needing to pause for manual DNS propagation later..

- First, login to https://dash.cloudflare.com
  <img width="1872" height="775" alt="image" src="https://github.com/user-attachments/assets/70a8881d-8208-472e-8992-3e0c37964e27" />

- On top left, click your avatar > "Profile"
  <img width="177" height="252" alt="image" src="https://github.com/user-attachments/assets/a1627adb-6fbe-4ce1-b8cf-d86507b3c5b0" />

- Then, on left panel, click API Tokens.
  <img width="225" height="273" alt="image" src="https://github.com/user-attachments/assets/88f8e130-d959-43fc-b64f-7b89dfbd8989" />

- On "User API Token", click the "+ Create Token" button
  <img width="1265" height="180" alt="image" src="https://github.com/user-attachments/assets/169ab2f4-5cc7-4620-b3d7-27dd93aebe74" />

- You'll be passed to API Token template page. Click "Create custom token"
  <img width="702" height="879" alt="image" src="https://github.com/user-attachments/assets/8acff0dd-b5ec-4d57-a9a1-434f11bd4001" />

- In the next page, write the name of the token then fill the permissions that we want. Because we only need to write DNS record and read the zone, we just gonna open the two. For Client IP Filtering, just leave it blank for now, you can edit it later with your servers' static IP after `terraform apply`. After you're done, click "Continue to summary".
  <img width="975" height="515" alt="image" src="https://github.com/user-attachments/assets/0a263e09-cc5f-431c-a3f2-67d12e5f1a81" />

- In the summary page, you can see your API token summary. If you're confident with it, then click "Create token"
  <img width="975" height="394" alt="image" src="https://github.com/user-attachments/assets/415010ae-b233-468e-9183-e6379d9f8ebd" />

- After token creation success, you'd be shown your API Token. IMMEDIATELY COPY THE TOKEN AND SAVE IT BECAUSE IT'LL ONLY SHOWN ONCE!
  <img width="738" height="269" alt="image" src="https://github.com/user-attachments/assets/033ae26a-cb5d-4148-a748-bdf900d32d4f" />

- After creating the API token, run these so that Terraform remember your token locally.

  ```bash
  export TF_VAR_cloudflare_api_token="your_actual_api_token_here"
  export TF_VAR_cloudflare_zone_id="your_actual_zone_id_here"
  ```
  <img width="1000" height="76" alt="image" src="https://github.com/user-attachments/assets/56e8c2a4-7fa3-41f3-8508-9666981c3299" />

  
- To get zone id token, go to overview page of the domain (studentdumbways.my.id), then scroll down until you found API ZONE ID on the bottom right of the page.
  <img width="672" height="866" alt="image" src="https://github.com/user-attachments/assets/e83dbc55-2a20-49ea-b19c-0dafbf6752b0" />


## Building with Terraform
Here are the structure of Terraform's directory:


~/infrastructure/<br>
└── terraform/<br>
-    ├── [providers.tf](https://github.com/ryuushiro/private/blob/main/files/task1/profiders.tf)<br>
-    ├── [variables.tf](https://github.com/ryuushiro/private/blob/main/files/task1/variables.tf)<br>
-    ├── [main.tf](https://github.com/ryuushiro/private/blob/main/files/task1/main.tf)<br>
-    ├── [dns.tf](https://github.com/ryuushiro/private/blob/main/files/task1/dns.tf)<br>
-    └── [outputs.tf](https://github.com/ryuushiro/private/blob/main/files/task1/outputs.tf) <br>

---

*   **`providers.tf`**: This file tells Terraform which external services it needs to talk to. In your case, it configures the connection to **AWS** (to create the servers) and **Cloudflare** (to manage your DNS records). It specifies the required versions for these plugins.
*   **`variables.tf`**: This file acts as a dictionary for all the customizable inputs your infrastructure needs. It defines variables like your Cloudflare API token, zone ID, the AWS region you want to deploy in, and potentially the size of the servers you want to use. Using variables makes your code reusable.
*   **`main.tf`**: This is the core of your infrastructure code. It contains the actual definitions of the cloud resources you want to create on AWS. This is where you declare your Gateway server, your three Appservers (k3s master and workers), and the Security Groups (firewall rules) that allow SSH and web traffic.
*   **`dns.tf`**: This file handles the **Cloudflare** resources. It defines the 8 `A` records required by Task 8 (e.g., `api.rizal.studentdumbways.my.id`, `staging.rizal...`, `monitoring...`) and points all of those subdomains to the public IP address of the newly created Gateway server. 
*   **`outputs.tf`**: After Terraform finishes building your infrastructure, this file tells Terraform what information to print out to the screen. For this project, it is configured to output the generated **Public and Private IP addresses** of your Gateway and Appservers so that you can easily use them in your Ansible inventory later.

<img width="825" height="86" alt="image" src="https://github.com/user-attachments/assets/378f12f6-c610-40c0-990a-4f8c4701128a" />

- run `terraform init` to initialize
  <img width="944" height="445" alt="image" src="https://github.com/user-attachments/assets/69694b00-37c0-4f26-a4fe-17d34837d0c6" />

- run these commands before applying
  <img width="975" height="178" alt="image" src="https://github.com/user-attachments/assets/54efc493-44c1-4619-8d36-fd761a21e66a" />

- run terraform apply to create the servers. Type “yes” when asked!
  <img width="975" height="217" alt="image" src="https://github.com/user-attachments/assets/c8d83cd3-7589-49ae-800b-87cc10aa0037" />

- When done, the outputs.tf gonna show you the IPs
  <img width="440" height="159" alt="image" src="https://github.com/user-attachments/assets/0a1227da-8ee3-4e9c-80d4-2f39501a6c84" />

- You can also check your cloudflare DNS records to see if the subdomains already registered.
  <img width="1296" height="735" alt="image" src="https://github.com/user-attachments/assets/00d0e590-8d67-497a-bdde-d7015f852b94" />





