# @summary Create PXE environment
#
# Create all directories required by PXE environment
#
# @example
#   include pxe::storage
class pxe::storage (
  Boolean $setup_tftp_root = false,
  Stdlib::Unixpath $tftp_root = $pxe::params::tftp_directory,
) inherits pxe::params {
  include apache::params
  $user = $apache::params::user

  include pxe::params

  $storage_directory  = $pxe::params::storage_directory

  $stream9_current_version = $pxe::params::stream9_current_version
  $stream10_current_version = $pxe::params::stream10_current_version

  $rocky8_current_version = $pxe::params::rocky8_current_version
  $rocky9_current_version = $pxe::params::rocky9_current_version

  # Storage
  file { [
      $storage_directory,
      "${storage_directory}/centos",
      "${storage_directory}/centos/9-stream",
      "${storage_directory}/centos/10-stream",
      "${storage_directory}/rocky",
      "${storage_directory}/rocky/${rocky8_current_version}",
      "${storage_directory}/rocky/${rocky9_current_version}",
      "${storage_directory}/ubuntu",
      "${storage_directory}/ubuntu/jammy",
      "${storage_directory}/ubuntu/noble",
      "${storage_directory}/configs",
      "${storage_directory}/configs/assets",
    "${storage_directory}/exec"]:
      ensure => directory,
      owner  => $user,
      mode   => '0511',
  }

  # TFTP root directory
  if $setup_tftp_root {
    file { $tftp_root:
      ensure => directory,
      mode   => '0711',
    }
  }

  # GRUB configuration
  file {
    default:
      ensure => directory,
      ;
    ["${tftp_root}/boot",
      "${tftp_root}/boot/grub",
      "${tftp_root}/boot/centos",
      "${tftp_root}/boot/centos/9-stream",
      "${tftp_root}/boot/centos/10-stream",
      "${tftp_root}/boot/rocky",
      "${tftp_root}/boot/rocky/${rocky8_current_version}",
      "${tftp_root}/boot/rocky/${rocky9_current_version}",
      "${tftp_root}/boot/ubuntu",
      "${tftp_root}/boot/ubuntu/jammy",
      "${tftp_root}/boot/ubuntu/noble",
    ]:
      mode => '0711',
      ;
    ["${tftp_root}/boot/install", '/var/lib/pxe']:
      owner => $user,
      mode  => '0751',
      ;
  }

  file { ["${tftp_root}/boot/rocky/8", "${storage_directory}/rocky/8"]:
    ensure => link,
    target => $rocky8_current_version,
  }

  file { ["${tftp_root}/boot/rocky/9", "${storage_directory}/rocky/9"]:
    ensure => link,
    target => $rocky9_current_version,
  }

  unless $storage_directory == '/diskless' {
    file { '/diskless':
      ensure => link,
      target => $storage_directory,
    }
  }
}
