# Install and manage TFTP service for PXE environment
#
# @summary Install and manage TFTP service for PXE environment
#
# @example
#   include pxe::tftp
class pxe::tftp (
  String $username = 'tftp',
  Stdlib::Unixpath $storage_directory = $pxe::params::tftp_directory,
  Variant[Enum[''], Stdlib::IP::Address] $address = '0.0.0.0',
  Integer $port = 69,
  Variant[String, Array[String]] $options = '--secure',
  String $server_package = $pxe::params::tftp_server_package,
) inherits pxe::params {
  include bsys::params

  case $bsys::params::osfam {
    'RedHat': {
      include pxe::tftp::xinetd

      package { $server_package:
        ensure => present,
      }

      # TFTP content
      file { $storage_directory:
        ensure  => directory,
        require => Package[$server_package],
      }

      Package[$server_package] -> Class['pxe::tftp::xinetd']
    }
    'Debian': {
      package { $server_package:
        ensure => present,
      }

      service { 'tftpd-hpa':
        ensure  => running,
        enable  => true,
        require => Package[$server_package],
      }

      $tftp_directory = [$storage_directory].flatten()
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

      $tftp_directory.each |$tftp_dir| {
        # TFTP content
        file { $tftp_dir:
          ensure  => directory,
          require => Package[$server_package],
          before  => Service['tftpd-hpa'],
        }
      }

      class { 'pxe::tftp::xinetd':
        decomission => true,
        before      => Service['tftpd-hpa'],
      }
    }
  }
}
