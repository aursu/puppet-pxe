# @summary Remove everything this module deploys from a host
#
# The inverse of `pxe::server` and friends: purges the packages, unmounts the
# installer ISOs and deletes the storage and TFTP trees, so a host that used to
# be a PXE install server keeps nothing behind.
#
# Intended for retiring a PXE server whose configuration can be rebuilt from
# this module later. It removes **payload as well as configuration** — the
# storage directory typically holds several GB of distribution trees and ISO
# images, and none of it is recoverable from here.
#
# ⚠ Do not declare this together with `pxe::server`, `pxe::tftp`, `pxe::ipxe`
# or `pxe::dhcp`. They declare the same packages with `ensure => present`, so
# the catalogue fails with a duplicate declaration — which is the right
# outcome: both intentions cannot be true on one host.
#
# ## What it deliberately does not touch
#
# * **nginx.** `pxe::nginx` only declares an `nginx::resource::server`; it never
#   installs nginx, so purging the package here could take down an unrelated
#   service. Drop `pxe::nginx` from the node to remove the vhost instead.
# * **`nmap`**, unless `remove_nmap` is set — `pxe::server` installs it, but it
#   is a general-purpose tool other things may rely on.
#
# @param remove_tftp Purge the TFTP server package (and `xinetd` on RedHat).
# @param remove_ipxe Purge the iPXE boot image package.
# @param remove_dhcp
#   Purge the DHCP server package. ⚠ On a host serving DHCP for a real network
#   this stops address assignment — confirm nothing else depends on it.
# @param remove_web
#   Purge the web server `pxe::profile::httpd` installs. ⚠ Check it is not
#   serving anything else: this module configures it through
#   `apache::custom_config`, so other vhosts may be present.
# @param remove_storage Delete the storage directory, TFTP root and ISO root.
# @param remove_nmap Purge `nmap` too. Off by default.
# @param storage_directory Storage root to delete.
# @param tftp_root TFTP root to delete.
# @param iso_root Root under which this module mounts installer ISOs.
# @param packages
#   Explicit package list, replacing everything the flags above derive. Use it
#   when a host installed something under a non-default name.
#
# @example Retire a PXE server completely
#   include pxe::decommission
#
# @example Keep the web server, which serves something else as well
#   class { 'pxe::decommission':
#     remove_web => false,
#   }
class pxe::decommission (
  Boolean $remove_tftp = true,
  Boolean $remove_ipxe = true,
  Boolean $remove_dhcp = true,
  Boolean $remove_web = true,
  Boolean $remove_storage = true,
  Boolean $remove_nmap = false,
  Stdlib::Unixpath $storage_directory = $pxe::params::storage_directory,
  Optional[Stdlib::Unixpath] $tftp_root = $pxe::params::tftp_root,
  Stdlib::Unixpath $iso_root = '/mnt/iso',
  Optional[Array[String[1]]] $packages = undef,
) inherits pxe::params {
  include bsys::params

  case $bsys::params::osfam {
    'RedHat': {
      $dhcp_package    = 'dhcp-server'
      $web_package     = 'httpd'
      $xinetd_packages = ['xinetd']
    }
    'Debian': {
      $dhcp_package    = 'isc-dhcp-server'
      $web_package     = 'apache2'
      $xinetd_packages = []
    }
    default: {
      fail("pxe::decommission does not support osfamily ${bsys::params::osfam}")
    }
  }

  if $remove_tftp and $pxe::params::tftp_server_package =~ String[1] {
    $tftp_packages = [$pxe::params::tftp_server_package] + $xinetd_packages
  }
  else {
    $tftp_packages = []
  }

  if $remove_ipxe and $pxe::params::ipxe_package =~ String[1] {
    $ipxe_packages = [$pxe::params::ipxe_package]
  }
  else {
    $ipxe_packages = []
  }

  if $remove_dhcp {
    $dhcp_packages = [$dhcp_package]
  }
  else {
    $dhcp_packages = []
  }

  if $remove_web {
    $web_packages = [$web_package]
  }
  else {
    $web_packages = []
  }

  if $remove_nmap {
    $nmap_packages = ['nmap']
  }
  else {
    $nmap_packages = []
  }

  $derived_packages = $tftp_packages + $ipxe_packages + $dhcp_packages + $web_packages + $nmap_packages
  $purge_packages = $packages.lest || { $derived_packages }

  # No Service resources: purging stops and disables the units, and a Service
  # resource naming a unit that no longer exists fails on every later run.
  package { $purge_packages:
    ensure => purged,
    tag    => ['pxe_decommission_package'],
  }

  if $remove_storage {
    if $tftp_root =~ Stdlib::Unixpath {
      $removable = [$storage_directory, $iso_root, $tftp_root]
    }
    else {
      $removable = [$storage_directory, $iso_root]
    }

    # Unmount first. pxe::ubuntu mounts installer ISOs under iso_root, and the
    # ISO files themselves live inside the storage directory - deleting either
    # while still mounted leaves the host with stale mounts.
    $mounted_below = "findmnt --raw --noheadings --output TARGET | grep '^${iso_root}'"

    exec { 'pxe::decommission unmount ISOs':
      # Deepest first, so nested mounts unmount cleanly.
      command => "${mounted_below} | sort --reverse | xargs --no-run-if-empty --max-args=1 umount",
      onlyif  => "${mounted_below} | grep --quiet .",
      path    => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
      tag     => ['pxe_decommission_umount'],
    }

    # `rm -rf` rather than a recursive file resource: these trees hold
    # distribution mirrors and ISO images, and recursing several GB through
    # Puppet's file type is prohibitively slow for a one-off removal.
    $removable.each |$path| {
      exec { "pxe::decommission remove ${path}":
        command => "rm -rf ${path}",
        onlyif  => "test -d ${path}",
        path    => ['/usr/bin', '/bin'],
        tag     => ['pxe_decommission_remove'],
      }
    }

    Package<| tag == 'pxe_decommission_package' |>
    -> Exec<| tag == 'pxe_decommission_umount' |>
    -> Exec<| tag == 'pxe_decommission_remove' |>
  }
}
