# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::collector7
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $prometheus_nodes: List of prometheus nodes to allow connections from
# - $input_kafka_ssl_truststore_password: password for jks truststore used by logstash kafka input plugin
#
# filtertags: labs-project-deployment-prep
class profile::logstash::collector7 (
    $prometheus_nodes = hiera('prometheus_nodes', []),
    $input_kafka_ssl_truststore_password = hiera('profile::logstash::collector::input_kafka_ssl_truststore_password'),
    $input_kafka_consumer_group_id = hiera('profile::logstash::collector::input_kafka_consumer_group_id', undef),
    $jmx_exporter_port = hiera('profile::logstash::collector::jmx_exporter_port', 7800),
    $maintenance_hosts = hiera('maintenance_hosts', []),
) {

    require ::profile::java

    nrpe::monitor_service { 'logstash':
        description  => 'logstash process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u logstash -C java -a logstash',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Logstash',
    }

    $config_dir = '/etc/prometheus'
    $jmx_exporter_config_file = "${config_dir}/logstash_jmx_exporter.yaml"

    # Prometheus JVM metrics
    profile::prometheus::jmx_exporter { "logstash_collector_${::hostname}":
        hostname         => $::hostname,
        port             => $jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        config_dir       => $config_dir,
        source           => 'puppet:///modules/profile/logstash/jmx_exporter.yaml',
    }

    class { '::logstash':
        jmx_exporter_port   => $jmx_exporter_port,
        jmx_exporter_config => $jmx_exporter_config_file,
    }

    sysctl::parameters { 'logstash_receive_skbuf':
        values => {
            'net.core.rmem_default' => 8388608,
        },
    }

    ## Inputs (10)

    ferm::service { 'grafana_dashboard_definition_storage':
        proto  => 'tcp',
        port   => '9200',
        srange => '@resolve((grafana1002.eqiad.wmnet))',
    }

    $maintenance_hosts_str = join($maintenance_hosts, ' ')
    ferm::service { 'logstash_canary_checker_reporting':
        proto  => 'tcp',
        port   => '9200',
        srange => "(\$DEPLOYMENT_HOSTS ${maintenance_hosts_str})",
    }

    # Logstash collectors in both sites pull messages
    # from logging kafka clusters in both DCs.
    logstash::input::kafka { 'rsyslog-shipper-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'rsyslog-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['input-kafka-rsyslog-shipper', 'rsyslog-shipper', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'rsyslog-shipper-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'rsyslog-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['rsyslog-shipper','kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
    }

    logstash::input::kafka { 'rsyslog-udp-localhost-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'udp_localhost-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['input-kafka-rsyslog-udp-localhost', 'rsyslog-udp-localhost', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
    }

    logstash::input::kafka { 'rsyslog-udp-localhost-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'udp_localhost-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['rsyslog-udp-localhost','kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'rsyslog-logback-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'logback.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'logback',
        tags                                  => ['input-kafka-rsyslog-logback', 'kafka-logging-eqiad', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'deprecated-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'deprecated.*',
        group_id                              => $input_kafka_consumer_group_id,
        tags                                  => ['input-kafka-deprecated', 'kafka-logging-eqiad', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'rsyslog-logback-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'logback.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'logback',
        tags                                  => ['input-kafka-rsyslog-logback', 'kafka-logging-codfw', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'clienterror-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topic                                 => 'eqiad.mediawiki.client.error',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'clienterror',
        tags                                  => ['input-kafka-clienterror-eqiad', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'clienterror-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topic                                 => 'codfw.mediawiki.client.error',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'clienterror',
        tags                                  => ['input-kafka-clienterror-codfw', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_password,
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    # TODO: Rename this, this is the EventLogging event error topic input.
    $kafka_topic_eventlogging        = 'eventlogging_EventError'
    logstash::input::kafka { $kafka_topic_eventlogging:
        kafka_cluster_name                    => 'jumbo-eqiad',
        topic                                 => $kafka_topic_eventlogging,
        group_id                              => $input_kafka_consumer_group_id,
        tags                                  => [$kafka_topic_eventlogging, 'kafka', 'input-kafka-eventlogging', 'es'],
        type                                  => 'eventlogging',
        codec                                 => 'json',
        ssl_endpoint_identification_algorithm => '',
    }

    ## Global pre-processing (15)

    # move files into module?
    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///modules/profile/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    # Enforce a maximum length on "message" and "msg" fields
    logstash::conf { 'filter_truncate':
        source   => 'puppet:///modules/profile/logstash/filter-truncate.conf',
        priority => 15,
    }

    ## Input specific processing (20)

    logstash::conf { 'filter_syslog':
        source   => 'puppet:///modules/profile/logstash/filter-syslog.conf',
        priority => 20,
    }

    logstash::conf { 'filter_syslog_network':
        source   => 'puppet:///modules/profile/logstash/filter-syslog-network.conf',
        priority => 20,
    }

    logstash::conf { 'filter_udp2log':
        source   => 'puppet:///modules/profile/logstash/filter-udp2log.conf',
        priority => 20,
    }

    logstash::conf { 'filter_gelf':
        source   => 'puppet:///modules/profile/logstash/filter-gelf.conf',
        priority => 20,
    }

    logstash::conf { 'filter_log4j':
        source   => 'puppet:///modules/profile/logstash/filter-log4j.conf',
        priority => 20,
    }

    logstash::conf { 'filter_logback':
        source   => 'puppet:///modules/profile/logstash/filter-logback.conf',
        priority => 20,
    }

    logstash::conf { 'filter_json_lines':
        source   => 'puppet:///modules/profile/logstash/filter-json-lines.conf',
        priority => 20,
    }

    # rsyslog-shipper processing might tweak/adjust some generic syslog fields
    # thus process this filter after all inputs
    logstash::conf { 'filter_rsyslog_shipper':
        source   => 'puppet:///modules/profile/logstash/filter-rsyslog-shipper.conf',
        priority => 25,
    }

    # Process nested JSON from Docker -> Kubernetes -> rsyslog
    logstash::conf { 'filter_kubernetes_docker':
        source   => 'puppet:///modules/profile/logstash/filter-kubernetes-docker.conf',
        priority => 30,
    }

    ## Application specific processing (50)

    logstash::conf { 'filter_mediawiki':
        source   => 'puppet:///modules/profile/logstash/filter-mediawiki.conf',
        priority => 50,
    }

    logstash::conf { 'filter_striker':
        source   => 'puppet:///modules/profile/logstash/filter-striker.conf',
        priority => 50,
    }

    logstash::conf { 'filter_ores':
        source   => 'puppet:///modules/profile/logstash/filter-ores.conf',
        priority => 50,
    }

    logstash::conf { 'filter_mjolnir':
        source   => 'puppet:///modules/profile/logstash/filter-mjolnir.conf',
        priority => 50,
    }

    logstash::conf { 'filter_webrequest':
        source   => 'puppet:///modules/profile/logstash/filter-webrequest.conf',
        priority => 50,
    }

    logstash::conf { 'filter_apache2_error':
        source   => 'puppet:///modules/profile/logstash/filter-apache2-error.conf',
        priority => 50,
    }

    logstash::conf { 'filter_rsyslog_multiline':
        source   => 'puppet:///modules/profile/logstash/filter-rsyslog-multiline.conf',
        priority => 50,
    }

    logstash::conf { 'filter_eventlogging':
        source   => 'puppet:///modules/profile/logstash/filter-eventlogging.conf',
        priority => 50,
    }

    logstash::conf { 'filter_icinga':
        source   => 'puppet:///modules/profile/logstash/filter-icinga.conf',
        priority => 50,
    }

    logstash::conf { 'filter_ulogd':
        source   => 'puppet:///modules/profile/logstash/filter-ulogd.conf',
        priority => 50,
    }

    logstash::conf { 'filter_clienterror':
        source   => 'puppet:///modules/profile/logstash/filter-clienterror.conf',
        priority => 50,
    }

    ## Global post-processing (70)

    logstash::conf { 'filter_add_normalized_message':
        source   => 'puppet:///modules/profile/logstash/filter-add-normalized-message.conf',
        priority => 70,
    }

    logstash::conf { 'filter_normalize_log_levels':
        source   => 'puppet:///modules/profile/logstash/filter-normalize-log-levels.conf',
        priority => 70,
    }

    logstash::conf { 'filter_de_dot':
        source   => 'puppet:///modules/profile/logstash/filter-de_dot.conf',
        priority => 70,
    }

    logstash::conf { 'filter_es_index_name':
        source   => 'puppet:///modules/profile/logstash/filter-es-index-name.conf',
        priority => 70,
    }

    ## Throttles (rate limiting) (75) (rate limit after filtering for consistency with field conventions)

    logstash::conf { 'filter_throttle':
        source   => 'puppet:///modules/profile/logstash/filter-throttle.conf',
        priority => 75,
    }

    ## Outputs (90)
    # Template for Elasticsearch index creation
    file { '/etc/logstash/elasticsearch-template-7.json':
        ensure => present,
        source => 'puppet:///modules/profile/logstash/elasticsearch-template-7.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    # lint:endignore

    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        guard_condition => '"es" in [tags]',
        index           => '%{[@metadata][index_name]}-%{+YYYY.MM.dd}',
        manage_indices  => true,
        priority        => 90,
        template        => '/etc/logstash/elasticsearch-template-7.json',
        require         => File['/etc/logstash/elasticsearch-template-7.json'],
    }

    logstash::output::statsd { 'MW_channel_rate':
        host            => '127.0.0.1',
        port            => '9125',
        guard_condition => '[type] == "mediawiki" and "es" in [tags]',
        namespace       => 'logstash.rate',
        sender          => 'mediawiki',
        increment       => [ '%{channel}.%{level}' ],
    }

    logstash::output::statsd { 'Apache2_channel_rate':
        host            => '127.0.0.1',
        port            => '9125',
        guard_condition => '[type] == "apache2" and "syslog" in [tags]',
        namespace       => 'logstash.rate',
        sender          => 'apache2',
        increment       => [ '%{level}' ],
    }

    class { '::profile::prometheus::statsd_exporter': }

    # Alerting
    monitoring::check_prometheus { 'logstash-udp-loss-ratio':
        description     => 'Packet loss ratio for UDP',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/logstash'],
        query           => "sum(rate(node_netstat_Udp_InErrors{instance=\"${::hostname}:9100\"}[5m]))/(sum(rate(node_netstat_Udp_InErrors{instance=\"${::hostname}:9100\"}[5m]))+sum(rate(node_netstat_Udp_InDatagrams{instance=\"${::hostname}:9100\"}[5m])))",
        warning         => 0.05,
        critical        => 0.10,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Logstash',
    }

    # Ship logstash server logs to ELK using startmsg_regex pattern to join multi-line events based on datestamp
    # example: [2018-11-30T16:13:48,043]
    rsyslog::input::file { 'logstash-multiline':
        path           => '/var/log/logstash/logstash-plain.log',
        startmsg_regex => '^\\\\[[0-9,-\\\\ \\\\:]+\\\\]',
    }

    mtail::program { 'logstash':
        ensure => present,
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/logstash.mtail',
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'mtail':
        proto  => 'tcp',
        port   => '3903',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
