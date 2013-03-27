# Main vhost define for Nginx
# Default usage when using 1 servername/alias is to set the resource name to
# the domainname. If more domainnames are required then explicitly pass a
# complete list as the parameter 'server_name'.
define proteon-nginx::site (
    $ensure             = present,
    $server_names        = [$name],
    $listen_ip          = '*',
    $listen_port        = '80',
    $listen_options     = undef,
    $log_format         = 'main',
    $ssl                = false,
    $ssl_cert           = undef,
    $ssl_key            = undef,
    $ssl_redirect       = false,
    $ssl_redirect_port  = '80',
    $default_location   = true,
) {
    # General variables
    $siteroot = "/opt/www/sites/${name}"
    $sslroot = '/opt/ssl'

    include proteon-nginx

    # SSL
    if ($ssl == true) {
        if !defined(File[$sslroot]) {
            file { $sslroot:
                ensure  => directory,
                owner   => 'root',
                group   => 'www-data',
                mode    => '2755',
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
        }

        file { "${sslroot}/${name}/${name}.key":
            owner   => 'root',
            group   => 'www-data',
            mode    => '0770',
            source  => $ssl_key,
            require => File["${sslroot}/${name}"],
        }
    }

    file { "/etc/nginx/sites-enabled/${name}.conf":
        ensure  => 'link',
        target  => "/etc/nginx/sites-available/${name}.conf",
        require => File["/etc/nginx/sites-available/${name}.conf"],
    }

    # Create vhost directory for htdocs and logs
    if !defined(File["/opt/www/sites/${name}"]) {
        file { [$siteroot, "${siteroot}/htdocs", "${siteroot}/logs"]:
            ensure  => directory,
            owner   => 'root',
            group   => 'www-data',
            mode    => '2755',
            require => Class['proteon-nginx'],
        }
    }

    # Create a concat file for the vhosts configuration
    concat { "/etc/nginx/sites-available/${name}.conf":
        notify  => Exec['nginx-reload'],
        require => Class['proteon-nginx'],
    }

    concat::fragment { "nginx_${name}_header":
        target  => "/etc/nginx/sites-available/${name}.conf",
        order   => '00',
        content => template('proteon-nginx/vhost_header.erb'),
    }

    concat::fragment { "nginx_${name}_footer":
        target  => "/etc/nginx/sites-available/${name}.conf",
        order   => '99',
        content => template('proteon-nginx/vhost_footer.erb'),
    }

    # Define a default location
    if ($default_location == true) {
        nginx::location { "${name}_default":
            site_name   => $name,
            location    => '/',
            www_root    => "${siteroot}/htdocs",
            require     => Class['proteon-nginx'],
        }
    }
}
