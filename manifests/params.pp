# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pxe::params
class pxe::params {
  $storage_directory = lookup('pxe::params::storage_directory', Stdlib::Unixpath, 'first', '/diskless')

  $stream9_current_version = '9-20250124.0'
  $stream10_current_version = '10-20250123.0'

  $rocky8_current_version = '8.10.20240528'
  $rocky9_current_version = '9.5.20241118'
}
