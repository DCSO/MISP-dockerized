#/bin/bash
ansible-playbook -i "localhost," -c local -t server /etc/ansible/playbooks/robot-playbook/site.yml
ansible-playbook -i "localhost," -c local -t database /etc/ansible/playbooks/robot-playbook/site.yml
ansible-playbook -i "localhost," -c local -t proxy /etc/ansible/playbooks/robot-playbook/site.yml
