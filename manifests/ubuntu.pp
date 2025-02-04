# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   pxe::ubuntu { 'namevar': }
define pxe::ubuntu (
  Pxe::Ubuntu_version $version = $name,
  Enum['amd64', 'arm64'] $arch = 'amd64',
) {
  include pxe::storage
  include pxe::params

  $storage_directory  = $pxe::params::storage_directory
  $tftp_root = $pxe::params::tftp_root

  $release_version = $version ? {
    'jammy' => $pxe::params::ubuntu22_current_version,
    'noble' => $pxe::params::ubuntu24_current_version,
  }

  $base_directory    = "${tftp_root}/boot/ubuntu/${release_version}"
  $distro_base_directory = "${storage_directory}/ubuntu/${release_version}"

  # https://releases.ubuntu.com/24.04.1/ubuntu-24.04.1-live-server-amd64.iso
  $ubuntu_url = "https://releases.ubuntu.com/${release_version}/ubuntu-${release_version}-live-server-${arch}.iso"

  $arch_directory        = "${base_directory}/netboot/${arch}"

  file { [
      "${base_directory}/netboot",
    $arch_directory]:
      ensure => directory,
  }
}
