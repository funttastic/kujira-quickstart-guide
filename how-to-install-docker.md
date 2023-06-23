Official guide: https://docs.docker.com/get-docker/

You can try to official guide above or one of the procedures below.

The installation process for Docker varies based on the operating system. Here are some basic scripts to install Docker on Linux, MacOS, and Windows. Please note that these scripts may not work for all versions of these operating systems, and may require administrator or sudo privileges.

For Linux (Debian-based distributions):

```bash
#!/bin/bash

# Update existing packages
sudo apt-get update

# Install packages to allow apt to use a repository over HTTPS
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Setup the Docker stable repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index and install Docker Engine and Docker Compose
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose

# Verify installation
sudo docker run hello-world
```

For other Linux distributions, refer to Docker's official documentation for installation instructions.

For MacOS:

Docker on MacOS is usually installed as a GUI application from a DMG, not via a terminal script. However, you can install Docker using Homebrew, a package manager for MacOS:

```bash
#!/bin/bash

# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker
brew install --cask docker

# Start Docker
open /Applications/Docker.app

# Test installation
docker run hello-world
```

For Windows:

Docker installation on Windows is best done through the Docker Desktop installer, which is a GUI application. However, if you require a CLI-based installation, you can do so with Chocolatey, a package manager for Windows. Firstly, you need to install Chocolatey. This should be done from an administrator-privileged command prompt:

```powershell
# Install Chocolatey
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Install Docker Desktop
choco install docker-desktop

# Test installation
docker run hello-world
```

Please note, these scripts are for development environments and are not recommended for production environments. Always consult the official documentation for best practices. Additionally, ensure that Docker Desktop is set to run at startup after installation on Windows and MacOS.