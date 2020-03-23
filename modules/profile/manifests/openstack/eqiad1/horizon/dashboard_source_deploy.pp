class profile::openstack::eqiad1::horizon::dashboard_source_deploy(
    $horizon_version = lookup('profile::openstack::eqiad1::horizon_version'),
    $openstack_version = lookup('profile::openstack::eqiad1::version'),
    $keystone_host = lookup('profile::openstack::eqiad1::keystone_host'),
    $wmflabsdotorg_admin = lookup('profile::openstack::eqiad1::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = lookup('profile::openstack::eqiad1::designate::wmflabsdotorg_pass'),
    $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    $instance_network_id = lookup('profile::openstack::eqiad1::horizon::instance_network_id'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $webserver_hostname = lookup('profile::openstack::eqiad1::horizon::webserver_hostname'),
    $all_regions = lookup('profile::openstack::eqiad1::all_regions'),
    $puppet_git_repo_name = lookup('profile::openstack::eqiad1::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = lookup('profile::openstack::eqiad1::horizon::puppet_git_repo_user'),
    $maintenance_mode = lookup('profile::openstack::eqiad1::horizon::maintenance_mode'),
    $secret_key = lookup('profile::openstack::eqiad1::horizon::secret_key'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
        keystone_host        => $keystone_host,
        wmflabsdotorg_admin  => $wmflabsdotorg_admin,
        wmflabsdotorg_pass   => $wmflabsdotorg_pass,
        dhcp_domain          => $dhcp_domain,
        instance_network_id  => $instance_network_id,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        puppet_git_repo_user => $puppet_git_repo_user,
        maintenance_mode     => $maintenance_mode,
        secret_key           => $secret_key,
    }
}
