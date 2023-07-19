# @summary Puppet ENC repository setup
#
# Fetch Puppet ENC repository setup to PXE server
#
# @example
#   include pxe::enc
class pxe::enc (
  String  $repo_source,
  String  $repo_revision  = 'master',
  Optional[Stdlib::Unixpath]
          $repo_identity  = undef,
) {
  include pxe::storage

  vcsrepo { '/var/lib/pxe/enc':
    ensure     => latest,
    provider   => 'git',
    source     => $repo_source, # eg git@git.domain.tld:project/enc.git
    revision   => $repo_revision,
    submodules => false,
    identity   => $repo_identity,
  }
}
