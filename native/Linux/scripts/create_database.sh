#!/bin/bash
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <database> <password>"
    exit 1
fi

DATABASE=$1
PASSWORD=$2

mysql -u root <<EOF
CREATE DATABASE $DATABASE CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci';
CREATE USER 'relution'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON $DATABASE.* TO 'relution'@'localhost' IDENTIFIED BY '$PASSWORD';
CREATE USER 'relution'@'%' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON $DATABASE.* TO 'relution'@'%' IDENTIFIED BY '$PASSWORD';
FLUSH PRIVILEGES;
EOF
