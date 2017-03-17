# Main vhost define for Nginx
# Default usage when using 1 servername/alias is to set the resource name to
# the domainname. If more domainnames are required then explicitly pass a
# complete list as the parameter 'server_name'.
# TODO add parameter docs
# TODO add usage examples
define nginx::site (
    $ensure            = present,
    $group             = undef, # use the same group to bundle multiple sites in one config file
    $siteroot          = "/opt/www/sites/${name}",
    $server_names      = [$name],
    $listen_ip         = undef,
    $listen_port       = '80',
    $listen_options    = undef,
    $access_log_filename = 'access.log',
    $log_format        = 'main',
    $extra_server_config = '',
    $ssl               = false,
    $ssl_cert          = undef,
    $ssl_cert_content  = undef,
    $ssl_key           = undef,
    $ssl_key_content   = undef,
    $ssl_redirect      = false,
    $ssl_redirect_port = '80',
    $ssl_redirect_type = 'redirect',
    $default_location  = true,
    $redirect_url      = undef,
    $include_base      = true,
) {
    # General variable(s)
    $sslroot  = '/opt/ssl'

    if ($group) {
        $config_name = $group
    } else {
        $config_name = $name
    }

    if ($include_base == true) {
        include nginx
    }
    $ensure_link = $ensure ? {
        absent  => absent,
        present => link,
        default => link,
    }

    $ensure_directory = $ensure ? {
        absent  => absent,
        present => directory,
        default => directory,
    }

   if ($ssl == true) {

        if !defined(File[$sslroot]) {
            ensure_resource('file', '/opt/ssl/', {
                ensure => 'directory',
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
            })

        }

        if (!defined(File["${sslroot}/${config_name}"])) {
            file { "${sslroot}/${config_name}":
                ensure  => $ensure_directory,
                owner   => 'root',
                group   => 'www-data',
                mode    => '2755',
                require => File[$sslroot],
            }
        }

        file { "${sslroot}/${config_name}/${name}.crt":
            ensure  => $ensure,
            owner   => 'root',
            group   => 'www-data',
            mode    => '0770',
            source  => $ensure ? {
                present => $ssl_cert,
                absent  => undef,
            },
            content => $ensure ? {
                present => $ssl_cert_content,
                absent  => undef,
            },
            require => File["${sslroot}/${config_name}"],
            notify  => Exec['nginx-reload'],
        }

        file { "${sslroot}/${config_name}/${name}.key":
            ensure  => $ensure,
            owner   => 'root',
            group   => 'www-data',
            mode    => '0770',
            source  => $ensure ? {
                present => $ssl_key,
                absent  => undef,
            },
            content => $ensure ? {
                present => $ssl_key_content,
                absent  => undef,
            },
            require => File["${sslroot}/${config_name}"],
            notify  => Exec['nginx-reload'],
        }
    }

    if !defined(File["/etc/nginx/sites-enabled/${config_name}.conf"]) {
        file { "/etc/nginx/sites-enabled/${config_name}.conf":
            ensure  => $ensure_link,
            target  => "/etc/nginx/sites-available/${config_name}.conf",
            require => [Concat["/etc/nginx/sites-available/${config_name}.conf"], File[$siteroot], File["${siteroot}/htdocs"], File["${siteroot}/logs"
                    ]],
            notify  => Exec['nginx-reload'],
        }
    }

    # Create vhost directory for htdocs and logs
    if !defined(File["/opt/www/sites/${config_name}"]) {
        file { [$siteroot, "${siteroot}/htdocs", "${siteroot}/logs"]:
            ensure  => $ensure_directory,
            owner   => 'root',
            group   => 'www-data',
            mode    => '2755',
            require => Class['nginx'],
            force   => true,
        }
    }

    # deprecated concat feature
    # include concat::setup

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
            site_name => $name,
            site_group => $group,
            location  => '/',
            www_root  => "${siteroot}/htdocs",
            require   => Class['nginx'],
        }
    }
}
