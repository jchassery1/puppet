class profile::openstack::base::nova::common(
    $version = hiera('profile::openstack::base::version'),
    $region = hiera('profile::openstack::base::region'),
    $db_user = hiera('profile::openstack::base::nova::db_user'),
    $db_pass = hiera('profile::openstack::base::nova::db_pass'),
    $db_host = hiera('profile::openstack::base::nova::db_host'),
    $db_name = hiera('profile::openstack::base::nova::db_name'),
    $db_name_api = hiera('profile::openstack::base::nova::db_name_api'),
    $compute_workers = hiera('profile::openstack::base::nova::compute_workers'),
    $metadata_workers = hiera('profile::openstack::base::nova::metadata_workers'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $scheduler_filters = hiera('profile::openstack::base::nova::scheduler_filters'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = hiera('profile::openstack::base::nova::rabbit_user'),
    $rabbit_pass = hiera('profile::openstack::base::rabbit_pass'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::base::neutron::metadata_proxy_shared_secret'),
    Stdlib::Port $metadata_listen_port = lookup('profile::openstack::base::nova::metadata_listen_port'),
    Stdlib::Port $osapi_compute_listen_port = lookup('profile::openstack::base::nova::osapi_compute_listen_port'),
    String       $dhcp_domain               = lookup('profile::openstack::base::nova::dhcp_domain',
                                                    {default_value => 'example.com'}),
    ) {

    class {'::openstack::nova::common':
        version                      => $version,
        region                       => $region,
        db_user                      => $db_user,
        db_pass                      => $db_pass,
        db_host                      => $db_host,
        db_name                      => $db_name,
        db_name_api                  => $db_name_api,
        openstack_controllers        => $openstack_controllers,
        keystone_api_fqdn            => $keystone_api_fqdn,
        scheduler_filters            => $scheduler_filters,
        ldap_user_pass               => $ldap_user_pass,
        rabbit_user                  => $rabbit_user,
        rabbit_pass                  => $rabbit_pass,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        compute_workers              => $compute_workers,
        metadata_listen_port         => $metadata_listen_port,
        metadata_workers             => $metadata_workers,
        osapi_compute_listen_port    => $osapi_compute_listen_port,
        dhcp_domain                  => $dhcp_domain,
    }
    contain '::openstack::nova::common'

    openstack::db::project_grants { 'nova_api':
        access_hosts => $openstack_controllers,
        db_host      => $db_host,
        db_name      => $db_name_api,
        db_user      => $db_user,
        db_pass      => $db_pass,
        project_name => 'nova',
    }
    openstack::db::project_grants { 'nova':
        access_hosts => $openstack_controllers,
        db_host      => $db_host,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        project_name => 'nova',
    }
}
