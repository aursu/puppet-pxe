# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   pxe::client_config { 'namevar': }
define pxe::client_config (
  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-howto
  Stdlib::Fqdn $install_server,
  Stdlib::Fqdn $hostname = $name,
  Optional[Stdlib::Unixpath] $kernel = undef,
  Optional[Stdlib::Unixpath] $initimg = undef,
  Enum['x86_64', 'i386'] $arch = 'x86_64',
  Optional[String] $autofile = undef,
  Optional[String] $osrelease = undef,
  # Only applicable to CentOS 6 systems
  Optional[String] $interface = 'eth0',
  # Kickstart settings
  Boolean $centos = true,
  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-disabling_consistent_network_device_naming
  # https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/
  Boolean $disable_biosdevname = true,
  Boolean $ipxe = false,
) {
  include pxe::params

  $tftp_root = $pxe::params::tftp_root

  $default_kernel = '/boot/centos/10-stream/BaseOS/x86_64/os/images/pxeboot/vmlinuz'
  $default_initimg = '/boot/centos/10-stream/BaseOS/x86_64/os/images/pxeboot/initrd.img'

  if $centos {
    if $osrelease {
      $centos_version = $osrelease ? {
        Pxe::Centos_version => $osrelease,
        default             => fail('Illegal value for $osrelease parameter'),
      }

      case $centos_version {
        '9-stream', '10-stream': {
          $major_version = $centos_version
        }
        default: {
          $major_version = $centos_version ? {
            /^10/ => 10,
            /^9/ => 9,
          }
        }
      }
    }
    else {
      $centos_version = undef
      $major_version = undef
    }

    if $autofile {
      $ks_filename = $autofile
    }
    elsif $centos_version {
      $ks_filename = "${centos_version}-${arch}" ? {
        '10-x86_64'        => 'default.cfg',
        '10-stream-x86_64' => 'default.cfg',
        '9-x86_64'         => 'default-9-x86_64.cfg',
        '9-stream-x86_64'  => 'default-9-x86_64.cfg',
        default            => "default-${centos_version}-${arch}.cfg",
      }
    }
    else {
      $ks_filename = 'default.cfg'
    }
  }

  if $kernel {
    $boot_kernel = $kernel
  }
  elsif $centos and $major_version {
    $boot_kernel = "/boot/centos/${major_version}/os/${arch}/images/pxeboot/vmlinuz"
  }
  else {
    if $ipxe {
      $boot_kernel = $default_kernel
    }
    else {
      $boot_kernel = undef
    }
  }

  if $initimg {
    $boot_initimg = $initimg
  }
  elsif $centos and $major_version {
    $boot_initimg = "/boot/centos/${major_version}/os/${arch}/images/pxeboot/initrd.img"
  }
  else {
    if $ipxe {
      $boot_initimg = $default_initimg
    }
    else {
      $boot_initimg = undef
    }
  }

  # TODO: iPXE
  # #!ipxe
  # kernel http://rpmb.carrierzone.com/boot/centos/7.9.2009/os/x86_64/images/pxeboot/vmlinuz ip=dhcp ksdevice= inst.ks=http://rpmb.carrierzone.com/ks/default.cfg net.ifnames=0 biosdevname=0
  # initrd http://rpmb.carrierzone.com/boot/centos/7.9.2009/os/x86_64/images/pxeboot/initrd.img
  # boot

  # $hostname should match DHCP option host-name or the host declaration name
  # (if one) if use-host-decl-names is on
  file { "/var/lib/pxe/${hostname}.cfg":
    ensure  => file,
    content => template('pxe/host.cfg.erb'),
    notify  => Exec["${tftp_root}/boot/install/${hostname}.cfg"],
  }

  exec { "${tftp_root}/boot/install/${hostname}.cfg":
    command     => "rm -f ${tftp_root}/boot/install/${hostname}.cfg",
    refreshonly => true,
    path        => '/usr/bin:/bin',
    onlyif      => "test -f ${tftp_root}/boot/install/${hostname}.cfg",
  }
}
