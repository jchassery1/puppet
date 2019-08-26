# == Class profile::analytics::database::meta::backup_dest
#
# Target host to store the analytics meta database snapshot, taken by
# the role running profile::analytics::database::meta::backup.
#
class profile::analytics::database::meta::backup_dest(
    $hive_metastore_host = hiera('profile::analytics::database::meta::backup_dest::hive::metastore_host'),
    $oozie_host          = hiera('profile::analytics::database::meta::backup_dest::oozie_host'),
    $use_kerberos        = hiera('profile::analytics::database::meta::bakcup_dest::use_kerberos', false)
) {

    # Need hadoop to copy versioned LVM snapshot into HDFS.
    Class['profile::hadoop::common'] -> Class['profile::analytics::database::meta::backup_dest']

    $backup_dir_group = $::realm ? {
        'production' => 'analytics-admins',
        'labs'       => "project-${::labsproject}",
    }

    if !defined(File['/srv/backup']) {
        file { '/srv/backup':
            ensure => 'directory',
            owner  => 'root',
            group  => $backup_dir_group,
            mode   => '0755',
        }
    }


    $analytics_meta_backup_dir = '/srv/backup/mysql/analytics-meta'
    file { [
            '/srv/backup/mysql',
            $analytics_meta_backup_dir,
        ]:
        ensure => 'directory',
        owner  => 'root',
        group  => $backup_dir_group,
        mode   => '0750',
    }

    class { '::rsync::server': }

    # These are probably the same host, but in case they
    # aren't, allow either use of this rsync server module.
    $hosts_allow = unique([$hive_metastore_host, $oozie_host])

    # This will allow $hosts_allow to host public data files
    # generated by the analytics cluster.
    # Note that this requires that cdh::hadoop::mount
    # be present and mounted at /mnt/hdfs
    rsync::server::module { 'backup':
        path        => '/srv/backup',
        read_only   => 'no',
        list        => 'no',
        hosts_allow => $hosts_allow,
        auto_ferm   => true,
    }

    base::service_auto_restart { 'rsync': }

    if !defined(Sudo::User['nagios_check_newest_file_age']) {
        sudo::user { 'nagios_check_newest_file_age':
            user       => 'nagios',
            privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_newest_file_age'],
        }
    }

    # Alert if backup gets stale.
    $warning_threshold_hours = 26
    $critical_threshold_hours = 48
    nrpe::monitor_service { 'analytics-database-meta-backup-age':
        description   => 'Age of most recent Analytics meta MySQL database backup files',
        nrpe_command  => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_newest_file_age -V -C --check-dirs -d ${analytics_meta_backup_dir} -w ${$warning_threshold_hours} -c ${critical_threshold_hours}",
        contact_group => 'analytics',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Mysql_Meta',
    }


    # Keep daily backups in HDFS.

    $hdfs_backup_script = '/usr/local/bin/analytics-meta-backup-to-hdfs'
    file { $hdfs_backup_script:
        source => 'puppet:///modules/profile/analytics/database/meta/backup_dest/backup_to_hdfs.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    $analytics_meta_hdfs_backup_dir = '/wmf/data/archive/backup/mysql/analytics-meta'
    cdh::hadoop::directory { $analytics_meta_hdfs_backup_dir:
        owner        => 'root',
        group        => $backup_dir_group,
        mode         => '0750',
        use_kerberos => $use_kerberos,
    }

    kerberos::systemd_timer { 'analytics-database-meta-snapshot-copy-to-hdfs':
        description               => 'Copies mylvmbackup snapshots of the analytics-meta MySQL instance to HDFS',
        command                   => "${hdfs_backup_script} ${analytics_meta_backup_dir} ${analytics_meta_hdfs_backup_dir}",
        interval                  => '*-*-* 00:30:00',
        user                      => 'root',
        monitoring_contact_groups => 'root',
        use_kerberos              => $use_kerberos,
        require                   => [
            Cdh::Hadoop::Directory[$analytics_meta_hdfs_backup_dir],
            File['/usr/local/bin/analytics-meta-backup-to-hdfs'],
        ],
    }
}
