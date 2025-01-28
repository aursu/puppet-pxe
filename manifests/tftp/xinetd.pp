# @summary Manages the configuration and setup of a TFTP server using Xinetd.
#
# This class ensures that the TFTP service is properly configured and enabled
# through Xinetd. It installs the required package, manages the configuration
# file, and ensures the service is running and enabled at startup. The behavior
# of the TFTP service can be customized using class parameters.
#
# @param service_enable
#   Enables or disables the TFTP service (default: true).
#
# @param verbose
#   Enables verbose logging for the TFTP server (default: false).
#
# @example Include the class with default parameters:
#   include pxe::tftp::xinetd
#
# @example Include the class with custom parameters:
#   class { 'pxe::tftp::xinetd':
#     service_enable => false,
#     verbose        => true,
#   }
class pxe::tftp::xinetd (
  Boolean $service_enable = true,
  Boolean $verbose = false,
  Stdlib::Unixpath $storage_directory = $pxe::params::tftp_directory,
  Boolean $decomission = false,
) inherits pxe::params {
  if $decomission {
    package { 'xinetd':
      ensure => absent,
    }

    file { '/etc/xinetd.d/tftp':
      ensure => absent,
      before => Package['xinetd'],
    }

    service { 'xinetd':
      ensure => stopped,
      enable => false,
      before => Package['xinetd'],
    }
  }
  else {
    package { 'xinetd':
      ensure => present,
    }

    file { '/etc/xinetd.d/tftp':
      ensure  => file,
      content => template('pxe/xinetd.tftp.erb'),
      notify  => Service['xinetd'],
    }

    service { 'xinetd':
      ensure  => running,
      enable  => true,
      require => Package['xinetd'],
    }
  }
}
