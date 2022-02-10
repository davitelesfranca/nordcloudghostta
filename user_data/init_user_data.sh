#!/bin/bash

# Send the output to the console logs and at /var/log/user-data.log
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
    apt-get update && apt-get upgrade -y
    apt-get install -y unzip

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    chmod +x ./aws/install
    bash ./aws/install

    OBJPATH="s3://${ghost_bucket}/${bucket_s3_object}";
    echo ${ghost_bucket}
    echo ${bucket_s3_object} 
    echo $OBJPATH
    echo "getting parameters"
    echo "${url} ${admin_url} ${endpoint} ${username} ${password} ${database} ${nginx_bucket} ${ghost_bucket}" 

    aws s3 --debug cp $OBJPATH ./
    chmod +x nordcloud_ghost_init.sh
    bash nordcloud_ghost_init.sh ${url} ${admin_url} ${endpoint} ${username} ${password} ${database} ${nginx_bucket} ${ghost_bucket}