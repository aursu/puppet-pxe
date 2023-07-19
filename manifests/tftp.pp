# Install and manage TFTP service for PXE environment
#
# @summary Install and manage TFTP service for PXE environment
#
# @example
#   include pxe::tftp
class pxe::tftp (
  Boolean $service_enable = true,
  Boolean $verbose        = false,
) {
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
