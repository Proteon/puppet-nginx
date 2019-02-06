# TODO: add documentation
define nginx::upstream (
    $members,
    $members_check          = undef,
    $upstream_name          = $name,
    $sticky_session         = false,
    $sticky_session_expires = '1h',
    $sticky_session_name    = undef,
    $sticky_session_path    = undef,
    $sticky_session_domain  = undef,
    $additional_configuration = '',
) {
    file { "/etc/nginx/upstreams.d/${name}.conf":
        content => template('nginx/upstream.erb'),
        notify  => Exec['nginx-reload'],
    }
}
