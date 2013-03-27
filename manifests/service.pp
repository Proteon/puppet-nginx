# Helper class to define Nginx's service
class proteon-nginx::service {
    service { 'nginx':
        ensure      => running,
        enable      => true,
        hasstatus   => true,
        hasrestart  => true,
    }

    exec { 'nginx-reload':
        command     => '/etc/init.d/nginx reload',
        refreshonly => true,
    }
}
