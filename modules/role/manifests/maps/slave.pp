# Sets up a maps server slave
class role::maps::slave {
    include ::profile::standard
    include ::profile::rsyslog::udp_localhost_compat
    include ::profile::base::firewall
    include ::profile::lvs::realserver

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_slave
    include ::profile::maps::tlsproxy
    include ::profile::prometheus::postgres_exporter

    system::role { 'maps::slave':
      ensure      => 'present',
      description => 'Maps master (postgresql, cassandra, tilerator, kartotherian)',
    }

}
