# Install and manage TFTP service for PXE environment
#
# @summary Install and manage TFTP service for PXE environment
#
# @example
#   include pxe::tftp
class pxe::tftp (
  String $username = 'tftp',
  Stdlib::Unixpath $root_directory = $pxe::params::tftp_root,
  Variant[Enum[''], Stdlib::IP::Address] $address = '0.0.0.0',
  Integer $port = 69,
  Variant[String, Array[String]] $options = '--secure',
  String $server_package = $pxe::params::tftp_server_package,
) inherits pxe::params {
  include bsys::params

  package { $server_package:
    ensure => present,
  }

  case $bsys::params::osfam {
    'RedHat': {
      include pxe::tftp::xinetd

      # TFTP content
      file { $root_directory:
        ensure  => directory,
        require => Package[$server_package],
      }

      Package[$server_package] -> Class['pxe::tftp::xinetd']
    }
    'Debian': {
      service { 'tftpd-hpa':
        ensure  => running,
        enable  => true,
        require => Package[$server_package],
      }

      $tftp_directory = [$root_directory].flatten()
      $tftp_options = [$options].flatten()

      file { '/etc/default/tftpd-hpa':
        ensure  => file,
        content => epp('pxe/init.tftpd-hpa.epp', {
            tftp_username  => $username,
            tftp_directory => $tftp_directory,
            tftp_address   => $address,
            tftp_port      => $port,
            tftp_options   => $tftp_options,
        }),
        require => Package[$server_package],
        notify  => Service['tftpd-hpa'],
      }

      # TFTP content
      file { $tftp_directory:
        ensure  => directory,
        require => Package[$server_package],
        before  => Service['tftpd-hpa'],
      }

      class { 'pxe::tftp::xinetd':
        decomission => true,
        before      => Service['tftpd-hpa'],
      }
    }
  }
}
