#!/bin/bash -xe

# Send the output to the console logs and at /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    # Update packages
    apt-get update && sudo apt-get upgrade -y

    # Install Nginx
    apt-get install -y nginx
    #sudo sed -i 's/# server_names_hash_bucket_size 64/server_names_hash_bucket_size 128/g' /etc/nginx/nginx.conf  
    #sudo sed -i '24s/\#//g' /etc/nginx/nginx.conf
    
    # Increase the server_names_hash_bucket_size to 128 in order to accept long domain names
    echo "server_names_hash_bucket_size 128;" | sudo tee /etc/nginx/conf.d/server_names_hash_bucket_size.conf

    # Add the NodeSource APT repository for Node 12
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash

    # Install Node.js && npm
    apt-get install -y nodejs
    npm install npm@latest -g

    # Install Ghost-CLI
    npm install ghost-cli@latest -g

    # Give permission to ubuntu user, create directory 
    chown -R ubuntu:ubuntu /var/www/
    sudo -u ubuntu mkdir -p /var/www/blog && cd /var/www/blog

    # Install Ghost, cannot be run via root (user data default)
    sudo -u ubuntu ghost install \
        --url http://${url} \
        --admin-url http://${admin_url}/admin \
        --db mysql \
        --dbhost ${endpoint} \
        --dbuser ${username}\
        --dbpass ${password} \
        --dbname ${database} \
        --process systemd \
        --no-prompt

    ghost update --force
    sudo service nginx restart && sudo service nginx reload 
