#/bin/bash

set -x

# Set non-interactive instaler mode, update repos.
export DEBIAN_FRONTEND=noninteractive

#sudo apt-get update

################################################################################
# www-data
################################################################################

chsh -s /bin/bash www-data
mkdir /var/www
chown -R www-data:www-data /var/www

################################################################################
# Build Essential
################################################################################

apt-get install -q -y build-essential binutils-doc autoconf cmake zlib1g-dev \
    sqlite3 libsqlite3-dev git

################################################################################
# RVM, Ruby and Bundler
################################################################################

curl -sSL https://get.rvm.io | bash -s stable --rails
gem install bundler

apt-get install -q -y ruby-dev

################################################################################
# Install Redmine
################################################################################

export REDMINE_VERSION=2.5.1
export VERBOSE=yes

export PLUGIN=code_audit
export WORKSPACE=/vagrant
export PATH_TO_PLUGIN=$WORKSPACE
export PATH_TO_REDMINE=/var/www/redmine
export ENVIRONMENT=development
export PATH_TO_DATABASE_CONFIG_FILE=tools/vagrant/database.yml

bash -x "$WORKSPACE/tools/travis/init.sh" -r || exit 1
chown -R www-data:www-data "$PATH_TO_REDMINE"

sudo -u www-data -E bash -x "$WORKSPACE/tools/travis/init.sh" -i || exit 1

################################################################################
# Install Nginx
################################################################################

# nginx and thin are required.
sudo apt-get install -q -y nginx thin

# Configure thin.
sudo thin config \
  --config /etc/thin1.9.1/redmine.yml \
  --chdir "$PATH_TO_REDMINE" \
  --environment "$ENVIRONMENT" \
  --servers 2 \
  --socket /tmp/thin.redmine.sock \
  --pid tmp/pids/thin.pid

# Configure nginx. For now default config is overriden.
sudo dd of=/etc/nginx/sites-available/default << EOF
upstream redmine_upstream {
  server unix:/tmp/thin.redmine.0.sock;
  server unix:/tmp/thin.redmine.1.sock;
}

server {
  listen 80;
  server_name 127.0.0.1;
  root /usr/share/redmine/public;

  location / {
    try_files \$uri @redmine_ruby;
  }

  location @redmine_ruby {
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header  Host \$http_host;
    proxy_redirect off;
    proxy_read_timeout 300;
    proxy_pass http://redmine_upstream;
  }
}
EOF

# Restart thin
sudo service thin restart

# Restart nginx
sudo service nginx restart


cat <<EOF
################################################
# Now you should be able to see Redmine at
# http://localhost:8888
#
# Username: admin
# Password: admin
################################################
EOF