#!/bin/sh
USERNAME="merlot"
echo $USERNAME
adduser --gecos "" --disabled-password $USERNAME
passwd -d $USERNAME
usermod -a -G sudo $USERNAME
echo "$USERNAME ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo

apt update
apt upgrade -y

echo "[user]" > /etc/wsl.conf
echo "default=$USERNAME" >> /etc/wsl.conf
echo "[boot]" >> /etc/wsl.conf
echo "systemd=true" >> /etc/wsl.conf

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
NODE_MAJOR=18
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install nodejs -y

npm install -g @angular/cli@latest

sudo apt install -y python3-pip

mkdir $MERLOT_WORKSPACE/mpo
git clone https://github.com/merlot-education/localdeployment.git $MERLOT_WORKSPACE/mpo/localdeployment
git -C $MERLOT_WORKSPACE/mpo/localdeployment checkout 1a29bbc11b9403ccd12a907e83a50c6e3f5631d2
mkdir $MERLOT_WORKSPACE/mpo/localdeployment/secrets
cp $MERLOT_WORKSPACE/mpo/localdeployment/secrets_example/git_auth_token.txt $MERLOT_WORKSPACE/mpo/localdeployment/secrets/git_auth_token.txt
cp $MERLOT_WORKSPACE/mpo/localdeployment/secrets_example/edc_ionos_secrets.txt $MERLOT_WORKSPACE/mpo/localdeployment/secrets/edc_ionos_secrets.txt
cp $MERLOT_WORKSPACE/mpo/localdeployment/secrets_example/s3_storage_secrets.txt $MERLOT_WORKSPACE/mpo/localdeployment/secrets/s3_storage_secrets.txt
git clone https://github.com/merlot-education/marketplace.git $MERLOT_WORKSPACE/mpo/marketplace
git -C $MERLOT_WORKSPACE/mpo/marketplace checkout 21575e23dc714e5ff71f85d870e17e1a87ce47b3
git clone https://github.com/merlot-education/aaam-orchestrator.git $MERLOT_WORKSPACE/mpo/aaam-orchestrator
git -C $MERLOT_WORKSPACE/mpo/aaam-orchestrator checkout c3e341ec8d5d69f4dba684569b47fd0e4468f4a4
git clone https://github.com/merlot-education/organisations-orchestrator.git $MERLOT_WORKSPACE/mpo/organisations-orchestrator
git -C $MERLOT_WORKSPACE/mpo/organisations-orchestrator checkout 1cf53e7d8c41893d0e915bed32ff07d1cd9d27e9
git clone https://github.com/merlot-education/serviceoffering-orchestrator.git $MERLOT_WORKSPACE/mpo/serviceoffering-orchestrator
git -C $MERLOT_WORKSPACE/mpo/serviceoffering-orchestrator checkout 2cb6dc8fe037da7908a8f87647ebfa19d05c0239
git clone https://github.com/merlot-education/contract-orchestrator.git $MERLOT_WORKSPACE/mpo/contract-orchestrator
git -C $MERLOT_WORKSPACE/mpo/contract-orchestrator checkout 2af2749344d3e7f89826c869d72abf00e6d0b47d
git clone https://github.com/merlot-education/merlot-edc.git $MERLOT_WORKSPACE/mpo/merlot-edc
git -C $MERLOT_WORKSPACE/mpo/merlot-edc checkout 554ff72a5417c5393e72e0fcdab9b8f585479c4d
chown -R $USERNAME:$USERNAME /home/$USERNAME

apt install zsh -y
git clone https://github.com/ohmyzsh/ohmyzsh.git /home/$USERNAME/.oh-my-zsh
cp /home/$USERNAME/.oh-my-zsh/templates/zshrc.zsh-template /home/$USERNAME/.zshrc

chsh -s $(which zsh) $USERNAME
echo 'eval $(keychain --eval id_rsa)' >> /home/$USERNAME/.zshrc

echo 'RUNNING=`ps aux | grep dockerd | grep -v grep`' >> /home/$USERNAME/.zshrc
echo 'if [ -z "$RUNNING" ]; then' >> /home/$USERNAME/.zshrc
echo '    sudo dockerd > /dev/null 2>&1 &' >> /home/$USERNAME/.zshrc
echo '    disown' >> /home/$USERNAME/.zshrc
echo 'fi' >> /home/$USERNAME/.zshrc

chown -R $USERNAME:$USERNAME /home/$USERNAME


dockerd > /dev/null 2>&1 &
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

sh -c 'echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf'
