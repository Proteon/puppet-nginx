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
    $logrotate_paths         = '/opt/www/sites/*/logs/*.log',
    $logrotate_count         = 52, # -1 to disable the removal of the logs
    $additional_config       = '',
    $version                 = held,
    $package                 = 'nginx', # may override with for instance 'nginx-extras' or 'nginx-light' 
    $use_nginx_repository    = false,
) {

    if (!is_numeric($logrotate_count)) {
        fail('logrotate_count must be numeric')
    }

    # General
    File {
        owner   => 'root',
        group   => 'www-data',
        notify  => Exec['nginx-reload'],
        require => Package['nginx'],
    }

    if ($use_nginx_repository == true or $use_nginx_repository == 'true') {
    
        apt::source { 'nginx':
            location   => 'http://ppa.launchpad.net/nginx/stable/ubuntu',
            release    => $::lsbdistcodename,
            repos      => 'main',
            key        => 'C300EE8C',
            key_server => 'keys.gnupg.net',
        }
    
    }

    $ensure = $::nginxversion ? {
        $version => held,
        default  => $version,
    }

    package { 'nginx':
        name    => $package,
        ensure  => $ensure,
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
        '/etc/nginx/upstreams.d',
        '/opt/www', # F: this makes it mutually exclusive with our apache module
        '/opt/www/sites',
    ]:
        ensure  => directory,
    }

    file { '/etc/logrotate.d/nginx':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('nginx/nginx.logrotate.erb'),
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
          '/etc/nginx/sites-available/default',
          '/etc/nginx/sites-enabled/default',
          '/etc/nginx/conf.d/example_ssl.conf']:
            ensure  => absent,
    }

}
