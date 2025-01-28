# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pxe::params
class pxe::params {
  include bsys::params

  $storage_directory = lookup('pxe::params::storage_directory', Stdlib::Unixpath, 'first', '/diskless')

  $stream9_current_version = '9-20250124.0'
  $stream10_current_version = '10-20250123.0'

  $rocky8_current_version = '8.10.20240528'
  $rocky9_current_version = '9.5.20241118'

  case $bsys::params::osfam {
    'RedHat': {
      $tftp_server_package = 'tftp-server'
      $tftp_directory      = '/var/lib/tftpboot'
    }
    'Debian': {
      $tftp_server_package = 'tftpd-hpa'
      $tftp_directory      = '/srv/tftp'
    }
    default: {
      $tftp_server_package = undef
      $tftp_directory      = undef
    }
  }
}
