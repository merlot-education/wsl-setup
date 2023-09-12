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
apt install -y ca-certificates curl gnupg

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

apt install -y podman
echo 'unqualified-search-registries = ["docker.io"]\n[[registry]]\nprefix = "docker.io"\nlocation = "docker.io"' >> /etc/containers/registries.conf
echo '[boot]\ncommand="podman system service --time=0 unix:///tmp/podman.sock &"' >> /etc/wsl.conf
pip3 install podman-compose

mkdir $MERLOT_WORKSPACE/mpo
git clone https://github.com/merlot-education/localdeployment.git $MERLOT_WORKSPACE/mpo/localdeployment
git clone https://github.com/merlot-education/marketplace.git $MERLOT_WORKSPACE/mpo/marketplace
git clone https://github.com/merlot-education/aaam-orchestrator.git $MERLOT_WORKSPACE/mpo/aaam-orchestrator
git clone https://github.com/merlot-education/organisations-orchestrator.git $MERLOT_WORKSPACE/mpo/organisations-orchestrator
git clone https://github.com/merlot-education/serviceoffering-orchestrator.git $MERLOT_WORKSPACE/mpo/serviceoffering-orchestrator
git clone https://github.com/merlot-education/contract-orchestrator.git $MERLOT_WORKSPACE/mpo/contract-orchestrator
git clone https://github.com/merlot-education/sd-creation-wizard-api.git $MERLOT_WORKSPACE/mpo/sd-creation-wizard-api
git clone https://github.com/merlot-education/gxfs-catalog-example-flows.git $MERLOT_WORKSPACE/mpo/gxfs-catalog-example-flows
git clone https://github.com/merlot-education/catalog-shapes.git $MERLOT_WORKSPACE/mpo/catalog-shapes
chown -R $USERNAME:$USERNAME /home/$USERNAME

apt install zsh -y
git clone https://github.com/ohmyzsh/ohmyzsh.git /home/$USERNAME/.oh-my-zsh
cp /home/$USERNAME/.oh-my-zsh/templates/zshrc.zsh-template /home/$USERNAME/.zshrc

chsh -s $(which zsh) $USERNAME
echo 'eval $(keychain --eval id_rsa)' >> /home/$USERNAME/.zshrc

chown -R $USERNAME:$USERNAME /home/$USERNAME

podman volume create portainer_data
podman system service --time=0 unix:///tmp/podman.sock &
podman run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /tmp/podman.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
