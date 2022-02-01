# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pxe::params
class pxe::params {
  $storage_directory = lookup('pxe::params::storage_directory', Stdlib::Unixpath, 'first', '/diskless')

  $centos6_version = '6.10'
  $centos7_current_version = '7.9.2009'
  $centos8_current_version = '8.5.2111'
  $stream_current_version  = '8-stream'
}
