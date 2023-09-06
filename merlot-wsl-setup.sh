#!/bin/sh
USERNAME="$(whoami.exe | sed -E s/'^.+\\([^\\]*)$'/'\1'/ | sed $'s/\r//')"
adduser --gecos "" --disabled-password $USERNAME
passwd -d $USERNAME
usermod -a -G sudo $USERNAME
echo "$USERNAME ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo

apt update
apt upgrade -y

echo "[user]" > /etc/wsl.conf
echo "default=$USERNAME" >> /etc/wsl.conf

apt install -y openjdk-17-jdk openjdk-17-jre maven
apt install -y gnupg2 software-properties-common git git-lfs keychain

apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 

usermod -a -G docker $USERNAME

echo 'eval $(keychain --eval id_rsa)' >> /home/$USERNAME/.bashrc

echo 'RUNNING=`ps aux | grep dockerd | grep -v grep`' >> /home/$USERNAME/.bashrc
echo 'if [ -z "$RUNNING" ]; then' >> /home/$USERNAME/.bashrc
echo '    sudo dockerd > /dev/null 2>&1 &' >> /home/$USERNAME/.bashrc
echo '    disown' >> /home/$USERNAME/.bashrc
echo 'fi' >> /home/$USERNAME/.bashrc

cd /home/$USERNAME
mkdir workspace
export MERLOT_WORKSPACE=/home/$USERNAME/workspace

apt remove -y nodejs
apt remove -y npm
apt autoremove -y
NODE_MAJOR=16
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install nodejs -y

npm install -g @angular/cli@latest

mkdir $MERLOT_WORKSPACE/mpo
git clone https://github.com/merlot-education/localdeployment.git $MERLOT_WORKSPACE/mpo/localdeployment
git clone https://github.com/merlot-education/marketplace.git $MERLOT_WORKSPACE/mpo/marketplace
git clone https://github.com/merlot-education/aaam-orchestrator.git $MERLOT_WORKSPACE/mpo/aaam-orchestrator
git clone https://github.com/merlot-education/organisations-orchestrator.git $MERLOT_WORKSPACE/mpo/organisations-orchestrator
git clone https://github.com/merlot-education/serviceoffering-orchestrator.git $MERLOT_WORKSPACE/mpo/serviceoffering-orchestrator
git clone https://github.com/merlot-education/contract-orchestrator.git $MERLOT_WORKSPACE/mpo/contract-orchestrator
git clone https://github.com/merlot-education/sd-creation-wizard-api.git $MERLOT_WORKSPACE/mpo/sd-creation-wizard-api
chown -R $USERNAME:$USERNAME /home/$USERNAME