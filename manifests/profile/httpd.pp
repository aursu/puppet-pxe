# @summary Setup httpd core in its minimal setup
#
# Setup httpd core in its minimal setup + CGI
#
# @example
#   include pxe::profile::httpd
class pxe::profile::httpd (
  Stdlib::Port $listen_port = 80,
  String  $servername = 'localhost',
  Boolean $manage_group = true,
  Boolean $manage_user = true,
  String  $conf_template = 'pxe/httpd/httpd.conf.epp',
) {
  $docroot = '/var/www/html'

  class { 'apache':
    mpm_module             => false,
    default_mods           => [],
    use_systemd            => true,
    default_vhost          => false,
    default_ssl_vhost      => false,
    server_signature       => 'Off',
    trace_enable           => 'Off',
    servername             => $servername,
    timeout                => 60,
    keepalive              => 'On',
    max_keepalive_requests => 100,
    keepalive_timeout      => 5,
    root_directory_secured => true,
    docroot                => $docroot,
    default_charset        => 'UTF-8',
    conf_template          => $conf_template,
    mime_types_additional  => undef,
    service_manage         => true,
    service_ensure         => 'running',
    service_enable         => true,
    manage_group           => $manage_group,
    manage_user            => $manage_user,
  }
  contain apache

  # if `apache` module >= 11 
  if defined('$apache::parameters') {
    apache::custom_config { 'docroot':
      priority => '00',
      content  => epp('pxe/httpd/docroot.epp', {
          docroot => $docroot,
      }),
    }
  }

  class { 'apache::mod::prefork':
    startservers        => 5,
    minspareservers     => 5,
    maxspareservers     => 10,
    serverlimit         => 256,
    maxclients          => 256,
    maxrequestsperchild => 0,
    notify              => Class['Apache::Service'],
  }

  apache::listen { "${listen_port}": # lint:ignore:only_variable_string
    notify => Class['Apache::Service'],
  }

  # apache::mod::mime included by SSL module
  class { 'apache::mod::ssl':
    ssl_compression            => false,
    ssl_cipher                 => 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384', # lint:ignore:140chars
    ssl_protocol               => ['all', '-SSLv3', '-TLSv1', '-TLSv1.1'],
    ssl_random_seed_bytes      => 1024,
    ssl_mutex                  => 'default',
    ssl_stapling               => true,
    ssl_stapling_return_errors => false,
    notify                     => Class['Apache::Service'],
  }

  class { 'apache::mod::dir':
    indexes => ['index.html'],
    notify  => Class['Apache::Service'],
  }

  class { 'apache::mod::mime_magic':
    magic_file => 'conf/magic',
    notify     => Class['Apache::Service'],
  }

  class { 'apache::mod::cgi':
    notify => Class['Apache::Service'],
  }

  include apache::mod::headers
  include apache::mod::rewrite
  include apache::mod::alias
}
