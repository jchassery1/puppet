# = Class: role::wdqs::test
#
# This class sets up Wikidata Query Service for testing purposes. Not
# exposed to public or private clients.
class role::wdqs::test {
    # Standard for all roles
    include ::profile::standard
    include ::profile::base::firewall
    # Standard wdqs installation
    require ::profile::query_service::wdqs

    system::role { 'wdqs::test':
        ensure      => 'present',
        description => 'Wikidata Query Service - test cluster',
    }
}
