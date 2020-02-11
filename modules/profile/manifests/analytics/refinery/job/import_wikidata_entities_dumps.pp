# == Class profile::analytics::refinery::job::import_wikidata_entities_dumps
# Schedules imports of wikidata entites dumps (all-json and all-ttl) to hadoop.
#
# NOTE: This class assumes the xmldatadumps folder under which public dumps
# can be found is mounted under /mnt/data, and that hdfs-rsync is installed
#

class profile::analytics::refinery::job::import_wikidata_entities_dumps (
    $use_kerberos = lookup('profile::analytics::refinery::job::import_wikidata_entities_dumps::use_kerberos', { 'default_value' => false }),
) {

    $wikidata_local_source = '/mnt/data/xmldatadumps/public/wikidatawiki/entities/'

    # Import all-json dumps
    profile::analytics::refinery::job::import_wikidata_dumps_config { 'refinery-import-wikidata-all-json-dumps':
        include_pattern   => '/*/*.json.bz2',
        local_source      => $wikidata_local_source,
        hdfs_destination  => '/wmf/data/raw/wikidata/dumps/all_json',
        timer_description => 'Schedules daily an hdfs-rsync of the wikidata all-json dumps into HDFS',
        timer_interval    => '*-*-* 00:00:00',
        use_kerberos      => $use_kerberos,
    }

    # Import all-ttl dumps
    profile::analytics::refinery::job::import_wikidata_dumps_config { 'refinery-import-wikidata-all-ttl-dumps':
        include_pattern   => '/*/*-all-BETA.ttl.bz2',
        local_source      => $wikidata_local_source,
        hdfs_destination  => '/wmf/data/raw/wikidata/dumps/all_ttl',
        timer_description => 'Schedules daily an hdfs-rsync of the wikidata all-ttl dumps into HDFS',
        timer_interval    => '*-*-* 00:30:00',
        use_kerberos      => $use_kerberos,
    }

}