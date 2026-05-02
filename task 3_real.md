# Task 3: Servers

## Configure the Servers with Ansible
Here are the structure of Ansible's directory:

~/infrastructure/<br>
└── ansible/<br>
    ├── group_vars/<br>
     │   └── all.yml<br>
    ├── ansible.cfg<br>
    ├── inventory.ini<br>
    ├── site.yml<br>
     └──  common.yml<br>
     
---

- site.yml: The master playbook that imports all other playbooks.
- common.yml: Contains tasks that must run on all servers (for Task 3: users, SSH ports, UFW).
- ansible.cfg :  Tells Ansible to use the ubuntu user and your project's private key (id_rsa_final_task) for the initial connection.
- inventory.ini : Contains the list of your servers' Elastic IPs so Ansible knows who to talk to.
- group_vars/all.yml :  Stores the values variables used in Ansible.

---

-	After creating all of that, we can ping the servers. `ansible all -m ping`

-	s
-	s
-	

