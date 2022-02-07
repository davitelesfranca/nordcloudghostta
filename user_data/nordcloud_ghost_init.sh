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

   #Install vector for observability
   cd
   curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | bash -s -- -y 

   sudo cp .vector/bin/vector /usr/local/bin/

   cd .vector && mkdir lib && cd

   rm -rf .vector/config/vector.toml

   cat << EOF > .vector/config/vector.toml

    # Set global options
    data_dir = "~.vector/lib/"

    # Ingest data by tailing one or more files
    [sources.nginx_logs]
    type         = "file"
    include      = ["/var/log/nginx/*.log"]    # supports globbing
    ignore_older = 86400                         # 1 day

    # Structure and parse the data
    [transforms.nginx_parser]
    inputs       = ["nginx_logs"]
    type         = "regex_parser"                # fast/powerful regex
    patterns      = ['^(?P<host>[w.]+) - (?P<user>[w]+) (?P<bytes_in>[d]+) [(?P<timestamp>.*)] "(?P<method>[w]+) (?P<path>.*)" (?P<status>[d]+) (?P<bytes_out>[d]+)$']

    # Sample the data to save on cost
    [transforms.nginx_sample]
    inputs       = ["nginx_parser"]
    type         = "sample"
    rate         = 50                            # only keep 50%

    # Send structured data to a cost-effective long-term storage
    [sinks.s3_nginx_archives]
    inputs       = ["nginx_parser"]             # don't sample for S3
    type         = "aws_s3"
    region       = "us-east-1"
    bucket       = "ob-nginx-ghost-nordcloud"
    key_prefix   = "nginx-date=%Y-%m-%d"               # daily partitions, hive friendly format
    compression  = "gzip"                        # compress final objects
    encoding     = "ndjson"                      # new line delimited JSON
    [sinks.s3_archives.batch]
    max_bytes   = 10000000                      # 10mb uncompressed

    # Ingest
    [sources.nginx_logs_cwm]
    type = "file"
    include = ["/var/log/nginx/*.log"]
    start_at_beginning = true

    # Structure and parse the data
    [transforms.nginx_cwm_regex_parser]
    inputs = ["nginx_logs_cwm"]
    type = "regex_parser"
    patterns = ['^(?P<host>[\w\.]+) - (?P<user>[\w-]+) \[(?P<timestamp>.*)\] "(?P<method>[\w]+) (?P<path>.*)" (?P<status>[\d]+) (?P<bytes_out>[\d]+)$']

    # Transform into metrics
    [transforms.nginx_cwm_to_metric]
    inputs = ["nginx_cwm_regex_parser"]
    type = "log_to_metric"

    [[transforms.nginx_cwm_to_metric.metrics]]
    type = "counter"
    increment_by_value = true
    field = "bytes_out"
    tags = {method = "{{method}}", status = "{{status}}"}

    # Output data
    [sinks.nginx_cwm_console_metrics]
    inputs = ["nginx_cwm_to_metric"]
    type = "console"
    encoding = "json"

    [sinks.nginx_cwm_console_logs]
    inputs = ["regex_parser"]
    type = "console"
    encoding = "json"

    [sinks.nginx_cloudwatch]
    inputs = ["log_to_metric"]
    type = "aws_cloudwatch_metrics"
    namespace = "nginxghost"
    endpoint = "http://localhost:4566"

    ##############################################################
    ##############################################################

    # Ingest data by tailing one or more files
    [sources.ghost_logs]
    type         = "file"
    include      = ["/var/www/content/logs/*.log"]    # supports globbing
    ignore_older = 86400                         # 1 day

    # Structure and parse the data
    [transforms.ghost_parser]
    inputs       = ["ghost_logs"]
    type         = "regex_parser"                # fast/powerful regex
    patterns      = ['^(?P<host>[w.]+) - (?P<user>[w]+) (?P<bytes_in>[d]+) [(?P<timestamp>.*)] "(?P<method>[w]+) (?P<path>.*)" (?P<status>[d]+) (?P<bytes_out>[d]+)$']

    # Sample the data to save on cost
    [transforms.ghost_sample]
    inputs       = ["ghost_parser"]
    type         = "sample"
    rate         = 50                            # only keep 50%

    # Send structured data to a cost-effective long-term storage
    [sinks.s3_archives]
    inputs       = ["ghost_parser"]             # don't sample for S3
    type         = "aws_s3"
    region       = "us-east-1"
    bucket       = "ob-app-ghost-nordcloud"
    key_prefix   = "ghost-app-date=%Y-%m-%d"               # daily partitions, hive friendly format
    compression  = "gzip"                        # compress final objects
    encoding     = "ndjson"                      # new line delimited JSON
    [sinks.s3_archives.batch]
    max_bytes   = 10000000                      # 10mb uncompressed

    # Ingest
    [sources.ghost_logs_cwm]
    type = "file"
    include = ["/var/www/blog/content/logs/*.log"]
    start_at_beginning = true

    # Structure and parse the data
    [transforms.ghost_cwm_regex_parser]
    inputs = ["ghost_logs_cwm"]
    type = "regex_parser"
    patterns = ['^(?P<host>[\w\.]+) - (?P<user>[\w-]+) \[(?P<timestamp>.*)\] "(?P<method>[\w]+) (?P<path>.*)" (?P<status>[\d]+) (?P<bytes_out>[\d]+)$']

    # Transform into metrics
    [transforms.ghost_cwm_to_metric]
    inputs = ["ghost_cwm_regex_parser"]
    type = "log_to_metric"

    [[transforms.ghost_cwm_to_metric.metrics]]
    type = "counter"
    increment_by_value = true
    field = "bytes_out"
    tags = {method = "{{method}}", status = "{{status}}"}

    # Output data
    [sinks.ghost_cwm_console_metrics]
    inputs = ["ghost_cwm_to_metric"]
    type = "console"
    encoding = "json"

    [sinks.ghost_cwm_console_logs]
    inputs = ["ghost_cwm_regex_parser"]
    type = "console"
    encoding = "json"

    [sinks.ghost_cloudwatch]
    inputs = ["ghost_cwm_to_metric"]
    type = "aws_cloudwatch_metrics"
    namespace = "appghost"
    endpoint = "http://localhost:4566"
       
    EOF
