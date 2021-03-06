class profile::openstack::base::glance(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    Stdlib::Port $public_port = lookup('profile::openstack::base::keystone::public_port'),
    String $db_user = lookup('profile::openstack::base::glance::db_user'),
    String $db_name = lookup('profile::openstack::base::glance::db_name'),
    String $db_pass = lookup('profile::openstack::base::glance::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::glance::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Absolutepath $glance_data_dir = lookup('profile::openstack::base::glance::data_dir'),
    Stdlib::Absolutepath $glance_image_dir = lookup('profile::openstack::base::glance::image_dir'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::glance::api_bind_port'),
    Stdlib::Port $registry_bind_port = lookup('profile::openstack::base::glance::registry_bind_port'),
    Stdlib::Fqdn $primary_glance_image_store = lookup('profile::openstack::base::primary_glance_image_store'),
    ) {

    $keystone_admin_uri = "http://${keystone_fqdn}:${auth_port}"
    $keystone_public_uri = "http://${keystone_fqdn}:${public_port}"

    class { '::openstack::glance::service':
        version             => $version,
        active              => $::fqdn == $primary_glance_image_store,
        keystone_admin_uri  => $keystone_admin_uri,
        keystone_public_uri => $keystone_public_uri,
        db_user             => $db_user,
        db_pass             => $db_pass,
        db_name             => $db_name,
        db_host             => $db_host,
        ldap_user_pass      => $ldap_user_pass,
        glance_data_dir     => $glance_data_dir,
        glance_image_dir    => $glance_image_dir,
        api_bind_port       => $api_bind_port,
        registry_bind_port  => $registry_bind_port,
    }
    contain '::openstack::glance::service'

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::rule {'glance_api_all':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (9292) ACCEPT;",
    }

    class {'openstack::glance::image_sync':
        active                => ($::fqdn == $primary_glance_image_store),
        glance_image_dir      => $glance_image_dir,
        openstack_controllers => $openstack_controllers,
    }

    # This is a no-op on the primary controller; on the spare master
    #  it allows us to sync up glance images with rsync.
    ferm::rule{'glancesync':
        ensure => 'present',
        rule   => "saddr (@resolve(${primary_glance_image_store}) @resolve(${primary_glance_image_store}, AAAA)) proto tcp dport (ssh) ACCEPT;",
    }

    openstack::db::project_grants { 'glance':
        access_hosts => $openstack_controllers,
        db_host      => $db_host,
        db_name      => 'glance',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
