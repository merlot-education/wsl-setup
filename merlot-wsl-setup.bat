@echo off
set wslname=merlot-test
echo This script will create a WSL instance called %wslname%
mkdir D:\wsl\%wslname%
copy .\merlot-wsl-setup.bat D:\wsl\%wslname%\
copy .\merlot-wsl-setup.sh D:\wsl\%wslname%\
cd /D D:\wsl\%wslname%
echo "Downloading Ubuntu image"
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz -OutFile ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz"
echo "Downloading wsl-vpnkit image"
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://github.com/sakai135/wsl-vpnkit/releases/download/v0.4.1/wsl-vpnkit.tar.gz -OutFile wsl-vpnkit.tar.gz"
echo "Creating wsl-vpnkit instance"
wsl --import wsl-vpnkit --version 2 .\wsl-vpnkit wsl-vpnkit.tar.gz
echo "Creating Ubuntu WSL instance"
wsl.exe --import %wslname% D:\wsl\%wslname% .\ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz
echo "Copying Ubuntu WSL script to instance"
powershell -Command "Copy-Item -Path .\merlot-wsl-setup.sh -Destination \\wsl.localhost\%wslname%\root\merlot-wsl-setup.sh"
echo "Running Ubuntu WSL script on instance"
wsl.exe -d %wslname% bash -c "chmod +x /root/merlot-wsl-setup.sh"
wsl.exe -d %wslname% -e /root/merlot-wsl-setup.sh
wsl.exe --terminate %wslname%
echo "All done!"
pause
