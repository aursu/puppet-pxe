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
    '22.04'   => $pxe::params::ubuntu22_current_version,
    'jammy'   => $pxe::params::ubuntu22_current_version,
    '24.04.1' => $version,
    default   => $pxe::params::ubuntu24_current_version,
  }

  $base_directory        = "${tftp_root}/boot/ubuntu/${release_version}"
  $distro_base_directory = "${storage_directory}/ubuntu/${release_version}"

  $iso_filename = "ubuntu-${release_version}-live-server-${arch}.iso"
  $iso_location = "${distro_base_directory}/${iso_filename}"

  $arch_directory = "${base_directory}/netboot/${arch}"
  $mount_point    = "/mnt/iso/ubuntu/${release_version}"

  file { [
      "${base_directory}/netboot",
      $arch_directory,
    $mount_point]:
      ensure => directory,
  }

  $checksum_value = $release_version ? {
    '22.04.5' => '9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0',
    '24.04.1' => 'e240e4b801f7bb68c20d1356b60968ad0c33a41d00d828e74ceb3364a0317be9',
    '24.04.2' => 'd6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d',
  }

  # https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso
  if $release_version in [$pxe::params::ubuntu22_current_version, $pxe::params::ubuntu24_current_version] {
    $release_source = "https://releases.ubuntu.com/${release_version}/${iso_filename}"
  }
  # https://old-releases.ubuntu.com/releases/24.04.1/ubuntu-24.04.1-live-server-amd64.iso
  else {
    $release_source = "https://old-releases.ubuntu.com/releases/${release_version}/${iso_filename}"
  }

  file { $iso_location:
    ensure         => 'file',
    checksum       => 'sha256',
    checksum_value => $checksum_value,
    source         => $release_source,
  }
  -> mount { $mount_point:
    ensure  => mounted,
    fstype  => 'iso9660',
    options => 'defaults,ro',
    device  => $iso_location,
  }
  -> file { "${arch_directory}/vmlinuz":
    source => "file://${mount_point}/casper/vmlinuz",
  }
  -> file { "${arch_directory}/initrd":
    source => "file://${mount_point}/casper/initrd",
  }
}
