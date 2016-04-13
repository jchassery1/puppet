# network.pp

class network::constants {

    # Note this name is misleading.  Most of these are "external" networks,
    # but some subnets of the IPv6 space are not externally routed, even if
    # they're externally route-able (the ones used for private vlans).
    $external_networks = [
        '91.198.174.0/24',
        '208.80.152.0/22',
        '2620:0:860::/46',
        '198.35.26.0/23',
        '185.15.56.0/22',
        '2a02:ec80::/32',
    ]

    $all_networks = flatten([$external_networks, '10.0.0.0/8'])
    $all_networks_lo = flatten([$all_networks, '127.0.0.0/8', '::1/128'])

    $special_hosts = {
        'production' => {
            'bastion_hosts' => [
                    '208.80.154.149',                   # bast1001.wikimedia.org
                    '2620:0:861:2:208:80:154:149',      # bast1001.wikimedia.org
                    '208.80.153.5',                     # bast2001.wikimedia.org
                    '2620:0:860:1:208:80:153:5',        # bast2001.wikimedia.org
                    '91.198.174.112',                   # bast3001.wikimedia.org
                    '2620:0:862:1:91:198:174:112',      # bast3001.wikimedia.org
                    '198.35.26.5',                      # bast4001.wikimedia.org
                    '2620:0:863:1:198:35:26:5',         # bast4001.wikimedia.org
                    '2620:0:863:1:92b1:1cff:fe4d:4249', # bast4001.wikimedia.org SLAAC
                    '208.80.154.151',                   # iron.wikimedia.org
                    '2620:0:861:2:208:80:154:151',      # iron.wikimedia.org
                    '2620:0:861:2:7a2b:cbff:fe09:d5c',  # iron.wikimedia.org SLAAC
                ],
            'monitoring_hosts' => [
                    '208.80.154.14',                    # neon.wikimedia.org
                    '2620:0:861:1:208:80:154:14',       # neon.wikimedia.org
                    '2620:0:861:1:7a2b:cbff:fe08:a42f', # neon.wikimedia.org SLAAC
                    '208.80.154.53',                    # uranium.wikimedia.org (ganglia, gmetad needs it)
                    '2620:0:861:1:208:80:154:53',       # uranium.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.0.196',                      # tin.eqiad.wmnet
                    '2620:0:861:101:10:64:0:196',       # tin.eqiad.wmnet
                    '10.192.16.132',                    # mira.codfw.wmnet
                    '2620:0:860:102:10:192:16:132',     # mira.codfw.wmnet
                ],
            },
        'labtest' => {
            'bastion_hosts' => [
                    '208.80.154.149',                   # bast1001.wikimedia.org
                    '2620:0:861:2:208:80:154:149',      # bast1001.wikimedia.org
                    '208.80.153.5',                     # bast2001.wikimedia.org
                    '2620:0:860:1:208:80:153:5',        # bast2001.wikimedia.org
                    '91.198.174.112',                   # bast3001.wikimedia.org
                    '2620:0:862:1:91:198:174:112',      # bast3001.wikimedia.org
                    '198.35.26.5',                      # bast4001.wikimedia.org
                    '2620:0:863:1:198:35:26:5',         # bast4001.wikimedia.org
                    '2620:0:863:1:92b1:1cff:fe4d:4249', # bast4001.wikimedia.org SLAAC
                    '208.80.154.151',                   # iron.wikimedia.org
                    '2620:0:861:2:208:80:154:151',      # iron.wikimedia.org
                    '2620:0:861:2:7a2b:cbff:fe09:d5c',  # iron.wikimedia.org SLAAC
                ],
            'monitoring_hosts' => [
                    '208.80.154.14',                    # neon.wikimedia.org
                    '2620:0:861:1:208:80:154:14',       # neon.wikimedia.org
                    '2620:0:861:1:7a2b:cbff:fe08:a42f', # neon.wikimedia.org SLAAC
                    '208.80.154.53',                    # uranium.wikimedia.org (ganglia, gmetad needs it)
                    '2620:0:861:1:208:80:154:53',       # uranium.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.0.196',                      # tin.eqiad.wmnet
                    '2620:0:861:101:10:64:0:196',       # tin.eqiad.wmnet
                    '10.192.16.132',                    # mira.codfw.wmnet
                    '2620:0:860:102:10:192:16:132',     # mira.codfw.wmnet
                ],
            },
        'labs' => {
            'bastion_hosts' => [
                    '10.68.17.232', # bastion-01.eqiad.wmflabs
                    '10.68.18.65',  # bastion-02.eqiad.wmflabs
                    '10.68.18.66',  # bastion-restricted-01.eqiad.wmflabs
                    '10.68.18.68',  # bastion-restricted-02.eqiad.wmflabs
                ],
            'monitoring_hosts' => [
                    '10.68.16.210', # shinken-01.eqiad.wmflabs
                ],
            'deployment_hosts' => [
                    '10.68.17.240',  # deployment-tin.deployment-prep.eqiad.wmflabs
                    '10.68.17.215',  # mira.deployment-prep.eqiad.wmflabs
                ],
            }
    }

