#!/bin/bash

set -x

# Set non-interactive installer mode
export DEBIAN_FRONTEND=noninteractive

export REDMINE_VERSION=3.0.4
export VERBOSE=yes

export PLUGIN=code_audit
export WORKSPACE=/vagrant
export PATH_TO_PLUGIN=$WORKSPACE
export PATH_TO_REDMINE=/var/www/redmine
export ENVIRONMENT=development
export PATH_TO_DATABASE_CONFIG_FILE=tools/vagrant/database.yml

################################################################################
# www-data
################################################################################

chsh -s /bin/bash www-data
mkdir -p /var/www
chown -R www-data:www-data /var/www

################################################################################
# Build Essential
################################################################################

apt-get update

apt-get install -q -y build-essential binutils-doc autoconf cmake zlib1g-dev sqlite3 libsqlite3-dev git nginx

################################################################################
# Ruby and Bundler
################################################################################

apt-get install -q -y ruby-dev

gem install bundler thin --no-rdoc

# Copy our custom thin startup script
cp /vagrant/tools/vagrant/thin /etc/init.d/thin
chmod +x /etc/init.d/thin
update-rc.d thin defaults

################################################################################
# Install Nginx
################################################################################

# Configure thin.
mkdir -p /etc/thin

thin config \
--config /etc/thin/redmine.yml \
--chdir "$PATH_TO_REDMINE" \
--environment "$ENVIRONMENT" \
--servers 2 \
--socket /tmp/thin.redmine.sock \
--pid tmp/pids/thin.pid

# Configure nginx. For now default config is overriden.
dd of=/etc/nginx/sites-available/default << EOF
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

################################################################################
# Install Redmine
################################################################################

bash -x "$WORKSPACE/tools/travis/init.sh" -r || exit 1
chown -R www-data:www-data "$PATH_TO_REDMINE"

sudo -u www-data -E bash -x "$WORKSPACE/tools/travis/init.sh" -i || exit 1

################################################################################
# Restart services
################################################################################

# Restart thin
service thin restart

# Restart nginx
service nginx restart


cat <<EOF
################################################
# Now you should be able to see Redmine at
# http://localhost
#
# Username: admin
# Password: admin
################################################
EOF