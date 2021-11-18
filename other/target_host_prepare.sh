#!/usr/bin/env bash

help="Usage: 
    ./this_script IP"
eval "$(docopts -A args -h "$help" : "$@")"
source ~/.colors
PORT=22
IP=${args[IP]}

HOSTS="
\n
10.30.72.10   fedn-base\n
10.30.72.11   fedn-reducer\n
10.30.72.12   fedn-combiner\n
10.30.72.13   fedn-client1\n
10.30.72.14   fedn-client2\n
10.30.72.15   fedn-client3\n
10.30.72.16   fedn-client4\n
10.30.72.17   fedn-client5\n
10.30.72.18   fedn-client6\n
"

SSH_KEY=`sudo cat ~/.ssh/id_rsa.pub`

ssh -i /tmp/id_rsa -oStrictHostKeyChecking=no -p$PORT \
        ubuntu@$IP "bash -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
                    echo $SSH_KEY | tee -a ~/.ssh/authorized_keys > /dev/null'"

echo -e $HOSTS | ssh -oStrictHostKeyChecking=no -p$PORT ubuntu@$IP "sudo bash -c 'cat | tee -a /etc/hosts > /dev/null'"

echo -e "\n${grn}Ruuning batch commands${noc}"
scp -P$PORT -oStrictHostKeyChecking=no target_host_ntp_patch.patch ubuntu@$IP:/tmp
ssh -oStrictHostKeyChecking=no -p$PORT \
        ubuntu@$IP "sudo bash -c 'apt update && apt-get install ntp -yqq && 
                patch -u /etc/ntp.conf -i /tmp/target_host_ntp_patch.patch && \
                sudo service ntp restart && \
                apt install conntrack socat ca-certificates curl gnupg lsb-release -yqq && \
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null && \
                echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu bionic stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
                apt-get update && \
                apt-get install -yqq docker-ce docker-ce-cli containerd.io && \
                mkdir -p /etc/docker && \
                systemctl enable docker && \
                systemctl daemon-reload && \
                systemctl restart docker && \
                curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose && \
                chmod +x /usr/local/bin/docker-compose
                '"


# docker build /home/ubuntu/examples/mnist-pytorch/ -t mnist-client:latest
 
# sudo docker-compose -f docker-compose.yaml -f extra-hosts.yaml up --build