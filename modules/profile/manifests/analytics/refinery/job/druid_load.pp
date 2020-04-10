# == Class profile::analytics::refinery::job::druid_load
#
# Installs spark jobs to load data sets to Druid.
#
class profile::analytics::refinery::job::druid_load(
    $use_kerberos = lookup('profile::analytics::refinery::job::druid_load::use_kerberos', { 'default_value' => false }),
    $ensure_timers = lookup('profile::analytics::refinery::job::druid_load::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::refinery

    # Update this when you want to change the version of the refinery job jar
    # being used for the druid load jobs.
    $refinery_version = '0.0.105'

    # Use this value as default refinery_job_jar.
    Profile::Analytics::Refinery::Job::Eventlogging_to_druid_job {
        ensure           => $ensure_timers,
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # Load event.NavigationTiming
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'navigationtiming':
        job_config => {
            dimensions    => 'event.action,event.isAnon,event.isOversample,event.mediaWikiVersion,event.mobileMode,event.namespaceId,event.netinfoEffectiveConnectionType,event.originCountry,recvFrom,revision,useragent.browser_family,useragent.browser_major,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,wiki',
            time_measures => 'event.connectEnd,event.connectStart,event.dnsLookup,event.domComplete,event.domInteractive,event.fetchStart,event.firstPaint,event.loadEventEnd,event.loadEventStart,event.redirecting,event.requestStart,event.responseEnd,event.responseStart,event.secureConnectionStart,event.unload,event.gaps,event.mediaWikiLoadEnd,event.RSI',
        },
    }

    # Load event.PageIssues
    # Deactivated for now until new experiment.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'pageissues':
        ensure     => 'absent',
        job_config => {
            dimensions => 'event.action,event.editCountBucket,event.isAnon,event.issuesSeverity,event.issuesVersion,event.namespaceId,event.sectionNumbers,revision,wiki,useragent.browser_family,useragent.browser_major,useragent.browser_minor,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,useragent.os_minor',
        },
    }

    # Load event.PrefUpdate
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'prefupdate':
        job_config => {
            dimensions => 'event.property,event.isDefault,wiki,useragent.browser_family,useragent.browser_major,useragent.browser_minor,useragent.device_family,useragent.os_family,useragent.os_major,useragent.os_minor'
        },
    }

    # Load wmf.netflow
    # Note that this data set does not belong to EventLogging, but the
    # eventlogging_to_druid_job wrapper is compatible and very convenient!
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'netflow':
        hourly_hours_until => 3,
        job_config         => {
            database         => 'wmf',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'as_dst,as_path,peer_as_dst,as_src,ip_dst,ip_proto,ip_src,peer_as_src,port_dst,port_src,tag2,tcp_flags,country_ip_src,country_ip_dst,peer_ip_src',
            metrics          => 'bytes,packets',
        },
    }
    # This second round serves as sanitization, after 90 days of data loading.
    # Note that some dimensions are not present, thus nullifying their values.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'netflow-sanitization':
        ensure_hourly    => 'absent',
        daily_days_since => 91,
        daily_days_until => 90,
        job_config       => {
            database         => 'wmf',
            table            => 'netflow',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'as_dst,as_path,peer_as_dst,as_src,peer_as_src,tag2,country_ip_src,country_ip_dst,peer_ip_src',
            metrics          => 'bytes,packets',
        },
    }
}
