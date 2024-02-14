#!/bin/sh
whoami.exe
USERNAME="merlot" # "$(whoami.exe | sed -E s/'^.+\\([^\\]*)$'/'\1'/ | sed $'s/\r//')"
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
git -C $MERLOT_WORKSPACE/mpo/localdeployment checkout f9fe37fec2c5b5e51be42faadb77313216da8513
mkdir $MERLOT_WORKSPACE/mpo/localdeployment/secrets
touch $MERLOT_WORKSPACE/mpo/localdeployment/secrets/git_auth_token.txt
sudo mkdir $MERLOT_WORKSPACE/mpo/localdeployment/docker_data
sudo mkdir $MERLOT_WORKSPACE/mpo/localdeployment/docker_data/neo4j
sudo mkdir $MERLOT_WORKSPACE/mpo/localdeployment/docker_data/neo4j/plugins
sudo wget https://github.com/neo4j-labs/neosemantics/releases/download/4.4.0.3/neosemantics-4.4.0.3.jar -O $MERLOT_WORKSPACE/mpo/localdeployment/docker_data/neo4j/plugins/n10s.jar
git clone https://github.com/merlot-education/marketplace.git $MERLOT_WORKSPACE/mpo/marketplace
git -C $MERLOT_WORKSPACE/mpo/marketplace checkout 34088ca700ae02edcffef4e00904346c3977fa4b
git clone https://github.com/merlot-education/aaam-orchestrator.git $MERLOT_WORKSPACE/mpo/aaam-orchestrator
git -C $MERLOT_WORKSPACE/mpo/aaam-orchestrator checkout 9ec1ca7195c485402a3e9c4e7453fc81b58d5a9e
git clone https://github.com/merlot-education/organisations-orchestrator.git $MERLOT_WORKSPACE/mpo/organisations-orchestrator
git -C $MERLOT_WORKSPACE/mpo/organisations-orchestrator checkout 30c258a0d4115fa9bc26a7953c15f0cf8fa7fca2
git clone https://github.com/merlot-education/serviceoffering-orchestrator.git $MERLOT_WORKSPACE/mpo/serviceoffering-orchestrator
git -C $MERLOT_WORKSPACE/mpo/serviceoffering-orchestrator checkout d086300723c19937c6af1cda07802b6681a93e30
git clone https://github.com/merlot-education/contract-orchestrator.git $MERLOT_WORKSPACE/mpo/contract-orchestrator
git -C $MERLOT_WORKSPACE/mpo/contract-orchestrator checkout 2fc741fc6636e744f06f27baa7e22789a5c9641f
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

wsl.exe -d wsl-vpnkit --cd /app cat /app/wsl-vpnkit.service | tee /etc/systemd/system/wsl-vpnkit.service
# systemctl enable wsl-vpnkit

sh -c 'echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf'
