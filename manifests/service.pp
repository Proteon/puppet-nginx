# Helper class to define Nginx's service
# TODO: this is for internal use only?
class nginx::service (
    $enabled = true, # true, false or 'manual'
) {
    service { 'nginx':
        ensure      => 'running',
        enable      => $enabled,
        hasstatus   => true,
        hasrestart  => true,
    }

    exec { 'nginx-reload':
        command     => '/etc/init.d/nginx reload',
        refreshonly => true,
    }
}
