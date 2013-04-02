# Define for a Nginx location define for a particular vhost.
# Please note that the following parameters are effectively mutually exclusive:
# $proxy, $location_alias, $www_root
# and the exact function of $options depends on which of these parameters is
# defined if any.
define nginx::location (
    $site_name, # site name (not necessarily a domain name)
    $location,
    $location_alias         = undef,
    $www_root               = undef,
    $index_files            = ['index.html', 'index.htm', 'index.php'],
    $proxy                  = undef,
    $proxy_read_timeout     = '300s',
    $proxy_connect_timeout  = '60s',
    $proxy_set_header       = [],
    $options                = [],
    $concat_order           = '01',
) {
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
        target  => "/etc/nginx/sites-available/${site_name}.conf",
        order   => $concat_order,
        content => $content,
    }
}
