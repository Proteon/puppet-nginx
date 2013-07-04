# Main vhost define for Nginx
# Default usage when using 1 servername/alias is to set the resource name to
# the domainname. If more domainnames are required then explicitly pass a
# complete list as the parameter 'server_name'.
# TODO add parameter docs
# TODO add usage examples
define nginx::site (
    $ensure            = present,
    $group             = undef, # use the same group to bunble multiple sites in one config file
    $server_names      = [$name],
    $listen_ip         = undef,
    $listen_port       = '80',
    $listen_options    = undef,
    $log_format        = 'main',
    $ssl               = false,
    $ssl_cert          = undef,
    $ssl_key           = undef,
    $ssl_redirect      = false,
    $ssl_redirect_port = '80',
    $default_location  = true,) {
    # General variables
    $siteroot = "/opt/www/sites/${name}"
    $sslroot  = '/opt/ssl'

    if ($group) {
        $config_name = $group
    } else {
        $config_name = $name
    }

#    notify {"site for ${name} with config_name '${config_name}'": }

    include nginx

    # SSL
    if ($ssl == true) {
        if !defined(File[$sslroot]) {
            file { $sslroot:
                ensure => directory,
                owner  => 'root',
                group  => 'www-data',
                mode   => '2755',
            }
        }

        file { "${sslroot}/${name}":
            ensure  => directory,
            owner   => 'root',
            group   => 'www-data',
            mode    => '2755',
            require => File[$sslroot],
        }

        file { "${sslroot}/${name}/${name}.crt":
            owner   => 'root',
            group   => 'www-data',
            mode    => '0770',
            source  => $ssl_cert,
            require => File["${sslroot}/${name}"],
            notify  => Exec['nginx-reload'],
        }

        file { "${sslroot}/${name}/${name}.key":
            owner   => 'root',
            group   => 'www-data',
            mode    => '0770',
            source  => $ssl_key,
            require => File["${sslroot}/${name}"],
            notify  => Exec['nginx-reload'],
        }
    }

    if !defined(File["/etc/nginx/sites-enabled/${config_name}.conf"]) {
        file { "/etc/nginx/sites-enabled/${config_name}.conf":
            ensure  => 'link',
            target  => "/etc/nginx/sites-available/${config_name}.conf",
            require => [File["/etc/nginx/sites-available/${config_name}.conf"], File[$siteroot], File["${siteroot}/htdocs"], File["${siteroot}/logs"
                    ]],
            notify  => Exec['nginx-reload'],
        }
    }

    # Create vhost directory for htdocs and logs
    if !defined(File["/opt/www/sites/${config_name}"]) {
        file { [$siteroot, "${siteroot}/htdocs", "${siteroot}/logs"]:
            ensure  => directory,
            owner   => 'root',
            group   => 'www-data',
            mode    => '2755',
            require => Class['nginx'],
        }
    }

    include concat::setup

    # Create a concat file for the vhosts configuration
    if !defined(Concat["/etc/nginx/sites-available/${config_name}.conf"]) {
        concat { "/etc/nginx/sites-available/${config_name}.conf":
            notify  => Exec['nginx-reload'],
            require => Class['nginx'],
        }
    }

    concat::fragment { "nginx_${config_name}_header for ${name}":
        target  => "/etc/nginx/sites-available/${config_name}.conf",
        order   => "${name}-00",
        content => template('nginx/vhost_header.erb'),
    }

    concat::fragment { "nginx_${config_name}_footer ${name}":
        target  => "/etc/nginx/sites-available/${config_name}.conf",
        order   => "${name}-99",
        content => template('nginx/vhost_footer.erb'),
    }

    # Define a default location
    if ($default_location == true) {
        nginx::location { "${config_name}_default":
            site_name  => $name,
            site_group => $group,
            location   => '/',
            www_root   => "${siteroot}/htdocs",
            require    => Class['nginx'],
        }
    }
}
