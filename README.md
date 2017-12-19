# Rancher OS on KVM
This small project is designed to automate the installation and configuration of a Rancher OS worker node running under Linux KVM. It is the amalgamation of spread out documentation and several hours of trial and error.

# Usage
1. Checkout this repository
1. Copy the cloud-config.yml.template file as some other name, e.g. cloud-config-01.yml
1. Edit the '%' delimited values in the YAML file, e.g. %hostname%
1. Set the server ID to be run, e.g. `export SERVER_ID=1`
1. Start an Nginx docker container to host the YAML files (this was part of the script, however it would often fail to terminate / start the container so it was removed)
   ```
   docker run -d -p 808$SERVER_ID:80/tcp -v $(pwd)/cloud-config-0$SERVER_ID.yml:/usr/share/nginx/html/install-config nginx:alpine
   ```
1. Set the value of the hostname:port through which the cloud-init file can be accessed through the Nginx container, e.g. `export HTTP_HOST=192.168.1.1:808$SERVER_ID`
1. Run the *install.sh* script and pass it the ID number of the Rancher OS instance to launch, e.g. `./install.sh $SERVER_ID`
