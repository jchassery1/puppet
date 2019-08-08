#
class apereo_cas (
    Stdlib::Filesource         $keystore_source,
    Stdlib::Filesource         $log4j_source        = 'puppet:///modules/apereo_cas/log4j2.xml',
    String                     $overlay_repo        = 'operations/software/cas-overlay-template',
    Stdlib::Unixpath           $overlay_dir         = '/srv/cas/overlay-template',
    Stdlib::Unixpath           $base_dir            = '/etc/cas',
    Stdlib::HTTPSUrl           $server_name         = "https://${facts['fqdn']}:8443",
    String                     $server_prefix       = 'cas',
    Array[String[1]]           $ldap_attribute_list = ['cn', 'memberOf', 'mail'],
    Array[Apereo_cas::LDAPUri] $ldap_uris           = [],
    Apereo_cas::Ldapauth       $ldap_auth           = 'AUTHENTICATED',
    Apereo_cas::Ldapconnection $ldap_connection     = 'ACTIVE_PASSIVE',
    Boolean                    $ldap_start_tls      = true,
    String                     $ldap_base_dn        = 'dc=,example,dc=org',
    String                     $ldap_search_filter  = 'cn={user}',
    String                     $ldap_bind_dn        = 'cn=user,dc=example,dc=org',
    String                     $ldap_bind_pass      = 'changeme',
    Apereo_cas::LogLevel       $log_level           = 'WARN',
) {
    $config_dir = "${base_dir}/config"
    $services_dir = "${base_dir}/services"

    ensure_packages(['openjdk-11-jdk'])
    file {wmflib::dirtree($overlay_dir) + [$base_dir, $services_dir, $config_dir, $overlay_dir]:
        ensure => directory,
    }
    git::clone {$overlay_repo:
        directory => $overlay_dir,
    }
    file {"${config_dir}/cas.properties":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('apereo_cas/cas.properties.erb'),
        before  => Systemd::Service['cas'],
    }
    file {"${config_dir}/log4j2.xml":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => $log4j_source,
        before => Systemd::Service['cas'],
    }
    file {"${base_dir}/thekeystore":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => $keystore_source,
        before => Systemd::Service['cas'],
    }
    exec{'build cas war':
        command => "${overlay_dir}/build.sh package",
        creates => "${overlay_dir}/build/libs/cas.war",
        cwd     => $overlay_dir,
        require => Git::Clone[$overlay_repo]
    }
    exec{'update cas war':
        command     => "${overlay_dir}/build.sh update",
        cwd         => $overlay_dir,
        require     => Exec['build cas war' ],
        subscribe   => Git::Clone[$overlay_repo],
        notify      => Systemd::Service['cas'],
        refreshonly => true,
    }
    systemd::service {'cas':
        content => template('apereo_cas/cas.service.erb'),
        require => Exec['build cas war' ],
    }
}
