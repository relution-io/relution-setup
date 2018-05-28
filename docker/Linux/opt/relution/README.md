# Relution on Docker

This directory contains a [Docker Compose](https://docs.docker.com/compose/) file for [Relution](https://www.relution.io/) on Linux. It has been verified to work on CentOS 7.4.

For convenience, the file configures all services necessary to run a Relution server: [MariaDB](https://mariadb.org/), [MongoDB](https://www.mongodb.com/), Relution and [NGINX](https://www.nginx.com/).

Depending on your performance and security requirements consider running some or all of these services on separate machines.

## docker-compose.yml

This file is an example. It contains placeholders for arguments like passwords and external host names. To use this file, please replace all placeholders in the form of `%VALUE%` with actual values.

## relution-nginx.conf

This file is an example. It contains the basic NGINX configuration that is needed to make Relution available on the Internet. To use this file, verify that the host names and certificate files specified in this file match your environment.

For increased security, do configure Diffie-Hellman parameters (`ssl_dhparam`) and OCSP stapling (`ssl_stapling`).
