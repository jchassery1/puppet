# Manifest to setup a Gerrit instance
class gerrit(
    String $config,
    Stdlib::Fqdn $host,
    Stdlib::Ipv4 $ipv4,
    Array[Stdlib::Fqdn] $replica_hosts = [],
    Boolean $replica = false,
    Hash $cache_text_nodes = {},
    Boolean $use_acmechief = false,
    Optional[Hash] $ldap_config = undef,
    Optional[Stdlib::Ipv6] $ipv6,
    Optional[Stdlib::Fqdn] $avatars_host = undef,
    Enum['11', '8'] $java_version = '8',
) {

    class { '::gerrit::jetty':
        host          => $host,
        ipv4          => $ipv4,
        ipv6          => $ipv6,
        replica       => $replica,
        replica_hosts => $replica_hosts,
        config        => $config,
        ldap_config   => $ldap_config,
        java_version  => $java_version,
    }

    class { '::gerrit::proxy':
        require          => Class['gerrit::jetty'],
        host             => $host,
        ipv4             => $ipv4,
        ipv6             => $ipv6,
        replica_hosts    => $replica_hosts,
        replica          => $replica,
        avatars_host     => $avatars_host,
        cache_text_nodes => $cache_text_nodes,
        use_acmechief    => $use_acmechief,
    }

    if !$replica {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
