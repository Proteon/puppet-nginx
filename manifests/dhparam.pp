# Little class to generate and install a server generated dh parameter
class nginx::dhparam (
    $key_size = 2048,
    $location = '/opt/ssl/dhparam.pem',
    $config_location = '/etc/nginx/conf.d/dhparam.conf'
) {

    exec { 'generate dh param':
        command => "/usr/bin/openssl dhparam -out ${location} ${key_size}",
        creates => $location,
        require => File['/opt/ssl'],
    }

    file { $config_location: 
        content => "ssl_dhparam ${location};",
        owner   => 'root',
        group   => 'www-data',
        require => Exec['generate dh param'],
        notify  => Service['nginx'],
    }
}

