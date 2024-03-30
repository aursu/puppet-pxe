# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pxe::params
class pxe::params {
  $storage_directory = lookup('pxe::params::storage_directory', Stdlib::Unixpath, 'first', '/diskless')

  $centos7_current_version = '7.9.2009'
  $stream8_current_version = '8-stream'
  $stream9_current_version = '9-stream'
}
