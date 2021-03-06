# = Class: role::wdqs::internal
#
# This class sets up Wikidata Query Service for internal prod cluster use
# cases.
class role::wdqs::internal {
    # Standard for all roles
    include ::profile::standard
    include ::profile::base::firewall
    # Standard wdqs installation
    require ::profile::query_service::wdqs
    # Production specific profiles
    include ::profile::lvs::realserver

    system::role { 'wdqs::internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
