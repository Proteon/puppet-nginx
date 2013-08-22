# Define for a Nginx location define for a particular vhost.
# Please note that the following parameters are effectively mutually exclusive:
# $proxy, $location_alias, $www_root
# and the exact function of $options depends on which of these parameters is
# defined if any.
# TODO add parameter docs
# TODO add usage examples
define nginx::location (
    $location,
    $location_alias         = undef,
    $www_root               = undef,
    $site_name              = $name, # site name (not necessarily a domain name)
    $site_group             = undef, # cluster config in a group
    $index_files            = ['index.html', 'index.htm', 'index.php'],
    $proxy                  = undef,
    $proxy_read_timeout     = '300s',
    $proxy_connect_timeout  = '60s',
    $proxy_set_header       = [],
    $options                = [],
    $concat_order           = '01',
    $ensure                 = present,
) {

    if ($site_group) {
        $config_name = $site_group
    } else {
        $config_name = $site_name
    }

    if ($proxy != undef) {
        $content = template('nginx/vhost_location_proxy.erb')
    } elsif ($location_alias != undef) {
        $content = template('nginx/vhost_location_alias.erb')
    } elsif ($www_root != undef) {
        $content = template('nginx/vhost_location_directory.erb')
    } else {
        $content = template('nginx/vhost_location.erb')
    }

    concat::fragment { "nginx location ${name} for ${site_name}":
        ensure  => $ensure,
        target  => "/etc/nginx/sites-available/${config_name}.conf",
        order   => "${site_name}-${concat_order}",
        content => $content,
    }
}