    $all_network_subnets = {
        'production' => {
            'eqiad' => {
                'public' => {
                    'public1-a-eqiad' => {
                        'ipv4' => '208.80.154.0/26',
                        'ipv6' => '2620:0:861:1::/64'
                    },
                    'public1-b-eqiad' => {
                        'ipv4' => '208.80.154.128/26',
                        'ipv6' => '2620:0:861:2::/64'
                    },
                    'public1-c-eqiad' => {
                        'ipv4' => '208.80.154.64/26',
                        'ipv6' => '2620:0:861:3::/64'
                    },
                    'public1-d-eqiad' => {
                        'ipv4' => '208.80.155.96/27',
                        'ipv6' => '2620:0:861:4::/64'
                    },
                    'public1-lvs-eqiad' => {
                        'ipv4' => '208.80.154.224/27',
                        'ipv6' => '2620:0:861:ed1a::/64',
                    },
                },
                'private' => {
                    'private1-a-eqiad' => {
                        'ipv4' => '10.64.0.0/22',
                        'ipv6' => '2620:0:861:101::/64'
                    },
                    'private1-b-eqiad' => {
                        'ipv4' => '10.64.16.0/22',
                        'ipv6' => '2620:0:861:102::/64'
                    },
                    'private1-c-eqiad' => {
                        'ipv4' => '10.64.32.0/22',
                        'ipv6' => '2620:0:861:103::/64'
                    },
                    'private1-d-eqiad' => {
                        'ipv4' => '10.64.48.0/22',
                        'ipv6' => '2620:0:861:107::/64'
                    },
                    'labs-instances1-a-eqiad' => {
                        'ipv4' => '10.68.0.0/24',
                        'ipv6' => '2620:0:861:201::/64'
                    },
                    'labs-instances1-b-eqiad' => {
                        'ipv4' => '10.68.16.0/21',
                        'ipv6' => '2620:0:861:202::/64'
                    },
                    'labs-instances1-c-eqiad' => {
                        'ipv4' => '10.68.32.0/24',
                        'ipv6' => '2620:0:861:203::/64'
                    },
                    'labs-instances1-d-eqiad' => {
                        'ipv4' => '10.68.48.0/24',
                        'ipv6' => '2620:0:861:204::/64'
                    },
                    'labs-hosts1-a-eqiad' => {
                        'ipv4' => '10.64.4.0/24',
                        'ipv6' => '2620:0:861:117::/64'
                    },
                    'labs-hosts1-b-eqiad' => {
                        'ipv4' => '10.64.20.0/24',
                        'ipv6' => '2620:0:861:118::/64'
                    },
                    'labs-hosts1-d-eqiad' => {
                        'ipv4' => '10.64.52.0/24',
                    },
                    'labs-support1-c-eqiad' => {
                        'ipv4' => '10.64.37.0/24',
                        'ipv6' => '2620:0:861:119::/64'
                    },
                    'analytics1-a-eqiad' => {
                        'ipv4' => '10.64.5.0/24',
                        'ipv6' => '2620:0:861:104::/64'
                    },
                    'analytics1-b-eqiad' => {
                        'ipv4' => '10.64.21.0/24',
                        'ipv6' => '2620:0:861:105::/64'
                    },
                    'analytics1-c-eqiad' => {
                        'ipv4' => '10.64.36.0/24',
                        'ipv6' => '2620:0:861:106::/64'
                    },
                    'analytics1-d-eqiad' => {
                        'ipv4' => '10.64.53.0/24',
                        'ipv6' => '2620:0:861:108::/64'
                    },
                },
            },
            'codfw' => {
                'public' => {
                    'public1-a-codfw' => {
                        'ipv4' => '208.80.153.0/27',
                        'ipv6' => '2620:0:860:1::/64'
                    },
                    'public1-b-codfw' => {
                        'ipv4' => '208.80.153.32/27',
                        'ipv6' => '2620:0:860:2::/64'
                    },
                    'public1-c-codfw' => {
                        'ipv4' => '208.80.153.64/27',
                        'ipv6' => '2620:0:860:3::/64'
                    },
                    'public1-d-codfw' => {
                        'ipv4' => '208.80.153.96/27',
                        'ipv6' => '2620:0:860:4::/64'
                    },
                    'public1-lvs-codfw' => {
                        'ipv4' => '208.80.153.224/27',
                        'ipv6' => '2620:0:860:ed1a::/64',
                    },
                },
                'private' => {
                    'private1-a-codfw' => {
                        'ipv4' => '10.192.0.0/22',
                        'ipv6' => '2620:0:860:101::/64'
                    },
                    'private1-b-codfw' => {
                        'ipv4' => '10.192.16.0/22',
                        'ipv6' => '2620:0:860:102::/64'
                    },
                    'private1-c-codfw' => {
                        'ipv4' => '10.192.32.0/22',
                        'ipv6' => '2620:0:860:103::/64'
                    },
                    'private1-d-codfw' => {
                        'ipv4' => '10.192.48.0/22',
                        'ipv6' => '2620:0:860:104::/64'
                    },
                },
            },
            'esams' => {
                'public' => {
                    'public1-esams' => {
                        'ipv4' => '91.198.174.0/25',
                        'ipv6' => '2620:0:862:1::/64'
                    },
                    'public1-lvs-esams' => {
                        'ipv4' => '91.198.174.192/27',
                        'ipv6' => '2620:0:862:ed1a::/64',
                    },
                },
                'private' => {
                    'private1-esams' => {
                        'ipv4' => '10.20.0.0/24',
                        'ipv6' => '2620:0:862:102::/64'
                    },
                },
            },
            'ulsfo' => {
                'public' => {
                    'public1-ulsfo' => {
                        'ipv4' => '198.35.26.0/28',
                        'ipv6' => '2620:0:863:1::/64'
                    },
                    'public1-lvs-ulsfo' => {
                        'ipv4' => '198.35.26.96/27',
                        'ipv6' => '2620:0:863:ed1a::/64',
                    },
                },
                'private' => {
                    'private1-ulsfo' => {
                        'ipv4' => '10.128.0.0/24',
                        'ipv6' => '2620:0:863:101::/64'
                    },
                },
            },
        },
        'frack' => {
            'eqiad' => {
                'public' => {
                    'frack-external1-c-eqiad' => {
                        'ipv4' => '208.80.155.0/27',
                    },
                },
                'private' => {
                    'frack-payments1-c-eqiad' => {
                        'ipv4' => '10.64.40.0/27',
                    },
                    'frack-bastion1-c-eqiad' => {
                        'ipv4' => '10.64.40.32/27',
                    },
                    'frack-administration1-c-eqiad' => {
                        'ipv4' => '10.64.40.64/27',
                    },
                    'frack-fundraising1-c-eqiad' => {
                        'ipv4' => '10.64.40.96/27',
                    },
                    'frack-DMZ1-c-eqiad' => {
                        'ipv4' => '10.64.40.128/27',
                    },
                    'frack-listenerdmz1-c-eqiad' => {
                        'ipv4' => '10.64.40.160/27',
                    },
                },
            },
            'codfw' => {
                'public' => {
                    'frack-external-codfw' => {
                        'ipv4' => '208.80.152.224/28',
                    },
                },
                'private' => {
                    'frack-payments-codfw' => {
                        'ipv4' => '10.195.0.0/27',
                    },
                    'frack-bastion-codfw' => {
                        'ipv4' => '10.195.0.64/29',
                    },
                    'frack-administration-codfw' => {
                        'ipv4' => '10.195.0.72/29',
                    },
                    'frack-fundraising-codfw' => {
                        'ipv4' => '10.195.0.32/27',
                    },
                    'frack-listenerdmz-codfw' => {
                        'ipv4' => '10.195.0.80/29',
                    },
                    'frack-management-codfw' => {
                        'ipv4' => '10.195.0.96/27',
                    },
                },
            },
        },
        'sandbox' => {
            'eqiad' => {
                'public' => {
                    'sandbox1-b-eqiad' => {
                        'ipv4' => '208.80.155.64/28',
                        'ipv6' => '2620:0:861:202::/64',
                    },
                },
            },
            'codfw' => {
                'public' => {
                    'sandbox1-a-codfw' => {
                        'ipv4' => '208.80.152.240/28',
                        'ipv6' => '2620:0:860:201::/64',
                    },
                },
            },
            'ulsfo' => {
                'public' => {
                    'sandbox1-ulsfo' => {
                        'ipv4' => '198.35.26.240/28',
                        'ipv6' => '2620:0:863:201::/64',
                    },
                },
            },
        },
    }


