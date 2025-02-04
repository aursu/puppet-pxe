# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pxe::params
class pxe::params {
  include bsys::params

  $storage_directory = lookup('pxe::params::storage_directory', Stdlib::Unixpath, 'first', '/diskless')

  $rocky8_current_version = '8.10'
  $rocky9_current_version = '9.5'

  $ubuntu22_current_version = '22.04.5'
  $ubuntu24_current_version = '24.04.1'

  case $bsys::params::osfam {
    'RedHat': {
      $tftp_server_package = 'tftp-server'
      $tftp_root           = '/var/lib/tftpboot'
      $ipxe_package        = 'ipxe-bootimgs'
    }
    'Debian': {
      $tftp_server_package = 'tftpd-hpa'
      $tftp_root           = '/srv/tftp'
      $ipxe_package        = 'ipxe'
    }
    default: {
      $tftp_server_package = undef
      $tftp_root           = undef
      $ipxe_package        = undef
    }
  }
}
