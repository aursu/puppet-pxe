# Install and manage TFTP service for PXE environment
#
# @summary Install and manage TFTP service for PXE environment
#
# @example
#   include pxe::tftp
class pxe::tftp (
  Boolean $service_enable = true,
  Boolean $verbose = false,
  String $username = 'tftp',
  Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]] $directory = '/srv/tftp',
  Variant[Enum[''], Stdlib::IP::Address] $address = '0.0.0.0',
  Integer $port = 69,
  Variant[String, Array[String]] $options = '--secure',
) {
  include bsys::params

  case $bsys::params::osfam {
    'RedHat': {
      # Install the xinetd service, that manages the tftpd service
      package { 'xinetd':
        ensure => present,
      }

      package { 'tftp-server':
        ensure => present,
      }

      file { '/etc/xinetd.d/tftp':
        ensure  => file,
        content => template('pxe/xinetd.tftp.erb'),
        require => Package['tftp-server'],
        notify  => Service['xinetd'],
      }

      service { 'xinetd':
        ensure  => running,
        enable  => true,
        require => Package['xinetd'],
      }

      # TFTP content
      file { '/var/lib/tftpboot':
        ensure  => directory,
        require => Package['tftp-server'],
      }
    }
    'Debian': {
      package { 'tftpd-hpa':
        ensure => present,
      }

      service { 'tftpd-hpa':
        ensure  => running,
        enable  => true,
        require => Package['tftpd-hpa'],
      }

      $tftp_directory = [$directory].flatten()
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
        require => Package['tftpd-hpa'],
        notify  => Service['tftpd-hpa'],
      }

      $tftp_directory.each |$tftp_dir| {
        # TFTP content
        file { $tftp_dir:
          ensure  => directory,
          require => Package['tftpd-hpa'],
          before  => Service['tftpd-hpa'],
        }
      }
    }
  }
}
