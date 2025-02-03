# @summary PXE server setup
#
# PXE server setup
#
# @example
#   include pxe::server
class pxe::server (
  Stdlib::Fqdn $server_name,
  Stdlib::Port $web_port = 80,
  Boolean $manage_web_service = true,
  Boolean $manage_web_user = true,
  Optional[String] $root_authorized_keys = undef,
  Optional[String] $puppet_local_config = undef,
  Boolean $enable = true,
  Boolean $rocky8_download = false,
  Boolean $rocky9_download = true,
  Boolean $post_install_puppet_agent = false,
  Variant[Enum['7', '8'], Integer[7, 8]] $puppet_version = 8,
) {
  include pxe::storage
  include pxe::params

  $puppet_platform = "puppet${puppet_version}"

  $storage_directory = $pxe::params::storage_directory
  $tftp_root         = $pxe::params::tftp_root

  $install_server    = $server_name

  # Web service
  if $manage_web_service {
    class { 'pxe::profile::httpd':
      listen_port  => $web_port,
      servername   => $server_name,
      manage_group => $manage_web_user,
      manage_user  => $manage_web_user,
      enable       => $enable,
    }

    # create apache user before storage setup
    Class['pxe::profile::httpd'] -> Class['pxe::storage']
  }

  apache::custom_config { 'diskless':
    content => template('pxe/httpd/diskless.erb'),
  }

  # CGI trigger for host installation
  file { "${storage_directory}/exec/move.cgi":
    ensure  => file,
    content => file('pxe/scripts/move.cgi'),
    mode    => '0755',
  }

  # /usr/bin/nmap required for repository installation and update scripts
  package { 'nmap':
    ensure => present,
  }

  # create /root/bin directory if not existing
  exec { 'mkdir -p /root/bin':
    path    => '/usr/bin:/bin',
    creates => '/root/bin',
  }

  if $post_install_puppet_agent {
    file { "${storage_directory}/configs/assets/${puppet_platform}-keyring.asc":
      ensure  => file,
      content => file('pxe/assets/puppet-keyring.asc'),
      mode    => '0644',
    }

    # install Puppet repository
    file { "${storage_directory}/configs/assets/${puppet_platform}-release.repo":
      ensure  => file,
      content => epp('pxe/puppet/repo.epp', {
          version => "${puppet_version}", # lint:ignore:only_variable_string
      }),
      mode    => '0644',
    }

    file { "${storage_directory}/configs/assets/RPM-GPG-KEY-2025-04-06-${puppet_platform}-release":
      ensure  => file,
      content => file('pxe/assets/RPM-GPG-KEY-2025-04-06-puppet-release'),
      mode    => '0644',
    }

    $rpm_gpg_key_url  = "http://${install_server}/ks/assets/RPM-GPG-KEY-2025-04-06-${puppet_platform}-release"
    $puppet_repo_url  = "http://${install_server}/ks/assets/${puppet_platform}-release.repo"
    $puppet_repo_path = "/etc/yum.repos.d/${puppet_platform}-release.repo"
    $rpm_gpg_key_path = "/etc/pki/rpm-gpg/RPM-GPG-KEY-2025-04-06-${puppet_platform}-release"

    case $puppet_platform {
      'puppet7': {
        $agent_version = '7.34.0-1'
      }
      'puppet8': {
        $agent_version = '8.10.0-1'
      }
      default: {
        fail('Not supported Puppet platform provided')
      }
    }
  }

  if $root_authorized_keys {
    file { "${storage_directory}/configs/assets/root.authorized_keys":
      ensure  => file,
      content => file($root_authorized_keys),
      mode    => '0644',
    }
  }

  if $puppet_local_config {
    file { "${storage_directory}/configs/assets/puppet.conf":
      ensure  => file,
      content => file($puppet_local_config),
      mode    => '0644',
    }
  }

  # Default asstes
  # Default kickstart http://<install-server>/ks/default.cfg (CentOS 8 installation)
  # python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
  file { "${storage_directory}/configs/default.cfg":
    ensure  => file,
    content => template('pxe/default-centos-8-x86_64-ks.cfg.erb'),
  }

  file { "${storage_directory}/configs/default-8-x86_64.cfg":
    ensure  => file,
    content => template('pxe/default-centos-8-x86_64-ks.cfg.erb'),
  }
}
