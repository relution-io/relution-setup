#!/bin/bash
#
#  _________  _________  ___        ___   ___  __________ ___  _________  _________          ___  ___  ___
# |\   __   \|\   _____\|\  \      |\  \ |\  \|\___    __\\  \|\   __   \|\   ___  \        |\  \|\  \|\  \
# \ \  \_|\  \ \  \____|\ \  \     \ \  \\ \  \|___|\  \_| \  \ \  \_|\  \ \  \_|\  \       \ \  \ \  \ \  \
#  \ \   __  /_ \   ___\ \ \  \     \ \  \\ \  \   \ \  \ \ \  \ \  \\ \  \ \  \\ \  \       \ \  \ \  \ \  \
#   \ \  \_|\  \ \  \__|__\ \  \_____\ \  \\_\  \   \ \  \ \ \  \ \  \\_\  \ \  \\ \  \       \/  /\/  /\/  /|
#    \ \__\\ \__\ \________\ \________\ \________\   \ \__\ \ \__\ \________\ \__\\ \__\      /  ///  ///  //
#     \|__| \|__|\|________|\|________|\|________|    \|__|  \|__|\|________|\|__| \|__|     /_ ///_ ///_ //
#                                                                                          |__|/|__|/|__|/
#
# Install script for Relution on CentOS 7.4 with MariaDB and NGINX
#


function start_service() {
  if $(/usr/bin/systemctl -q is-active $1); then
    systemctl restart $1
  else
    systemctl start $1
  fi
}

function conf() {
  sed -i -e "s^$2^$3^g" $1
}

function fail() {
	echo -e "\033[1;31m$1\033[0m"
}

function warn() {
	echo -e "\033[1;33m$1\033[0m"
}

function info() {
	echo -e "\033[1;38m$1\033[0m"
}

function head() {
  echo
  echo -e "\033[1;38m$1\033[0m"
}

