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
  include pxe::storage
  include pxe::params

  $storage_directory  = $pxe::params::storage_directory
  $tftp_root = $pxe::params::tftp_root

  $common_version = $version ? {
    /^9/    => '9-stream',
    /^10/   => '10-stream',
  }

  $repo = 'BaseOS'
  $arch_path = "${repo}/${arch}"
  $repo_path = "${repo}/${arch}/os"

  $base_directory    = "${tftp_root}/boot/centos/${common_version}"
  $distro_base_directory = "${storage_directory}/centos/${common_version}"

  $centos_url = "http://mirror.stream.centos.org/${common_version}/${repo_path}"

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
}