    # Networks hosting MediaWiki application servers
    if $::realm == 'production' {
        # TODO: Revisit this structure in the future
        $mw_appserver_networks =
            [
                '208.80.152.0/22',    # external
                '2620:0:860::/46',    # all external previous was for silver
                '10.64.37.14/32',     # nobelium, temporary mw install to copy over es indices
                '2620:0:861:119:f21f:afff:fee8:b1fb/64', # same as ^
                $all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv6'],
                $all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv6'],
                $all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv6'],
                $all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv6'],
            ]
    } elsif $::realm == 'labs' {
        # rely on security groups in labs to restrict this
        $mw_appserver_networks = ['10.0.0.0/8', '127.0.0.1']
    } elsif $::realm == 'labtest' {
        # This just a placeholder... .erb doesn't like this to be empty.
        $mw_appserver_networks = ['208.80.152.0/22']
    }

    # Analytics subnets
    $analytics_networks = [
        $all_network_subnets['production']['eqiad']['private']['analytics1-a-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-a-eqiad']['ipv6'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-b-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-b-eqiad']['ipv6'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-c-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-c-eqiad']['ipv6'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-d-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-d-eqiad']['ipv6'],
    ]

    # Networks that trebuchet/git-deploy
    # will be able to deploy to.
    # (Puppet does array concatenation
    # by declaring array of other arrays! (?!)
    # See: http://weblog.etherized.com/posts/175)
    $deployable_networks = [
        $mw_appserver_networks,
        $analytics_networks,
    ]
}
