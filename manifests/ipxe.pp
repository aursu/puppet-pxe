# @summary iPXE bootloader installation
#
# iPXE boot loader installation
#
# @example
#   include pxe::ipxe
class pxe::ipxe inherits pxe::params {
  include pxe::storage
  include bsys::params

  $tftp_root = $pxe::params::tftp_directory
  $ipxe_root = "${tftp_root}/boot/ipxe"
  $ipxe_package = $pxe::params::ipxe_package

  # iPXE is an open source network bootloader
  package { $ipxe_package:
    ensure  => 'present',
  }

  file { $ipxe_root:
    ensure => directory,
  }

  case $bsys::params::osfam {
    'RedHat': {
      ['undionly.kpxe', 'ipxe.efi'].each |$ipxe_file| {
        file { "${ipxe_root}/${ipxe_file}":
          ensure  => file,
          source  => "file:///usr/share/ipxe/${ipxe_file}",
          require => Package[$ipxe_package],
        }
      }
    }
    'Debian': {
      ['undionly.kpxe', 'ipxe.efi'].each |$ipxe_file| {
        file { "${ipxe_root}/${ipxe_file}":
          ensure  => file,
          source  => "file:///usr/lib/ipxe/${ipxe_file}",
          require => Package[$ipxe_package],
        }
      }
    }
  }

  file { "${tftp_root}/boot/install.ipxe":
    ensure  => file,
    content => file('pxe/install.ipxe'),
  }
}
