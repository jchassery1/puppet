# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster::frontend() {
    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    include network::constants
    $labs_metal = hiera('labs_baremetal_servers', [])
    $novaconfig = hiera_hash('novaconfig', {})
    $labs_instance_range = $novaconfig['fixed_range']
    $horizon_host = hiera('labs_horizon_host')
    $horizon_host_ip = ipresolve(hiera('labs_horizon_host'), 4)
    $designate_host_ip = ipresolve(hiera('labs_designate_hostname'), 4)

    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, $labs_metal, '.wikimedia.org'])

    include ::base::firewall

    include ::profile::backup::host
    include ::profile::puppetmaster::labsenc
    include ::profile::puppetmaster::labsencapi

    # validatelabsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    include ::openstack::clientlib
    file { '/usr/local/sbin/validatelabsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/validatelabsfqdn.py',
    }

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => '/usr/local/sbin/validatelabsfqdn.py',
    }

    class { '::profile::puppetmaster::frontend':
        config         => $config,
        secure_private => false,
    }

    # Update git checkout.  This is done via a cron
    #  rather than via puppet_merge to increase isolation
    #  between these puppetmasters and the production ones.
    class { 'puppetmaster::gitsync':
        run_every_minutes => '1',
    }

    include ::profile::conftool::client
    include ::profile::conftool::master

    include puppetmaster::labsrootpass

    # config-master.wikimedia.org
    include ::profile::configmaster
    include ::profile::discovery::client

    $labs_vms = $novaconfig['fixed_range']
    $monitoring = '208.80.154.14 208.80.155.119 208.80.153.74'
    $all_puppetmasters = inline_template('<%= scope.function_hiera([\'puppetmaster::servers\']).values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')

    $fwrules = {
        puppetmaster_balancer => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip}) proto tcp dport 8140 ACCEPT;",
        },
        puppetmaster => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip} @resolve((${all_puppetmasters}))) proto tcp dport 8141 ACCEPT;",
        },
        puppetbackend => {
            rule => "saddr (${horizon_host_ip} ${designate_host_ip}) proto tcp dport 8101 ACCEPT;",
        },
        puppetbackendgetter => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip} @resolve((${all_puppetmasters})) @resolve((${all_puppetmasters}), AAAA)) proto tcp dport 8100 ACCEPT;",
        },
    }
    create_resources (ferm::rule, $fwrules)
}
