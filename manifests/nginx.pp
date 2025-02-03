# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pxe::nginx
class pxe::nginx (
  Stdlib::Fqdn $server_name,
  Array[Stdlib::IP::Address] $resolver,
  Stdlib::Port $listen_port = 80,
  Stdlib::Port $proxy_port  = 8080,
) {
  $location_proxy_handler = {
    proxy_set_header  => [
      'Host $host',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
    ],
    proxy_pass_header => [
      'Server',
    ],
    proxy             => "http://\$server_addr:${proxy_port}",  # lint:ignore:variables_not_enclosed
  }

  nginx::resource::server { 'pxe':
    server_name => [$server_name],
    listen_port => $listen_port,

    error_log   => '/var/log/nginx/pxe.error_log info',
    access_log  => {
      '/var/log/nginx/pxe.access_log' => 'combined',
    },

    resolver    => $resolver,

    locations   => {
      'pxe-default' => { location  => '/' } + $location_proxy_handler,
    },
  }
}
