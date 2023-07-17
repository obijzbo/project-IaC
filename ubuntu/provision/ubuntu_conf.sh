#!/bin/bash

# Create the user
sudo useradd -m -s /bin/bash devops

# Set the password
echo "devops:123" | sudo chpasswd

# Add user to the sudo group
sudo usermod -aG sudo devops

# Update package lists
sudo apt-get update

# Remove existing Docker packages
sudo apt-get remove docker docker-engine docker.io containerd runc -y

# Install required packages for Docker installation
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

# Update package information with the new Docker repository
sudo apt-get update

# Install Docker CE (Community Edition)
sudo apt-get install docker-ce -y

# Check the status of Docker service
sudo systemctl status docker

# Install Ansible
sudo apt-add-repository ppa:ansible/ansible

sudo apt-get update

sudo apt-get install ansible -y

# Install default JRE and JDK
sudo apt-get install -y default-jre default-jdk

# Check Java versions
java -version
javac -version

# Configure default Java version
sudo update-alternatives --config java

# Set JAVA_HOME environment variable
echo "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" | sudo tee -a /etc/environment
source /etc/environment
echo $JAVA_HOME
java -version

# Install Maven
wget https://mirrors.estointernet.in/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -xvf apache-maven-3.6.3-bin.tar.gz
sudo mv apache-maven-3.6.3 /opt/
echo 'export PATH="/opt/apache-maven-3.6.3/bin:$PATH"' >> ~/.profile
source ~/.profile
mvn -version

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y

#Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

# Allow Jenkins and SSH through firewall
sudo ufw allow 8080
sudo ufw allow OpenSSH
echo "y" | sudo ufw enable

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

# Allow Jenkins and SSH through firewall
sudo ufw allow 8080
sudo ufw allow OpenSSH
echo "y" | sudo ufw enable

# Set the password
echo "jenkins:123" | sudo chpasswd

# Retrieve Jenkins Initial Admin Password
INITIAL_ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Display Initial Admin Password
echo "Initial Admin Password: $INITIAL_ADMIN_PASSWORD"

# Download Jenkins CLI
sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar -P /var/lib/jenkins

su - jenkins

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:INITIAL_ADMIN_PASSWORD create-user --username jenkins --password 123 --fullname "nahiyan mubashshir" --email nahiyanmubashshir@gmail.com


# Restart the VM for changes to take effect
sudo reboot
