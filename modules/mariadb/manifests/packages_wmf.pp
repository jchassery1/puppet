# MariaDB WMF patched build installed in /opt.
# Unless you're setting up a production server,
# you probably want vanilla mariadb::packages

class mariadb::packages_wmf(
    $package   = 'undefined',
    ) {

    require_package (
        'percona-toolkit',
        'grc',
        'python3-pymysql',    # for mariadb_check.py
    )

    # Do not try to install xtrabackup on stretch, it has been removed.
    if os_version('debian < stretch') {
        require_package ('percona-xtrabackup')
    }
    elsif os_version('debian >= buster') {
        require_package('mariadb-backup')
    }

    # if not defined, default to 10.4 on buster, 10.1 on stretch, 10.0 elsewhere
    if $package == 'undefined' {
        if os_version('debian == buster'){
            $mariadb_package = 'wmf-mariadb104'
        } elsif os_version('debian == stretch') {
            $mariadb_package = 'wmf-mariadb101'
        } else {
            $mariadb_package = 'wmf-mariadb10'
        }
    } else {
        $mariadb_package = $package
    }

    case $mariadb_package {
        'wmf-mariadb101', 'wmf-mariadb102', 'wmf-mariadb103', 'wmf-mariadb104', 'wmf-percona-server80', 'wmf-mysql80':
        {
            require_package( $mariadb_package )
        }
        'wmf-mariadb', 'wmf-mariadb10':
        {
            require_package( $mariadb_package )

            # if you have installed a non-systemd compatible package,
            # create a custom, safer mysqld_safe
            # New packages include it, but old packages have
            # to be overwritten still - do not take out at least
            # until all hosts are on version > 10.0.27
            class { 'mariadb::mysqld_safe':
                package => $mariadb_package,
            }
        }
        default :
        {
            fail("Invalid package version \"${mariadb_package}\". \
The only allowed versions are: wmf-mariadb10, wmf-mariadb101, wmf-mariadb102, \
wmf-mariadb103, wmf-percona-server80 or wmf-mysql80")
        }
    }

    # Manual override until all hosts are in >10.1.44-1 or >10.4.13-1
    file { '/usr/local/bin/mbstream':
        ensure => 'link',
        target => "/opt/${mariadb_package}/bin/mbstream",
    }
}
