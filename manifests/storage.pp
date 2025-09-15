# @summary Create PXE environment
#
# Create all directories required by PXE environment
#
# @example
#   include pxe::storage
class pxe::storage (
  Boolean $setup_tftp_root = false,
  Boolean $manage_storage_directory = true,
  Stdlib::Unixpath $tftp_root = $pxe::params::tftp_root,
) inherits pxe::params {
  include apache::params
  $user = $apache::params::user

  $storage_directory  = $pxe::params::storage_directory

  $rocky8_current_version = $pxe::params::rocky8_current_version
  $rocky9_current_version = $pxe::params::rocky9_current_version
  $rocky10_current_version = $pxe::params::rocky10_current_version

  $ubuntu22_current_version = $pxe::params::ubuntu22_current_version
  $ubuntu24_current_version = $pxe::params::ubuntu24_current_version

  if $manage_storage_directory {
    file { $storage_directory:
      ensure => directory,
      owner  => $user,
      mode   => '0511',
    }
  }
  else {
    exec { "create ${storage_directory}":
      command => "mkdir -p ${storage_directory}",
      path    => ['/usr/bin', '/bin'],
      creates => $storage_directory,
    }
  }

  # Storage
  file { [
      "${storage_directory}/centos",
      "${storage_directory}/centos/9-stream",
      "${storage_directory}/centos/10-stream",
      "${storage_directory}/rocky",
      "${storage_directory}/rocky/${rocky8_current_version}",
      "${storage_directory}/rocky/${rocky9_current_version}",
      "${storage_directory}/rocky/${rocky10_current_version}",
      "${storage_directory}/ubuntu",
      "${storage_directory}/ubuntu/${ubuntu22_current_version}",
      "${storage_directory}/ubuntu/${ubuntu24_current_version}",
      "${storage_directory}/configs",
      "${storage_directory}/configs/assets",
      "${storage_directory}/configs/ubuntu",
      "${storage_directory}/configs/ubuntu/${ubuntu22_current_version}",
      "${storage_directory}/configs/ubuntu/${ubuntu24_current_version}",
      '/mnt/iso',
      '/mnt/iso/ubuntu',
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
      "${tftp_root}/boot/rocky/${rocky10_current_version}",
      "${tftp_root}/boot/ubuntu",
      "${tftp_root}/boot/ubuntu/${ubuntu22_current_version}",
      "${tftp_root}/boot/ubuntu/${ubuntu24_current_version}",
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

  file { ["${tftp_root}/boot/rocky/10", "${storage_directory}/rocky/10"]:
    ensure => link,
    target => $rocky10_current_version,
  }

  file { ["${tftp_root}/boot/ubuntu/jammy", "${storage_directory}/ubuntu/jammy",
      "${tftp_root}/boot/ubuntu/22.04", "${storage_directory}/ubuntu/22.04",
    "${storage_directory}/configs/ubuntu/22.04", "${storage_directory}/configs/ubuntu/jammy"]:
      ensure => link,
      target => $ubuntu22_current_version,
  }

  file { ["${tftp_root}/boot/ubuntu/noble", "${storage_directory}/ubuntu/noble",
      "${tftp_root}/boot/ubuntu/24.04", "${storage_directory}/ubuntu/24.04",
    "${storage_directory}/configs/ubuntu/24.04", "${storage_directory}/configs/ubuntu/noble"]:
      ensure => link,
      target => $ubuntu24_current_version,
  }

  if $manage_storage_directory {
    unless $storage_directory == '/diskless' {
      file { '/diskless':
        ensure => link,
        target => $storage_directory,
      }
    }
  }
}
