# @summary Create PXE environment
#
# Create all directories required by PXE environment
#
# @example
#   include pxe::storage
class pxe::storage (
  Boolean $centos6_support = false,
  Boolean $setup_tftp_root = false,
) {
  include apache::params
  $user = $apache::params::user

  include pxe::params

  $storage_directory  = $pxe::params::storage_directory

  $centos7_current_version = $pxe::params::centos7_current_version
  $stream8_current_version = $pxe::params::stream8_current_version
  $stream9_current_version = $pxe::params::stream9_current_version

  # Storage
  file { [
      $storage_directory,
      "${storage_directory}/centos",
      "${storage_directory}/centos/${centos7_current_version}",
      "${storage_directory}/centos/${stream8_current_version}",
      "${storage_directory}/centos/${stream9_current_version}",
      "${storage_directory}/configs",
      "${storage_directory}/configs/assets",
    "${storage_directory}/exec"]:
      ensure => directory,
      owner  => $user,
      mode   => '0511',
  }

  # TFTP root directory
  if $setup_tftp_root {
    file { '/var/lib/tftpboot':
      ensure => directory,
      mode   => '0711',
    }
  }

  # GRUB configuration
  file {
    default:
      ensure => directory,
      ;
    ['/var/lib/tftpboot/boot',
      '/var/lib/tftpboot/boot/grub',
      '/var/lib/tftpboot/boot/centos',
      "/var/lib/tftpboot/boot/centos/${centos7_current_version}",
      "/var/lib/tftpboot/boot/centos/${stream8_current_version}",
    "/var/lib/tftpboot/boot/centos/${stream9_current_version}"]:
      mode => '0711',
      ;
    ['/var/lib/tftpboot/boot/install', '/var/lib/pxe']:
      owner => $user,
      mode  => '0751',
      ;
  }

  file { ['/var/lib/tftpboot/boot/centos/7', "${storage_directory}/centos/7"]:
    ensure => link,
    target => $centos7_current_version,
  }

  unless $stream8_current_version == '8-stream' {
    file { ['/var/lib/tftpboot/boot/centos/8-stream', "${storage_directory}/centos/8-stream"]:
      ensure => link,
      target => $stream8_current_version,
    }
  }

  unless $stream9_current_version == '9-stream' {
    file { ['/var/lib/tftpboot/boot/centos/9-stream', "${storage_directory}/centos/9-stream"]:
      ensure => link,
      target => $stream9_current_version,
    }
  }

  unless $storage_directory == '/diskless' {
    file { '/diskless':
      ensure => link,
      target => $storage_directory,
    }
  }
}