function can_create() {
  if [[ -e $1 ]]; then
    echo
    warn "$1 already exists!"
    read -p "Overwrite? [y/N] " OVERWRITE
    echo
    if [[ "$OVERWRITE" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
      return 0
    else
      return 1
    fi
  else
    return 0
  fi
}


#
# Ensure the script is run as root
#
if [ $(id -u) != 0 ]; then
  fail "Please run this script as root"
  exit 1
fi


# --------------------------------------------------------------------------------
# GET INFORMATION
# --------------------------------------------------------------------------------
DEFAULT_SMTP_HOSTNAME="localhost"
DEFAULT_SMTP_PORT="25"
DEFAULT_SMTP_USERNAME=""
DEFAULT_SMTP_PASSWORD=""

DEFAULT_WEB_HOSTNAME=$(hostname --fqdn)
DEFAULT_WEB_SSL_CERT_PATH="/opt/relution/server.pem"
DEFAULT_WEB_SSL_CERT_KEY_PATH="/opt/relution/server.key"
DEFAULT_WEB_SSL_CERT_CHAIN_PATH="/opt/relution/server.chain"

DEFAULT_ORG_UNAME="example"
DEFAULT_ORG_NAME="Example Inc."
DEFAULT_ADM_USERNAME="admin"
DEFAULT_ADM_PASSWORD=""
DEFAULT_ADM_FNAME="Administrator"
DEFAULT_ADM_LNAME="Organization"

echo
info "Welcome to the Relution setup script. Please provide the necessary information required to configure your system."

CONFIRMED=No
while [[ ! "$CONFIRMED" =~ ^([yY][eE][sS]|[yY])+$ ]]; do
  head "E-MAIL"
  echo "Please provide an SMTP server configuration. This SMTP server and user account are used to send email on behalf of Relution."

  echo
  read -p "Hostname [$DEFAULT_SMTP_HOSTNAME]: " SMTP_HOSTNAME
  read -p "Port [$DEFAULT_SMTP_PORT]: " SMTP_PORT
  read -p "Username [$DEFAULT_SMTP_USERNAME]: " SMTP_USERNAME
  read -p "Password [$DEFAULT_SMTP_PASSWORD]: " -s SMTP_PASSWORD

  DEFAULT_SMTP_HOSTNAME=${SMTP_HOSTNAME:-$DEFAULT_SMTP_HOSTNAME}
  DEFAULT_SMTP_PORT=${SMTP_PORT:-$DEFAULT_SMTP_PORT}
  DEFAULT_SMTP_USERNAME=${SMTP_USERNAME:-$DEFAULT_SMTP_USERNAME}
  DEFAULT_SMTP_PASSWORD=${SMTP_PASSWORD:-$DEFAULT_SMTP_PASSWORD}

  SMTP_HOSTNAME=${DEFAULT_SMTP_HOSTNAME}
  SMTP_PORT=${DEFAULT_SMTP_PORT}
  SMTP_USERNAME=${DEFAULT_SMTP_USERNAME}
  SMTP_PASSWORD=${DEFAULT_SMTP_PASSWORD}

  echo
  read -p "Is this information correct? [Y/n]" CONFIRMED
  CONFIRMED=${CONFIRMED:-Yes}
done

CONFIRMED=No
while [[ ! "$CONFIRMED" =~ ^([yY][eE][sS]|[yY])+$ ]]; do
  head "NETWORK"
  echo "Please provide some information about the machine's network configuration. This is used to configure the reverse proxy (nginx)."

  echo
  read -p "Hostname [$DEFAULT_WEB_HOSTNAME]: " WEB_HOSTNAME
  read -p "Use SSL/TLS [Y/n]" WEB_ENABLE_SSL
  WEB_ENABLE_SSL=${WEB_ENABLE_SSL:-Yes}

  if [[ "$WEB_ENABLE_SSL" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    WEB_ENABLE_SSL=Yes
    read -p "SSL certificate path [$DEFAULT_WEB_SSL_CERT_PATH]: " WEB_SSL_CERT_PATH
    read -p "SSL certificate key path [$DEFAULT_WEB_SSL_CERT_KEY_PATH]: " WEB_SSL_CERT_KEY_PATH

    read -p "Use SSL certificate stapling [Y/n]" WEB_ENABLE_SSL_STAPLING
    WEB_ENABLE_SSL_STAPLING=${WEB_ENABLE_SSL_STAPLING:-Yes}
  else
    WEB_ENABLE_SSL=No
  fi

  if [[ "$WEB_ENABLE_SSL_STAPLING" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    WEB_ENABLE_SSL_STAPLING=Yes
    read -p "SSL certificate chain path [$DEFAULT_WEB_SSL_CERT_CHAIN_PATH]" $WEB_SSL_CERT_CHAIN_PATH
  else
    WEB_ENABLE_SSL_STAPLING=No
  fi

  DEFAULT_WEB_HOSTNAME=${WEB_HOSTNAME:-$DEFAULT_WEB_HOSTNAME}
  DEFAULT_WEB_SSL_CERT_PATH=${WEB_SSL_CERT_PATH:-$DEFAULT_WEB_SSL_CERT_PATH}
  DEFAULT_WEB_SSL_CERT_KEY_PATH=${WEB_SSL_CERT_KEY_PATH:-$DEFAULT_WEB_SSL_CERT_KEY_PATH}
  DEFAULT_WEB_SSL_CERT_CHAIN_PATH=${WEB_SSL_CERT_CHAIN_PATH:-$DEFAULT_WEB_SSL_CERT_CHAIN_PATH}

  WEB_HOSTNAME=${DEFAULT_WEB_HOSTNAME}
  WEB_SSL_CERT_PATH=${DEFAULT_WEB_SSL_CERT_PATH}
  WEB_SSL_CERT_KEY_PATH=${DEFAULT_WEB_SSL_CERT_KEY_PATH}
  WEB_SSL_CERT_CHAIN_PATH=${DEFAULT_WEB_SSL_CERT_CHAIN_PATH}

  if [[ "$WEB_ENABLE_SSL" == "Yes" && ! -f $WEB_SSL_CERT_PATH ]]; then
    warn "The file $WEB_SSL_CERT_PATH does not exist!"
  fi
  if [[ "$WEB_ENABLE_SSL" == "Yes" && ! -f $WEB_SSL_CERT_KEY_PATH ]]; then
    warn "The file $WEB_SSL_CERT_KEY_PATH does not exist!"
  fi
  if [[ "$WEB_ENABLE_SSL_STAPLING" == "Yes" && ! -f $WEB_SSL_CERT_CHAIN_PATH ]]; then
    warn "The file $WEB_SSL_CERT_CHAIN_PATH does not exist!"
  fi

  echo
  read -p "Is this information correct? [Y/n]" CONFIRMED
  CONFIRMED=${CONFIRMED:-Yes}
done

CONFIRMED=No
while [[ ! "$CONFIRMED" =~ ^([yY][eE][sS]|[yY])+$ ]]; do
  head "ORGANIZATION"
  echo "Please provide some information about the organization you want to create."

  echo
  read -p "Unique name [$DEFAULT_ORG_UNAME]: " ORG_UNAME
  read -p "Name [$DEFAULT_ORG_NAME]: " ORG_NAME
  read -p "Administrator username [$DEFAULT_ADM_USERNAME]: " ADM_USERNAME
  read -p "Administrator password [$DEFAULT_ADM_PASSWORD]: " ADM_PASSWORD
  read -p "Administrator first name [$DEFAULT_ADM_FNAME]: " ADM_FNAME
  read -p "Administrator last name  [$DEFAULT_ADM_LNAME]: " ADM_LNAME

  DEFAULT_ORG_UNAME=${ORG_UNAME:-$DEFAULT_ORG_UNAME}
  DEFAULT_ORG_NAME=${ORG_NAME:-$DEFAULT_ORG_NAME}
  DEFAULT_ADM_USERNAME=${ADM_USERNAME:-$DEFAULT_ADM_USERNAME}
  DEFAULT_ADM_PASSWORD=${ADM_PASSWORD:-$DEFAULT_ADM_PASSWORD}
  DEFAULT_ADM_FNAME=${ADM_FNAME:-$DEFAULT_ADM_FNAME}
  DEFAULT_ADM_LNAME=${ADM_LNAME:-$DEFAULT_ADM_LNAME}

  ORG_UNAME=${DEFAULT_ORG_UNAME}
  ORG_NAME=${DEFAULT_ORG_NAME}
  ADM_USERNAME=${DEFAULT_ADM_USERNAME}
  ADM_PASSWORD=${DEFAULT_ADM_PASSWORD}
  ADM_FNAME=${DEFAULT_ADM_FNAME}
  ADM_LNAME=${DEFAULT_ADM_LNAME}

  echo
  read -p "Is this information correct? [Y/n]" CONFIRMED
  CONFIRMED=${CONFIRMED:-Yes}
done


# --------------------------------------------------------------------------------
# INSTALL DEPENDENCIES
# --------------------------------------------------------------------------------


#
# Install dependencies
#
echo "Installing dependencies..."
sudo yum -y -q -e 0 update
sudo yum -y -q -e 0 install epel-release
sudo yum -y -q -e 0 install pwgen unzip vim wget bind-utils
sudo yum -y -q -e 0 install java-1.8.0-openjdk mariadb-server nginx


#
# Configure JAVA_HOME environment variable
#
if grep -q "export JAVA_HOME" /etc/profile; then
  echo "JAVA_HOME already set"
else
  echo "Configure JAVA_HOME environment variable"
  sudo echo "export JAVA_HOME=/usr" >> /etc/profile
fi
source /etc/profile


# --------------------------------------------------------------------------------
# SET UP MARIADB
# --------------------------------------------------------------------------------


echo "Add MariaDB configuration for Relution"
if can_create /etc/my.cnf.d/relution.cnf; then
  #
  # Add MariaDB configuration for Relution
  #
  sudo cp Linux/etc/my.cnf.d/relution.cnf.template /etc/my.cnf.d/relution.cnf


  #
  # Start and enable MariaDB
  #
  echo "Restart MariaDB service"
  sudo systemctl enable mariadb.service
  start_service mariadb.service
fi


#
# Create database and user for Relution
#
echo "Create Relution database"
MYSQL_PASSWORD=$(/usr/bin/pwgen -snc 48 1)
Linux/scripts/create_database.sh "relution" "$MYSQL_PASSWORD"


# --------------------------------------------------------------------------------
# SET UP RELUTION
# --------------------------------------------------------------------------------


#
# Download and extract latest Relution package
#
if can_create /opt/relution-package.zip; then
  echo "Download latest Relution package"
  rm -rf /opt/relution-package.zip
  wget https://repo.relution.io/package/latest/relution-package.zip --directory-prefix=/opt
fi
if can_create /opt/relution; then
  if [[ -f /opt/relution/application.yml ]]; then
    info "Backup /opt/relution/application.yml"
    cp /opt/relution/application.yml /opt/relution_application.yml.bak
  fi
  echo "Extract Relution package"
  rm -rf /opt/relution
  unzip /opt/relution-package.zip -d /opt
fi
if [[ -f /opt/relution_application.yml.bak ]]; then
  info "Restore /opt/relution/application.yml from backup"
  mv /opt/relution_application.yml.bak /opt/relution/application.yml
fi


#
# Create unprivileged Relution user
#
echo "Create unprivileged Relution user"
sudo useradd -s /bin/false -r relution


#
# Change owner or Relution directory
#
echo "Change owner of Relution directory"
sudo chown -R relution:relution /opt/relution
if [[ -d /tmp/relution.tmp ]]; then
  sudo chown -R relution:relution /tmp/relution.tmp
fi


#
# Add basic Relution configuration
#
if can_create /opt/relution/application.yml; then
  echo "Create configuration"
  FILE=/opt/relution/application.yml
  cp Linux/opt/relution/application.yml.template $FILE
  conf $FILE "%MYSQL_PASSWORD%" "$MYSQL_PASSWORD"
  conf $FILE "%SMTP_HOSTNAME%" "$SMTP_HOSTNAME"
  conf $FILE "%SMTP_PORT%" "$SMTP_PORT"
  conf $FILE "%SMTP_USERNAME%" "$SMTP_USERNAME"
  conf $FILE "%SMTP_PASSWORD%" "$SMTP_PASSWORD"
  conf $FILE "%ORG_UNIQUE_NAME%" "$ORG_UNAME"
  conf $FILE "%ORG_DISPLAY_NAME%" "$ORG_NAME"
  conf $FILE "%ADM_USERNAME%" "$ADM_USERNAME"
  conf $FILE "%ADM_PASSWORD%" "$ADM_PASSWORD"
  conf $FILE "%ADM_FIRST_NAME%" "$ADM_FNAME"
  conf $FILE "%ADM_LAST_NAME%" "$ADM_LNAME"
fi


#
# Set configuration file permissions
#
echo "Set configuration file permissions"
sudo chown root:relution /opt/relution/application.yml
sudo chmod 640 /opt/relution/application.yml


#
# Set up Relution as a system service
#
echo Set up Relution as a system service
if can_create /etc/systemd/system/relution.service; then
  sudo cp Linux/etc/systemd/system/relution.service.template /etc/systemd/system/relution.service
  sudo systemctl daemon-reload

  sudo systemctl enable relution.service
  start_service relution.service
fi


# --------------------------------------------------------------------------------
# SET UP NGINX
# --------------------------------------------------------------------------------


#
# Generate secure Diffie-Hellman parameters
#
if [[ "$WEB_ENABLE_SSL" == "Yes" ]]; then
  echo "Generate secure Diffie-Hellman parameters"
  if can_create /etc/nginx/dhparams.pem; then
    sudo openssl dhparam -out /etc/nginx/dhparams.pem 4096
  fi
fi


#
# Create cache directory
#
echo "Create cache directory"
sudo mkdir /usr/share/nginx/cache
sudo chown nginx:nginx /usr/share/nginx/cache


#
# Add Relution configuration
#
echo "Add nginx configuration for Relution"
if [[ "$WEB_ENABLE_SSL" == "Yes" ]]; then
  TEMPLATE=Linux/etc/nginx/conf.d/relution-ssl.conf.template
else
  TEMPLATE=Linux/etc/nginx/conf.d/relution.conf.template
fi

FILE=/etc/nginx/conf.d/relution.conf
if can_create $FILE; then
  cp $TEMPLATE $FILE
  cp Linux/etc/nginx/conf.d/relution-location.include.template /etc/nginx/conf.d/relution-location.include
  conf $FILE "%EXT_HOSTNAME%" "$WEB_HOSTNAME"
  conf $FILE "%SSL_CERT_PATH%" "$WEB_SSL_CERT_PATH"
  conf $FILE "%SSL_CERT_KEY_PATH%" "$WEB_SSL_CERT_KEY_PATH"
  conf $FILE "%SSL_CERT_CHAIN_PATH%" "$WEB_SSL_CERT_CHAIN_PATH"
fi


#
# Start and enable nginx
#
echo "Restart nginx service"
sudo systemctl enable nginx.service
start_service nginx.service


#
# Configure SELinux
#
sudo setsebool -P httpd_can_network_connect 1


#
# Configure firewall
#
echo "Open HTTP (80) port in firewall"
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
if [[ "$WEB_ENABLE_SSL" == "Yes" ]]; then
  echo "Open HTTPS (443) port in firewall"
  sudo firewall-cmd --permanent --zone=public --add-port=443/tcp
fi
echo "Activate firewall configuration"
sudo firewall-cmd --reload
