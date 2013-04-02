# Helper class to define Nginx's service
# TODO: this is for internal use only?
class nginx::service {
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
