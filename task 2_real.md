<img width="975" height="386" alt="image" src="https://github.com/user-attachments/assets/4c0961bc-a2f4-4509-85bc-70231587ac76" /># Repository

## 1. Gitlab Repos
1.	Login to your gitlab account.
   <img width="975" height="411" alt="image" src="https://github.com/user-attachments/assets/9f6fb064-82af-4e00-9365-de728b17188b" />

   
2.	Click on “Projects” on the left side of the web, then click on “Create a project”, then click “Import project”, and choose “Repository by URL”.
<img width="975" height="402" alt="image" src="https://github.com/user-attachments/assets/41147d83-926b-4e41-8b80-39c5e4fae0e4" />
<img width="975" height="219" alt="image" src="https://github.com/user-attachments/assets/f5fa4b58-f7cc-4788-94d9-bd234e0fa168" />
<img width="975" height="222" alt="image" src="https://github.com/user-attachments/assets/d1032e6b-9d14-4221-a79f-f19a6a542d72" />


3.	In the “import repository by URL” page, fill the boxes with the necessary information. When done, click “Create project”.
<img width="975" height="821" alt="image" src="https://github.com/user-attachments/assets/59c72223-0b32-4d4f-81aa-52a25254bb12" />


4.	After forking the git, goes to your forked repo then click “Code > Branches” on the left side of the web.
<img width="975" height="335" alt="image" src="https://github.com/user-attachments/assets/71d6517f-0b8c-4271-bc3a-bfb589f6ca9e" />


5.	Click on “New branch” then gave the branch name “Staging” and “Production” (We’ll made two branches).
<img width="975" height="454" alt="image" src="https://github.com/user-attachments/assets/26e78735-2522-4b42-98a9-e870dbc3f7d6" />
<img width="975" height="383" alt="image" src="https://github.com/user-attachments/assets/acf6e96a-b3ff-493e-ae0e-86de2060ae0d" />

6.	You can see that now we have two branches on the repo.
<img width="447" height="502" alt="image" src="https://github.com/user-attachments/assets/8818e952-2850-4ca8-b368-c97a4c274815" />

## 2. Cloning Git to Local
1.	First, check if Git configured in your local (I’m using wsl). If not, then set them.
<img width="889" height="159" alt="image" src="https://github.com/user-attachments/assets/767d82ac-1013-4bf0-8fcb-db9f6099a0fd" />


2.	Go to your gitlab account, click your avatar > edit profile. Then on the left side of the web, click Access > SSH Keys
<img width="975" height="172" alt="image" src="https://github.com/user-attachments/assets/c551e01f-651f-488b-ae63-19690a3e387a" />
 

3.	Check your ssh directory, and copy the public key that already generated for this project.
<img width="914" height="258" alt="image" src="https://github.com/user-attachments/assets/af0d3704-301a-4cc4-9012-d3fd922a0663" />

 
4.	Back to gitlab, click “add new key” and paste it to the textbox. Then click “Add key” button.
<img width="664" height="874" alt="image" src="https://github.com/user-attachments/assets/420f7f13-1ea0-41e7-b9aa-beb09037c0e5" />

 
5.	Back to local terminal, tell SSH to use the key to connect to gitlab.
<img width="839" height="86" alt="image" src="https://github.com/user-attachments/assets/f18f1758-6f59-475b-b886-f35897ab6345" />


6.	Then, edit ssh config so it can be permanent. (`nano ~/.ssh/config`)
<img width="745" height="180" alt="image" src="https://github.com/user-attachments/assets/7a8082b5-6dc7-4612-b9c0-30c8e7d4c180" />
 

7.	After that, we checked it again with (`ssh -T git@gitlab.com`)
<img width="541" height="102" alt="image" src="https://github.com/user-attachments/assets/2a0ba315-8927-407d-8595-24a7a03bd7c5" />
 

8.	Then, back to the repos again, then click “Code > Clone with SSH”
<img width="975" height="213" alt="image" src="https://github.com/user-attachments/assets/8829c7d2-914d-4f5b-bce8-bf2ba4a461c1" />
 

9.	Back to local terminal, and run `git clone git@gitlab.com:rizaladlan/fe-dumbmerch.git` and git clone git@gitlab.com:rizaladlan/be-dumbmerch.git`.
<img width="975" height="383" alt="image" src="https://github.com/user-attachments/assets/d064d511-0002-4cf1-a411-acb2369df5e5" />

 
10.	After cloning complete, you can check the branches inside the repos with `git branch -a`.
<img width="731" height="500" alt="image" src="https://github.com/user-attachments/assets/a675086e-3ec2-4934-b825-597b701338ef" />

## 3. Creating the `.env` file and Push Git
1.	First, we’ll create .env for frontend. As per example, we’re going to create an .env file with “REACT_APP_BASEURL=https://api.staging.rizaladlan.studentdumbways.my.id/api/v1" for staging…
<img width="731" height="500" alt="image" src="https://github.com/user-attachments/assets/8f2092eb-4e5b-45f1-8e3e-cc2085b5d372" />

 
And "REACT_APP_BASEURL=https://api.<your_name>.studentdumbways.my.id/api/v1" for production.
<img width="975" height="431" alt="image" src="https://github.com/user-attachments/assets/36821ae3-df73-4632-a6fe-cdfc674d5c4c" />
 

2.	For backend, we’ll add .env file for DB integration (PostgresSQL). Both the SQL script are the same.
<img width="975" height="506" alt="image" src="https://github.com/user-attachments/assets/24667889-1ed0-4c5f-8bff-053f4bda4aaf" />
<img width="975" height="521" alt="image" src="https://github.com/user-attachments/assets/581d055c-09a6-4ed7-a72c-731ba256d2c5" />
 
 
We use port 5432 for PostgresSQL.

3.	Lastly, we’ll create a placeholder for CI/CD (task 6) that is gitlab-ci.yml. All the same for fe/be and Staging/Production (because they’re just placeholder.
<img width="975" height="468" alt="image" src="https://github.com/user-attachments/assets/5e692d3c-7ac2-4bbe-8d54-245c43da7f9c" />
<img width="975" height="249" alt="image" src="https://github.com/user-attachments/assets/7b8a7861-49b3-4e78-b47e-92c8f781dbb1" />
<img width="975" height="453" alt="image" src="https://github.com/user-attachments/assets/6029d4f3-9de5-4ded-a49a-81a344c036ba" />
<img width="975" height="443" alt="image" src="https://github.com/user-attachments/assets/907f0669-9b5e-44ca-be1e-a3a56ac38371" />
<img width="975" height="710" alt="image" src="https://github.com/user-attachments/assets/69a68755-74f0-4448-85f1-88bd9f41bca0" />

