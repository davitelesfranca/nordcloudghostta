#!/bin/bash -xe

# Send the output to the console logs and at /var/log/user-data.log
exec > >(tee /var/log/ghost-script.log | logger -t ghost-script -s 2>/dev/console) 2>&1
    url=$1;
    admin_url=$2;
    endpoint=$3;
    username=$4;
    password=$5;
    database=$6;
    nginx_bucket=$7;
    ghost_bucket=$8;

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
    sudo -u ubuntu ghost install --url http://$url --admin-url http://$admin_url/admin --db mysql --dbhost $endpoint --dbuser $username --dbpass $password --dbname $database --process systemd --no-prompt
    
    sudo -u ubuntu ghost update --force
    
	  #Install vector for observability
    apt-get install -y net-tools 
    export HOME=/var/local/observability/

    chown -R ubuntu:ubuntu /var/local/
    sudo -u ubuntu mkdir -p /var/local/observability && cd /var/local/observability
    sudo -u ubuntu curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | bash -s -- -y 
    chown -R ubuntu:ubuntu /var/local/observability/.vector

    cp /var/local/observability/.vector/bin/vector /usr/local/bin/

    rm -rf /var/local/observability/.vector/config/vector.toml
    cd /var/local/observability/.vector/config/ && sudo -u ubuntu mkdir -p lib
	  service nginx restart && service nginx reload

	  echo "# Set global options" >> /var/local/observability/.vector/config/vector.toml
    echo "data_dir = \"/var/local/observability/.vector/config/lib/\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Ingest data by tailing one or more files" >> /var/local/observability/.vector/config/vector.toml
    echo "[sources.nginx_logs]" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"file\"" >> /var/local/observability/.vector/config/vector.toml
    echo "include      = [\"/var/log/nginx/*.log\"]    # supports globbing" >> /var/local/observability/.vector/config/vector.toml
    echo "ignore_older = 86400                         # 1 day" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Structure and parse the data" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.nginx_parser]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs       = [\"nginx_logs\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"regex_parser\"                # fast/powerful regex" >> /var/local/observability/.vector/config/vector.toml
    echo "patterns      = ['^(?P<host>[w.]+) - (?P<user>[w]+) (?P<bytes_in>[d]+) [(?P<timestamp>.*)] \"(?P<method>[w]+) (?P<path>.*)\" (?P<status>[d]+) (?P<bytes_out>[d]+)$']" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Sample the data to save on cost" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.nginx_sample]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs       = [\"nginx_parser\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"sample\"" >> /var/local/observability/.vector/config/vector.toml
    echo "rate         = 50                            # only keep 50%" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Send structured data to a cost-effective long-term storage" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.s3_nginx_archives]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs       = [\"nginx_parser\"]             # don't sample for S3" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"aws_s3\"" >> /var/local/observability/.vector/config/vector.toml
    echo "region       = \"us-east-1\"" >> /var/local/observability/.vector/config/vector.toml
    echo "bucket       = \"$nginx_bucket\"" >> /var/local/observability/.vector/config/vector.toml
    echo "key_prefix   = \"nginx-date=%Y-%m-%d\"               # daily partitions, hive friendly format" >> /var/local/observability/.vector/config/vector.toml
    echo "compression  = \"gzip\"                        # compress final objects" >> /var/local/observability/.vector/config/vector.toml
    echo "encoding     = \"ndjson\"                      # new line delimited JSON" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Ingest" >> /var/local/observability/.vector/config/vector.toml
    echo "[sources.nginx_logs_cwm]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"file\"" >> /var/local/observability/.vector/config/vector.toml
    echo "include = [\"/var/log/nginx/*.log\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "start_at_beginning = true" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Structure and parse the data" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.nginx_cwm_regex_parser]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"nginx_logs_cwm\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"regex_parser\"" >> /var/local/observability/.vector/config/vector.toml
    echo "patterns = ['^(?P<host>[\w\.]+) - (?P<user>[\w-]+) \[(?P<timestamp>.*)\] \"(?P<method>[\w]+) (?P<path>.*)\" (?P<status>[\d]+) (?P<bytes_out>[\d]+)$']" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Transform into metrics" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.nginx_cwm_to_metric]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"nginx_cwm_regex_parser\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"log_to_metric\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[[transforms.nginx_cwm_to_metric.metrics]]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"counter\"" >> /var/local/observability/.vector/config/vector.toml
    echo "increment_by_value = true" >> /var/local/observability/.vector/config/vector.toml
    echo "field = \"bytes_out\"" >> /var/local/observability/.vector/config/vector.toml
    echo "tags = {method = \"{{method}}\", status = \"{{status}}\"}" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Output data" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.nginx_cwm_console_metrics]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"nginx_cwm_to_metric\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"console\"" >> /var/local/observability/.vector/config/vector.toml
    echo "encoding = \"json\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.nginx_cwm_console_logs]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"nginx_parser\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"console\"" >> /var/local/observability/.vector/config/vector.toml
    echo "encoding = \"json\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.nginx_cloudwatch]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"nginx_cwm_to_metric\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"aws_cloudwatch_metrics\"" >> /var/local/observability/.vector/config/vector.toml
    echo "namespace = \"nginxghost\"" >> /var/local/observability/.vector/config/vector.toml
    echo "endpoint = \"http://localhost:4566\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "##############################################################" >> /var/local/observability/.vector/config/vector.toml
    echo "##############################################################" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Ingest data by tailing one or more files" >> /var/local/observability/.vector/config/vector.toml
    echo "[sources.ghost_logs]" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"file\"" >> /var/local/observability/.vector/config/vector.toml
    echo "include      = [\"/var/www/content/logs/*.log\"]    # supports globbing" >> /var/local/observability/.vector/config/vector.toml
    echo "ignore_older = 86400                         # 1 day" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Structure and parse the data" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.ghost_parser]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs       = [\"ghost_logs\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"regex_parser\"                # fast/powerful regex" >> /var/local/observability/.vector/config/vector.toml
    echo "patterns      = ['^(?P<host>[w.]+) - (?P<user>[w]+) (?P<bytes_in>[d]+) [(?P<timestamp>.*)] \"(?P<method>[w]+) (?P<path>.*)\" (?P<status>[d]+) (?P<bytes_out>[d]+)$']" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Sample the data to save on cost" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.ghost_sample]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs       = [\"ghost_parser\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"sample\"" >> /var/local/observability/.vector/config/vector.toml
    echo "rate         = 50                            # only keep 50%" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Send structured data to a cost-effective long-term storage" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.s3_archives]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs       = [\"ghost_parser\"]             # don't sample for S3" >> /var/local/observability/.vector/config/vector.toml
    echo "type         = \"aws_s3\"" >> /var/local/observability/.vector/config/vector.toml
    echo "region       = \"us-east-1\"" >> /var/local/observability/.vector/config/vector.toml
    echo "bucket       = \"$ghost_bucket\"" >> /var/local/observability/.vector/config/vector.toml
    echo "key_prefix   = \"ghost-app-date=%Y-%m-%d\"               # daily partitions, hive friendly format" >> /var/local/observability/.vector/config/vector.toml
    echo "compression  = \"gzip\"                        # compress final objects" >> /var/local/observability/.vector/config/vector.toml
    echo "encoding     = \"ndjson\"                      # new line delimited JSON" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.s3_archives.batch]" >> /var/local/observability/.vector/config/vector.toml
    echo "max_bytes   = 10000000                      # 10mb uncompressed" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Ingest" >> /var/local/observability/.vector/config/vector.toml
    echo "[sources.ghost_logs_cwm]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"file\"" >> /var/local/observability/.vector/config/vector.toml
    echo "include = [\"/var/www/blog/content/logs/*.log\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "start_at_beginning = true" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Structure and parse the data" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.ghost_cwm_regex_parser]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"ghost_logs_cwm\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"regex_parser\"" >> /var/local/observability/.vector/config/vector.toml
    echo "patterns = ['^(?P<host>[\w\.]+) - (?P<user>[\w-]+) \[(?P<timestamp>.*)\] \"(?P<method>[\w]+) (?P<path>.*)\" (?P<status>[\d]+) (?P<bytes_out>[\d]+)$']" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Transform into metrics" >> /var/local/observability/.vector/config/vector.toml
    echo "[transforms.ghost_cwm_to_metric]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"ghost_cwm_regex_parser\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"log_to_metric\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[[transforms.ghost_cwm_to_metric.metrics]]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"counter\"" >> /var/local/observability/.vector/config/vector.toml
    echo "increment_by_value = true" >> /var/local/observability/.vector/config/vector.toml
    echo "field = \"bytes_out\"" >> /var/local/observability/.vector/config/vector.toml
    echo "tags = {method = \"{{method}}\", status = \"{{status}}\"}" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "# Output data" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.ghost_cwm_console_metrics]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"ghost_cwm_to_metric\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"console\"" >> /var/local/observability/.vector/config/vector.toml
    echo "encoding = \"json\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.ghost_cwm_console_logs]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"ghost_cwm_regex_parser\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"console\"" >> /var/local/observability/.vector/config/vector.toml
    echo "encoding = \"json\"" >> /var/local/observability/.vector/config/vector.toml
    echo "" >> /var/local/observability/.vector/config/vector.toml
    echo "[sinks.ghost_cloudwatch]" >> /var/local/observability/.vector/config/vector.toml
    echo "inputs = [\"ghost_cwm_to_metric\"]" >> /var/local/observability/.vector/config/vector.toml
    echo "type = \"aws_cloudwatch_metrics\"" >> /var/local/observability/.vector/config/vector.toml
    echo "namespace = \"appghost\"" >> /var/local/observability/.vector/config/vector.toml
    echo "endpoint = \"http://localhost:4566\"" >> /var/local/observability/.vector/config/vector.toml
    chown -R ubuntu:ubuntu /var/local/observability/.vector/config/vector.toml

    vector --config /var/local/observability/.vector/config/vector.toml
