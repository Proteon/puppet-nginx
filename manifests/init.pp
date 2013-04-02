# Base Nginx class
# TODO add parameter docs
# TODO add usage examples
class nginx (
    $nginx_user              = 'www-data',
    $worker_processes        = '1',
    $worker_connections      = '1024',
    $client_max_body_size    = '32M',
    $client_body_buffer_size = '256k',
    $error_loglevel          = 'warn', # debug | info | notice | warn | error | crit | alert | emerg
    $additional_config       = '',
    $version                 = held,
) {
    # General
    File {
        owner   => 'root',
        group   => 'www-data',
        notify  => Exec['nginx-reload'],
        require => Package['nginx'],
    }

    package { 'nginx':
        ensure  => $version,
    }

    # Logrotate
    if ! defined(Package['logrotate']) {
        package { 'logrotate':
            ensure => present,
        }
    }

    # Service
    class { 'nginx::service':
        require => Class['nginx'],
    }

    # TODO: put all parameters in an nginx::params class
    # Some default directory's
    file { [
        '/etc/nginx/conf.d',
        '/etc/nginx/sites-available',
        '/etc/nginx/sites-enabled',
        # '/etc/nginx/upstreams.d', # maybe for later, when we setup loadbalancing
        '/opt/www', # F: this makes it mutually exclusive with our apache module
        '/opt/www/sites',
    ]:
        ensure  => directory,
    }

    file { '/etc/logrotate.d/nginx':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/nginx/nginx.logrotate',
        require => Package['logrotate'],
    }

    # Main Configuration
    file { '/etc/nginx/nginx.conf':
        content => template('nginx/nginx.conf.erb'),
        notify  => Service['nginx'],
    }

    # Delete some default configuration files
    file {
        [ '/etc/nginx/conf.d/default.conf',
          '/etc/nginx/conf.d/example_ssl.conf']:
            ensure  => absent,
    }

}
