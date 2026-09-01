# Changelog

All notable changes to this project will be documented in this file.

## Release 0.1.1

**Features**

**Bugfixes**

* Fixed compatibility with Puppet httpd module > 9.0.0

**Known Issues**

## Release 0.2.0

**Features**

* Upgraded all dependencies

**Bugfixes**

**Known Issues**

## Release 0.3.0

**Features**

* PDK upgrade to 2.7.1

**Bugfixes**

**Known Issues**

## Release 0.4.0

**Features**

* Removed support for CentOS 6 and CentOS 8
* Added support for CentOS Stream 8 and CentOS Stream 9

**Bugfixes**

* Fixed compatibility with Puppet httpd module >= 11.0.0

**Known Issues**

* Removed compatibility with Puppet httpd module < 11.0.0

## Release 0.5.0

**Features**

* PDK upgrade to 3.0.0

**Bugfixes**

**Known Issues**

## Release 0.5.2

**Features**

**Bugfixes**

* Fixed default kickstart config for CentOS 8

**Known Issues**

* Added missed require

## Release 0.6.1

**Features**

* Removed CentOS 6/7, CentOS Stream 8
* Added CentOS Stream 10
* Added Ubuntu support for TFTP
* Added xinetd decomission for Ubuntu

**Bugfixes**

**Known Issues**

## Release 0.7.1

**Features**

* Added iPXE nstallation on Ubuntu
* Added Grub 2 intallation on Ubuntu

**Bugfixes**

* Fix compatibility with Ruby 3.x

**Known Issues**

## Release 0.8.5

**Features**

* Removed CentOS 6 and CentOS 7. Added CentOS 10
* Added Ubuntu for storage and Puppet installation assets
* Added SSH key settings for ENC repo.
* Added Ubuntu support into PXE storage

**Bugfixes**

* Updated Puppet installation assets
* Fixed httpd template to support Ubuntu
* Corrected listen and proxied port numbers
* Corrected TFTP root for Ubuntu inside client_config

**Known Issues**

## Release 0.9.2

**Features**

* Added Ubuntu assets for netbooting
* Fixed CGI move script

**Bugfixes**

* Bugfix: No matching entry for selector parameter with value '24.04.1'

**Known Issues**

## Release 0.10.2

**Features**

* Added Ubuntu autoinstall script
* Added ability to just enable autoinstall (to default settings)

**Bugfixes**

* Corrected user-data autoinstall script

**Known Issues**

## Release 0.10.3

**Features**

* Added Ubuntu autoinstall script setup per server
* Added version 24.04.2
* Added Rocky Linux 10 storage management

**Bugfixes**

**Known Issues**

## Release 0.10.4

**Features**

* Added version 24.04.3

**Bugfixes**

**Known Issues**

## Release 0.10.5

**Features**

* New class `pxe::decommission` - the inverse of `pxe::server`. Purges the TFTP,
  iPXE, DHCP and web packages this module installs, unmounts the installer ISOs
  and deletes the storage, TFTP and ISO trees, so a retired PXE server keeps
  nothing behind.

  Unmounting happens before deletion: `pxe::ubuntu` mounts installer ISOs under
  `/mnt/iso`, and those ISO files live inside the storage directory, so deleting
  either while still mounted would leave stale mounts.

  Removal uses guarded `rm -rf` rather than recursive file resources - these
  trees hold distribution mirrors and ISO images, and recursing several GB
  through Puppet's file type is prohibitively slow for a one-off removal.

  No Service resources are declared: purging stops and disables the units, and a
  Service resource naming a unit that no longer exists fails on every later run.

  `nginx` is never touched - `pxe::nginx` only declares a vhost and never
  installs the package - and `nmap` is left alone unless `remove_nmap` is set.

**Bugfixes**

**Known Issues**

