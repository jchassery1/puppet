# == Class profile::analytics::refinery::job::refine
# Install cron jobs for Spark Refine jobs.  These jobs
# transform data imported into Hadoop into augmented Parquet backed
# Hive tables.
#
# Description of Refine jobs declared here:
#
# - eventlogging_analytics
#   Uses schemas from meta.wikimedia.org and refines from
#   /wmf/data/raw/eventlogging -> /wmf/data/event into the Hive event database.
#
# - event
#   Uses schemas from schema.discovery.wmnet and refines from
#   /wmf/data/raw/event -> /wmf/data/event into the Hive event database.
#
# - mediawiki_job_events
#   Infers schemas from data and refines from
#   /wmf/data/raw/mediawiki_job -> /wmf/data/event into the Hive event database.
#
# - netflow
#   Infers schema from data and refines from
#   /wmf/data/raw/netflow -> /wmf/data/wmf/netflow in the Hive wmf database.
#
class profile::analytics::refinery::job::refine(
    $use_kerberos  = lookup('profile::analytics::refinery::job::refine::use_kerberos', { 'default_value' => false }),
    $ensure_timers = lookup('profile::analytics::refinery::job::refine::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::refinery
    require ::profile::hive::client

    # Update this when you want to change the version of the refinery job jar
    # being used for the refine job.
    $refinery_version = '0.0.127'

    # Use this value by default
    Profile::Analytics::Refinery::Job::Refine_job {
        # Use this value as default refinery_job_jar.
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # These configs will be used for all refine jobs unless otherwise overridden.
    $default_config = {
        'to_emails'           => 'analytics-alerts@wikimedia.org',
        'should_email_report' => true,
        'database'            => 'event',
        'output_path'         => '/wmf/data/event',
        'hive_server_url'     => "${::profile::hive::client::hiveserver_host}:${::profile::hive::client::hiveserver_port}",
        # Look for data to refine from 26 hours ago to 2 hours ago, giving some time for
        # raw data to be imported in the last hour or 2 before attempting refine.
        'since'               => '26',
        'until'               => '2',
    }


    # === EventLogging Analytics (capsule based) data ===
    # /wmf/data/raw/eventlogging -> /wmf/data/event
    $eventlogging_analytics_input_path = '/wmf/data/raw/eventlogging'
    $eventlogging_analytics_input_path_regex = 'eventlogging_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)'
    $eventlogging_analytics_input_path_regex_capture_groups = 'table,year,month,day,hour'
    $eventlogging_analytics_table_blacklist = [
        # Legacy EventLogging tables:
        'Edit',
        'InputDeviceDynamics',
        'PageIssues',
        'MobileWebMainMenuClickTracking',
        'KaiOSAppConsent',
    ]
    $eventlogging_analytics_table_blacklist_regex = "^(${join($eventlogging_analytics_table_blacklist, '|')})$"

    profile::analytics::refinery::job::refine_job { 'eventlogging_analytics':
        ensure                   => $ensure_timers,
        job_config               => merge($default_config, {
            input_path                      => $eventlogging_analytics_input_path,
            input_path_regex                => $eventlogging_analytics_input_path_regex,
            input_path_regex_capture_groups => $eventlogging_analytics_input_path_regex_capture_groups,
            table_blacklist_regex           => $eventlogging_analytics_table_blacklist_regex,
            # Deduplicate basd on uuid field and geocode ip in EventLogging analytics data.
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.event_transforms',
            # Get EventLogging JSONSchemas from meta.wikimedia.org.
            schema_base_uris                => 'eventlogging',
        }),
        # Use webproxy so that this job can access meta.wikimedia.org to retrive JSONSchemas.
        spark_extra_opts         => '--driver-java-options=\'-Dhttp.proxyHost=webproxy.eqiad.wmnet -Dhttp.proxyPort=8080 -Dhttps.proxyHost=webproxy.eqiad.wmnet -Dhttps.proxyPort=8080\'',
        interval                 => '*-*-* *:30:00',
        monitor_interval         => '*-*-* 00:15:00',
        monitor_failure_interval => '*-*-* 00:45:00',
        use_kerberos             => $use_kerberos,
    }


    # === Event data ===
    # /wmf/data/raw/event -> /wmf/data/event
    $event_input_path = '/wmf/data/raw/event'
    $event_input_path_regex = '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)'
    $event_input_path_regex_capture_groups = 'datacenter,table,year,month,day,hour'
    # Unrefineable tables due to poorly defined schemas.
    $event_table_blacklist = [
        'mediawiki_page_properties_change',
        'mediawiki_recentchange',
    ]
    $event_table_blacklist_regex = "^(${join($event_table_blacklist, '|')})$"

    profile::analytics::refinery::job::refine_job { 'event':
        ensure                   => $ensure_timers,
        job_config               => merge($default_config, {
            input_path                      => $event_input_path,
            input_path_regex                => $event_input_path_regex,
            input_path_regex_capture_groups => $event_input_path_regex_capture_groups,
            table_blacklist_regex           => $event_table_blacklist_regex,
            # event_transforms:
            # - deduplicate
            # - filter_allowed_domains
            # - geocode_ip
            # - parse_user_agent
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.event_transforms',
            # Get JSONSchemas from the HTTP schema service.
            # Schema URIs are extracted from the $schema field in each event.
            schema_base_uris                => 'https://schema.discovery.wmnet/repositories/primary/jsonschema,https://schema.discovery.wmnet/repositories/secondary/jsonschema',
        }),
        interval                 => '*-*-* *:20:00',
        monitor_interval         => '*-*-* 01:15:00',
        monitor_failure_interval => '*-*-* 01:45:00',
        use_kerberos             => $use_kerberos,
        spark_executor_memory    => '4G',
    }


    # === Mediawiki Job events ===
    # /wmf/data/raw/mediawiki_job -> /wmf/data/event

    # Problematic jobs that will not be refined.
    # These have inconsistent schemas that cause refinement to fail.
    $mediawiki_job_table_blacklist = [
        'EchoNotificationJob',
        'EchoNotificationDeleteJob',
        'TranslationsUpdateJob',
        'MessageGroupStatesUpdaterJob',
        'InjectRCRecords',
        'cirrusSearchDeleteArchive',
        'enqueue',
        'htmlCacheUpdate',
        'LocalRenameUserJob',
        'RecordLintJob',
        'wikibase_addUsagesForPage',
        'refreshLinks',
        'cirrusSearchCheckerJob',
        'MassMessageSubmitJob',
        'refreshLinksPrioritized',
        'TranslatablePageMoveJob',
        'ORESFetchScoreJob',
        'PublishStashedFile',
        'CentralAuthCreateLocalAccountJob',
        'gwtoolsetUploadMediafileJob',
        'gwtoolsetUploadMetadataJob',
        'MessageGroupStatsRebuildJob',
        'fetchGoogleCloudVisionAnnotations',
        'CleanTermsIfUnused',
    ]
    $mediawiki_job_table_blacklist_regex = sprintf('.*(%s)$', join($mediawiki_job_table_blacklist, '|'))

    $mediawiki_job_events_input_path = '/wmf/data/raw/mediawiki_job'
    $mediawiki_job_events_input_path_regex = '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)'
    $mediawiki_job_events_input_path_regex_capture_groups = 'datacenter,table,year,month,day,hour'

    profile::analytics::refinery::job::refine_job { 'mediawiki_job_events':
        ensure                   => $ensure_timers,
        job_config               => merge($default_config, {
            input_path                      => $mediawiki_job_events_input_path,
            input_path_regex                => $mediawiki_job_events_input_path_regex,
            input_path_regex_capture_groups => $mediawiki_job_events_input_path_regex_capture_groups,
            table_blacklist_regex           => $mediawiki_job_table_blacklist_regex,
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.deduplicate',
        }),
        interval                 => '*-*-* *:25:00',
        monitor_interval         => '*-*-* 02:15:00',
        monitor_failure_interval => '*-*-* 02:45:00',
        use_kerberos             => $use_kerberos,
    }


    # === Netflow data ===
    # /wmf/data/raw/netflow -> /wmf/data/wmf
    $netflow_input_path = '/wmf/data/raw/netflow'
    $netflow_input_path_regex = '(netflow)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)'
    $netflow_input_path_regex_capture_groups = 'table,year,month,day,hour'

    profile::analytics::refinery::job::refine_job { 'netflow':
        ensure                         => $ensure_timers,
        job_config                     => merge($default_config, {
            # This is imported by camus_job { 'netflow': }
            input_path                      => $netflow_input_path,
            input_path_regex                => $netflow_input_path_regex,
            input_path_regex_capture_groups => $netflow_input_path_regex_capture_groups,
            output_path                     => '/wmf/data/wmf',
            database                        => 'wmf',
        }),
        monitoring_enabled             => false,
        refine_monitor_enabled         => false,
        refine_monitor_failure_enabled => true,
        interval                       => '*-*-* *:45:00',
        monitor_failure_interval       => '*-*-* 03:45:00',
        use_kerberos                   => $use_kerberos,
    }

}
