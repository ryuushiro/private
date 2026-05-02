# Task 3: Servers

## Configure the Servers with Ansible
Here are the structure of Ansible's directory:

~/infrastructure/<br>
└── ansible/<br>
    ├── group_vars/<br>   
     │   └── /all/all.yml<br>
     │   └── /all/vault.yml<br>
    ├── ansible.cfg<br>
    ├── inventory.ini<br>
    ├── site.yml<br>
     └──  common.yml<br>
     
---

- site.yml: The master playbook that imports all other playbooks.
- common.yml: Contains tasks that must run on all servers (for Task 3: users, SSH ports, UFW).
- ansible.cfg :  Tells Ansible to use the ubuntu user and your project's private key (id_rsa_final_task) for the initial connection.
- inventory.ini : Contains the list of your servers' Elastic IPs so Ansible knows who to talk to.
- group_vars/all/all.yml :  Stores the values variables used in Ansible.
- group_vars/all/vault.yml : storing password via Ansible Vault

---

- Before creating the common.yml, create a secret password with ansible vault.
- First, run `ansible-vault create ~/infrastructure/ansible/group_vars/all/vault.yml`. After pressed enter, you'll be asked to put a new password (master key) for the vault.
  <img width="849" height="80" alt="image" src="https://github.com/user-attachments/assets/29e712af-6e27-4f66-abb7-d2162d05fdd2" />

- After that, you can input this to the file.

  ```ini                                       
    vault_ssh_password: inputyourpassword
    vault_sudo_password: inputyourpassword
    vault_user_password: inputyourpassword
  ```

  <img width="944" height="90" alt="image" src="https://github.com/user-attachments/assets/1024cdd5-9a5a-4753-9bf9-4ffcc7b78451" />

- With that, you can just call the password in all.yml with "{{ vault_ssh_password }}", and "{{ vault_sudo_password }}".
  <img width="609" height="211" alt="image" src="https://github.com/user-attachments/assets/a792d7ac-4539-4b2a-95db-4dbf4c04fb04" />

- Next, we can create the file with our master key for the vault inside a new one (named with dot in front of it so it'll not uploaded to git).
  <img width="922" height="46" alt="image" src="https://github.com/user-attachments/assets/a8a6a659-8b01-4636-92f6-38724d17b793" />

- Then edit ansible.cfg, add "vault_password_file = 'youransiblepasswordfile'"
  <img width="465" height="141" alt="image" src="https://github.com/user-attachments/assets/a7f00e8f-08c6-4311-bd80-10d165c2b42f" />
    
- After creating all of that, we can ping the servers. `ansible all -m ping`
  <img width="489" height="493" alt="image" src="https://github.com/user-attachments/assets/646f38d8-061c-4d03-a3ec-62806bccf368" />

- If all outputs are success, then we can finally run the ansible with `ansible-playbook site.yml`. With this, we perform **PLEASE EDIT LATER!** :
  <img width="1254" height="824" alt="image" src="https://github.com/user-attachments/assets/82146b06-7ebb-4296-9f5d-f910ea13dc18" />

  <img width="714" height="757" alt="image" src="https://github.com/user-attachments/assets/9fe172b0-f742-4cbe-b578-7c78297f7f04" />




-	s
-	s



