# Setup GRUB2 for booting over network
#
# @summary Setup GRUB2 for booting over network
#
# @example
#   include pxe::grub
#
class pxe::grub (
  Stdlib::Unixpath $net_directory = $pxe::params::tftp_root,
) inherits pxe::params {
  include bsys::params

  case $bsys::params::osfam {
    'Debian': {
      # GRUB2 Modules installation
      package {
        default:
          ensure => 'present',
          ;
        'grub-common': ;
        ['grub-efi-ia32-bin', 'grub-pc-bin', 'grub-efi-amd64-bin']:
          require => Package['grub-common'],
          ;
      }

      exec { "grub-mknetdir --net-directory=${net_directory} --subdir=boot/grub -d /usr/lib/grub/x86_64-efi":
        path    => '/usr/bin:/bin',
        creates => "${net_directory}/boot/grub/x86_64-efi/core.efi",
        require => Package['grub-efi-amd64-bin'],
      }

      exec { "grub-mknetdir --net-directory=${net_directory} --subdir=boot/grub -d /usr/lib/grub/i386-pc":
        path    => '/usr/bin:/bin',
        creates => "${net_directory}/boot/grub/i386-pc/core.0",
        require => Package['grub-pc-bin'],
        before  => File["${net_directory}/boot/grub/grub.cfg"],
      }

      exec { "grub-mknetdir --net-directory=${net_directory} --subdir=boot/grub -d /usr/lib/grub/i386-efi":
        path    => '/usr/bin:/bin',
        creates => "${net_directory}/boot/grub/i386-efi/core.efi",
        require => Package['grub-efi-ia32-bin'],
      }

      $default_kernel = '/boot/ubuntu/noble/casper/vmlinuz'
      $default_initimg = '/boot/ubuntu/noble/casper/initrd'
    }
    'RedHat': {
      # GRUB2 Modules installation
      package {
        default:
          ensure  => 'present',
          ;
        'grub2-tools-extra':
          ;
        ['grub2-efi-ia32-modules', 'grub2-pc-modules', 'grub2-efi-x64-modules']:
          require => Package['grub2-tools-extra'],
          ;
      }

      # GRUB2 TFTP data
      exec { 'grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=boot/grub -d /usr/lib/grub/x86_64-efi':
        path    => '/usr/bin:/bin',
        creates => '/var/lib/tftpboot/boot/grub/x86_64-efi/core.efi',
        require => Package['grub2-efi-x64-modules'],
      }

      exec { 'grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=boot/grub -d /usr/lib/grub/i386-pc':
        path    => '/usr/bin:/bin',
        creates => '/var/lib/tftpboot/boot/grub/i386-pc/core.0',
        require => Package['grub2-pc-modules'],
        before  => File['/var/lib/tftpboot/boot/grub/grub.cfg'],
      }

      exec { 'grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=boot/grub -d /usr/lib/grub/i386-efi':
        path    => '/usr/bin:/bin',
        creates => '/var/lib/tftpboot/boot/grub/i386-efi/core.efi',
        require => Package['grub2-pc-modules'],
      }

      # GRUB configuration files
      # MAC: 00:50:56:8e:5b:30
      # IP: 10.55.156.40 (hex: 0A.37.9C.28)
      # /boot/grub/i386-pc/grub.cfg-01-00-50-56-8e-5b-30
      # /boot/grub/i386-pc/grub.cfg-01-00-50-56-8e-5b-30
      # /boot/grub/i386-pc/grub.cfg-0A379C28
      # /boot/grub/i386-pc/grub.cfg-0A379C28
      # /boot/grub/i386-pc/grub.cfg-0A379C2
      # /boot/grub/i386-pc/grub.cfg-0A379C2
      # /boot/grub/i386-pc/grub.cfg-0A379C
      # /boot/grub/i386-pc/grub.cfg-0A379C
      # /boot/grub/i386-pc/grub.cfg-0A379
      # /boot/grub/i386-pc/grub.cfg-0A379
      # /boot/grub/i386-pc/grub.cfg-0A37
      # /boot/grub/i386-pc/grub.cfg-0A37
      # /boot/grub/i386-pc/grub.cfg-0A3
      # /boot/grub/i386-pc/grub.cfg-0A3
      # /boot/grub/i386-pc/grub.cfg-0A
      # /boot/grub/i386-pc/grub.cfg-0A
      # /boot/grub/i386-pc/grub.cfg-0
      # /boot/grub/i386-pc/grub.cfg-0
      # /boot/grub/i386-pc/grub.cfg
      #
      # cat boot/grub/i386-pc/grub.cfg
      # source boot/grub/grub.cfg

      # TODO: move accent to CentOS Stream 10 or Rocky Linux 9
      $default_kernel = '/boot/centos/10-stream/BaseOS/x86_64/os/images/pxeboot/vmlinuz'
      $default_initimg = '/boot/centos/10-stream/BaseOS/x86_64/os/images/pxeboot/initrd.img'
    }
  }

  file { "${net_directory}/boot/grub/grub.cfg":
    ensure  => file,
    content => template('pxe/grub.cfg.erb'),
  }
}
