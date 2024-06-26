# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   pxe::centos { 'namevar': }
define pxe::centos (
  Pxe::Centos_version $version = $name,
  Enum['x86_64', 'i386', 'aarch64'] $arch = 'x86_64',
) {
  # TODO: CentOS 8 setup

  include pxe::storage
  include pxe::params

  $storage_directory  = $pxe::params::storage_directory

  $centos7_current_version = $pxe::params::centos7_current_version
  $stream8_current_version = $pxe::params::stream8_current_version
  $stream9_current_version = $pxe::params::stream9_current_version

  $real_version = $version ? {
    '7'     => $centos7_current_version,
    /^8/    => $stream8_current_version,
    /^9/    => $stream9_current_version,
    default => $version
  }

  $major_version = $real_version ? {
    /^7/ => 7,
    # including 8-stream
    /^8/ => 8,
    # including 9-stream
    /^9/ => 9,
  }

  if $major_version > 7 {
    $repo = 'BaseOS'
    $arch_path = "${repo}/${arch}"
    $repo_path = "${repo}/${arch}/os"
  }
  else {
    $repo = 'os'
    $arch_path = "${repo}/${arch}"
    $repo_path = $arch_path
  }

  $base_directory    = "/var/lib/tftpboot/boot/centos/${real_version}"
  $distro_base_directory = "${storage_directory}/centos/${real_version}"

  case $real_version {
    $centos7_current_version, $stream8_current_version: {
      $centos_url = "http://mirror.centos.org/centos/${real_version}/${repo_path}"
    }
    $stream9_current_version: {
      $centos_url = "http://mirror.stream.centos.org/${real_version}/${repo_path}"
    }
    default: {
      file { [$base_directory, $distro_base_directory]:
        ensure => directory,
      }

      $centos_url = "http://vault.centos.org/${version}/${repo_path}"
    }
  }

  $arch_directory        = "${base_directory}/${arch_path}"
  $repo_directory        = "${base_directory}/${repo_path}"
  $images_directory      = "${arch_directory}/images"
  $pxeboot_directory     = "${images_directory}/pxeboot"
  $distro_arch_directory = "${distro_base_directory}/${arch_path}"
  $distro_repo_directory = "${distro_base_directory}/${repo_path}"

  file { [
      "${base_directory}/${repo}",
      $arch_directory,
      $repo_directory,
      $images_directory,
      $pxeboot_directory,
      "${distro_base_directory}/${repo}",
      $distro_arch_directory,
    $distro_repo_directory].unique: # lint:ignore:unquoted_resource_title
      ensure => directory,
  }

  archive { "${pxeboot_directory}/vmlinuz":
    ensure => present,
    source => "${centos_url}/images/pxeboot/vmlinuz",
  }

  archive { "${pxeboot_directory}/initrd.img":
    ensure => present,
    source => "${centos_url}/images/pxeboot/initrd.img",
  }

  # /diskless/centos/7/os/x86_64/LiveOS/squashfs.img
  if $major_version == 7 {
    file { "${distro_repo_directory}/LiveOS":
      ensure => directory,
    }

    archive { "${distro_repo_directory}/LiveOS/squashfs.img":
      ensure => present,
      source => "${centos_url}/LiveOS/squashfs.img",
    }
  }
}
