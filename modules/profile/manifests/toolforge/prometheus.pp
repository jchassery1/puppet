# This profile provides both project-wide host discovery/monitoring (via cron
# prometheus-labs-targets) and kubernetes discovery/monitoring via Prometheus'
# native k8s support.

class profile::toolforge::prometheus (
    Stdlib::Fqdn  $legacy_k8s_master_host = lookup('k8s::master_host'),
    $legacy_k8s_users                     = lookup('k8s_infrastructure_users')
) {
    require ::profile::labs::lvm::srv
    include ::profile::prometheus::blackbox_exporter

    class { '::prometheus::wmcs_scripts': }

    $bearer_token_file = '/srv/prometheus/tools/k8s.token'
    $targets_path = '/srv/prometheus/tools/targets'

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }

    prometheus::server { 'tools':
        listen_address       => '127.0.0.1:9902',
        external_url         => 'https://tools-prometheus.wmflabs.org/tools',
        scrape_configs_extra => [
            {
                'job_name'              => 'k8s-api',
                'bearer_token_file'     => $bearer_token_file,
                'scheme'                => 'https',
                'tls_config'            => {
                    'server_name' => $legacy_k8s_master_host,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${legacy_k8s_master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'endpoints',
                    },
                ],
                # Scrape config for API servers, keep only endpoints for default/kubernetes to poll only
                # api servers
                'relabel_configs'       => [
                    {
                        'source_labels' => ['__meta_kubernetes_namespace',
                                            '__meta_kubernetes_service_name',
                                            '__meta_kubernetes_endpoint_port_name'],
                        'action'        => 'keep',
                        'regex'         => 'default;kubernetes;https',
                    },
                ],
            },
            {
                'job_name'              => 'k8s-node',
                'bearer_token_file'     => $bearer_token_file,
                # Force (insecure) https only for node servers
                'scheme'                => 'https',
                'tls_config'            => {
                    'insecure_skip_verify' => true,
                },
                'kubernetes_sd_configs' => [
                    {
                        'api_server'        => "https://${legacy_k8s_master_host}:6443",
                        'bearer_token_file' => $bearer_token_file,
                        'role'              => 'node',
                    },
                ],
                'relabel_configs'       => [
                    # Map kubernetes node labels to prometheus metric labels
                    {
                        'action' => 'labelmap',
                        'regex'  => '__meta_kubernetes_node_label_(.+)',
                    },
                    # Drop spammy metrics (i.e. with high cardinality k/v pairs)
                    {
                        'action'        => 'drop',
                        'regex'         => 'rest_client_request.*',
                        'source_labels' => [ '__name__' ],
                    },
                ]
            },
            {
                'job_name'        => 'ssh_banner',
                'metrics_path'    => '/probe',
                'params'          => {
                    'module' => ['ssh_banner'],
                },
                'file_sd_configs' => [
                    {
                        'files' => ["${targets_path}/ssh_banner.yml"]
                    }
                ],
                'relabel_configs' => [
                    # The replacement syntax is for prometheus to consume
                    # lint:ignore:single_quote_string_with_variables
                    {
                        'source_labels' => ['__address__'],
                        'regex'         => '(.*)',
                        'target_label'  => '__param_target',
                        'replacement'   => '${1}',
                    },
                    {
                        'source_labels' => ['__param_target'],
                        'regex'         => '(.*)',
                        'target_label'  => 'instance',
                        'replacement'   => '${1}',
                    },
                    {
                        'source_labels' => [],
                        'regex'         => '.*',
                        'target_label'  => '__address__',
                        'replacement'   => '127.0.0.1:9115',
                    }
                    # lint:endignore
                ]
            },
            {
            'job_name'        => 'etcd',
            'file_sd_configs' => [
                {
                    'files' => [ "${targets_path}/etcd_*.yml" ]
                }
            ]
            },
            {
            'job_name'        => 'toolsdb-mariadb',
            'file_sd_configs' => [
                {
                    'files' => [ "${targets_path}/toolsdb-mariadb.yml" ]
                }
            ]
            },
            {
            'job_name'        => 'toolsdb-node',
            'file_sd_configs' => [
                {
                    'files' => [ "${targets_path}/toolsdb-node.yml" ]
                }
            ]
            },
        ]
    }

    prometheus::web { 'tools':
        proxy_pass => 'http://localhost:9902/tools',
    }

    $client_token = $legacy_k8s_users['prometheus']['token']

    file { $bearer_token_file:
        ensure  => present,
        content => $client_token,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
    }

    file { "${targets_path}/toolsdb-mariadb.yml":
      content => ordered_yaml([{
        'targets' => ['clouddb1001.clouddb-services.eqiad.wmflabs:9104',
                      'clouddb1002.clouddb-services.eqiad.wmflabs:9104',
            ]
        }]),
    }

    file { "${targets_path}/toolsdb-node.yml":
      content => ordered_yaml([{
        'targets' => ['clouddb1001.clouddb-services.eqiad.wmflabs:9100',
                      'clouddb1002.clouddb-services.eqiad.wmflabs:9100',
            ]
        }]),
    }

    cron { 'prometheus_tools_project_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets > ${targets_path}/node_project.$$ && mv ${targets_path}/node_project.$$ ${targets_path}/node_project.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }

    cron { 'prometheus_tools_project_ssh_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --port 22 > ${targets_path}/ssh_banner.$$ && mv ${targets_path}/ssh_banner.$$ ${targets_path}/ssh_banner.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }

    cron { 'prometheus_tools_k8s_etcd_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --port 9051 --prefix tools-k8s-etcd- > ${targets_path}/etcd_k8s.$$ && mv ${targets_path}/etcd_k8s.$$ ${targets_path}/etcd_k8s.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }

    cron { 'prometheus_tools_flannel_etcd_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets --port 9051 --prefix tools-flannel-etcd- > ${targets_path}/etcd_flannel.$$ && mv ${targets_path}/etcd_flannel.$$ ${targets_path}/etcd_flannel.yml",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }
}