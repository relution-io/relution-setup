# Relution setup

Scripts and configuration files that can be used to set up Relution on various platforms

## Template files

Most of these files are templates. They contain placeholder values in the form of `%VALUE%`. They need to be adjusted for your environment; they can't be used as-is.

In most cases these files need to be copied to the appropriate directory on your server's disk and the `%VALUE%` placeholders need to be replaced. Please consult the installation manual for detailed instructions on how to use these files.

For convenience setup scripts are provided that can be used to set up a basic Relution server on some platforms.

## Supported platforms

We recommend the use of Linux in combination with docker.

### Linux

Relution has been verified to work with:

- Alma or Rocky Linux 8
- Red Hat Enterprise Linux 8 or newer
- SUSE Linux Enterprise Server 12 or newer

Relution should work on any Linux distribution that supports `systemd` but this has not been verified and is not currently supported. If you wish to receive support, please ensure that you run Relution on a supported platform.

## Supported databases

Relution has been verified to work with:

- MariaDB 10.3 or newer
- MySQL 8.0 or newer
- PostgreSQL 12 or newer
