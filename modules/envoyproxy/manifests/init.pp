class envoyproxy(
    Wmflib::Ensure $ensure,
    Stdlib::Port $admin_port,
    String $service_cluster,
    Enum['envoy', 'envoyproxy', 'getenvoy-envoy'] $pkg_name,
    Boolean $use_override = true,
) {

    # Variables for zone-aware routing, useful if that is used.
    $service_node = $::fqdn
    $service_zone = $::site
    package { $pkg_name:
        ensure => $ensure
    }
    $envoy_directory = '/etc/envoy'
    $dir_ensure = ensure_directory($ensure)

    file { $envoy_directory:
        ensure => $dir_ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    # Ensure envoy.yaml has the correct permissions.
    # It will be overwritten by the exec below.
    file { "${envoy_directory}/envoy.yaml":
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Create the subdirectories where we will store:
    # Listener and cluster definitions
    file { ["${envoy_directory}/listeners.d", "${envoy_directory}/clusters.d"]:
        ensure  => $dir_ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    # Configure proper log filtering and rotation
    systemd::syslog { 'envoy':
        ensure     => $ensure,
        force_stop => true,
    }

    # build-envoy-config should generate all configuration starting from
    # the puppet-declared envoyproxy::listener and envoyproxy::cluster
    # definitions.
    #
    # It will also verify the new configuration and only put it in place if something
    # has changed.
    require_package('python3-yaml')
    # Jessie has python 3.4, with no typing support.
    if os_version('debian jessie') {
        $build_source = 'puppet:///modules/envoyproxy/build_envoy_config.jessie.py'
    }
    else {
        $build_source = 'puppet:///modules/envoyproxy/build_envoy_config.py'
    }
    file { '/usr/local/sbin/build-envoy-config':
        ensure => $ensure,
        source => $build_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $admin = {
        'access_log_path' => '/var/log/envoy/admin-access.log',
        'address'         => {'socket_address' => {'address' => '0.0.0.0', 'port_value' => $admin_port}}
    }

    file { "${envoy_directory}/admin-config.yaml":
        ensure  => $ensure,
        content => to_yaml($admin),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        notify  => Exec['verify-envoy-config'],
    }

    # Used by defines to verify the configuration.
    exec { 'verify-envoy-config':
        command     => "/usr/local/sbin/build-envoy-config -c '${envoy_directory}'",
        user        => 'root',
        refreshonly => true,
        notify      => Systemd::Service['envoyproxy.service'],
        require     => Package[$pkg_name],
    }


    if $use_override {
        $tpl = 'envoyproxy/systemd.override.conf.erb'
    }
    else {
        $tpl = 'envoyproxy/systemd.full.conf.erb'
    }

    # hot restarter script, taken from the envoy repository directly.
    file { '/usr/local/sbin/envoyproxy-hot-restarter':
        ensure => $ensure,
        source => 'puppet:///modules/envoyproxy/hot_restarter/hot-restarter.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/envoyproxy-start':
        ensure => $ensure,
        source => 'puppet:///modules/envoyproxy/hot_restarter/start-envoy.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # We override the restart from puppet to become a reload, which sends
    # SIGHUP to the hot restarter.
    systemd::service { 'envoyproxy.service':
        ensure         => $ensure,
        content        => template($tpl),
        override       => $use_override,
        service_params => {'restart' => '/bin/systemctl reload envoyproxy.service',  },
    }
}
