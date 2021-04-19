# @summary PXE server setup
#
# PXE server setup
#
# @example
#   include pxe::server
class pxe::server (
  Stdlib::Fqdn
          $server_name,
  Stdlib::Port
          $web_port              = 80,
  Boolean $manage_web_service    = true,
  Boolean $manage_web_user       = true,
  Optional[String]
          $root_authorized_keys  = undef,
  Optional[String]
          $puppet_local_config   = undef,
  Boolean $enable                = true,
  Boolean $centos6_download      = false,
  Boolean $centos7_download      = true,
  Boolean $install_puppet_agent  = false,
  Enum['puppet5', 'puppet7']
          $puppet_platform       = 'puppet7',
  Boolean $centos6_support       = $pxe::centos6_support,
)
{
  include pxe::storage
  include pxe::params

  $storage_directory       = $pxe::params::storage_directory
  $centos_version          = $pxe::params::centos7_current_version
  $centos8_version         = $pxe::params::centos8_current_version
  $stream_version          = $pxe::params::stream_current_version
  $install_server          = $server_name

  if $centos7_download and $enable {
    pxe::centos { $centos_version: }
  }

  # Web service
  if $manage_web_service {
    class { 'pxe::profile::httpd':
      listen_port  => $web_port,
      servername   => $server_name,
      manage_group => $manage_web_user,
      manage_user  => $manage_web_user,
      enable       => $enable,
    }
  }

  apache::custom_config { 'diskless':
    content => template('pxe/httpd.conf.diskless.erb'),
  }

  # Default asstes
  # Default kickstart http://<install-server>/ks/default.cfg (CentOS 7 installation)
  # python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
  file{ "${storage_directory}/configs/default.cfg":
    ensure  => file,
    content => template('pxe/default-centos-7-x86_64-ks.cfg.erb'),
  }

  file{ "${storage_directory}/configs/default-8-x86_64.cfg":
    ensure  => file,
    content => template('pxe/default-centos-8-x86_64-ks.cfg.erb'),
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

  # repository installation script
  file { '/root/bin/install-7-x86_64.sh':
    ensure  => file,
    content => file('pxe/scripts/install.sh'),
    mode    => '0500',
  }

  # repository update script (including EPEL and rpmforge)
  file { '/root/bin/update-7-x86_64.sh':
    ensure  => file,
    content => file('pxe/scripts/update.sh'),
    mode    => '0500',
  }

  if $centos6_support {
    $centos6_version = $pxe::params::centos6_version

    if $centos6_download and $enable {
      pxe::centos { $centos6_version: }
    }

    file{ "${storage_directory}/configs/default-6-x86_64.cfg":
      ensure  => file,
      content => template('pxe/default-centos-6-x86_64-ks.cfg.erb'),
    }
  }

  if $install_puppet_agent {
    # install Puppet repository
    file { "${storage_directory}/configs/assets/${puppet_platform}.repo":
      ensure  => file,
      content => file("pxe/assets/${puppet_platform}.repo"),
      mode    => '0644',
    }

    # install Puppet repository GPG key
    # https://puppet.com/docs/puppet/7.5/install_puppet.html#enable_the_puppet_platform_repository
    # https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
    file { "${storage_directory}/configs/assets/RPM-GPG-KEY-puppet":
      ensure  => file,
      content => file('pxe/assets/RPM-GPG-KEY-puppet'),
      mode    => '0644',
    }

    file { "${storage_directory}/configs/assets/RPM-GPG-KEY-2025-04-06-puppet7-release":
      ensure  => file,
      content => file('pxe/assets/RPM-GPG-KEY-2025-04-06-puppet7-release'),
      mode    => '0644',
    }

    $rpm_gpg_key_url  = "http://${install_server}/ks/assets/RPM-GPG-KEY-puppet"
    $puppet_repo_url  = "http://${install_server}/ks/assets/${puppet_platform}.repo"
    $puppet_repo_path = "/etc/yum.repos.d/${puppet_platform}.repo"

    case $puppet_platform {
      'puppet5': {
        $agent_version = '5.5.22-1'
        $rpm_gpg_key_path = '/etc/pki/rpm-gpg/RPM-GPG-KEY-puppet5'
      }
      'puppet7': {
        $agent_version = '7.5.0-1'
        $rpm_gpg_key_path = '/etc/pki/rpm-gpg/RPM-GPG-KEY-puppet7-release'
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
}
