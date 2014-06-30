use 5.8.8;
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Installation paths

my $sysconfig = ( -e '/etc/default' ) ? '/etc/default' : '/etc/sysconfig';
my $install_path = {
    etc           => '/etc/xas',
    sbin          => '/usr/sbin',
    script        => '/usr/bin',
    sysconfig     => $sysconfig,
    'init.d'      => '/etc/init.d',
    'profile.d'   => '/etc/profile.d',
    'logrotate.d' => '/etc/logrotate.d',
};

# Required modules

my $requires = {
    'Badger'                      => 0.09,
    'POE'                         => 1.35,
    'DateTime'                    => 0.53,
    'DateTime::Format::Pg'        => 0.0,     #0.16008,
    'DateTime::Format::Strptime'  => 1.10,
    'Config::IniFiles'            => 2.72,
    'File::Pid'                   => 0.0,
    'Hash::Merge'                 => 0.12,
    'JSON::XS'                    => 2.27,
    'LockFile::Simple'            => 0.207,
    'MIME::Lite'                  => 3.027,
    'Params::Validate'            => 0.92,
    'Pod::Usage'                  => 1.35,
    'Try::Tiny::Retry'            => 0.003,
    'Set::Light'                  => 0.04,
    'Net::SSH2'                   => 0.44,
};

# Needed for Win32 installations

if ($^O eq 'MSWin32') {

    $requires->{'Win32'}          = 0.45;
    $requires->{'Win32::OLE'}     = 0.1709;
    $requires->{'Win32::Daemon'}  = 20110117;
    $requires->{'Win32::Service'} = 0.06;

    my $path = defined($ENV{'XAS_ROOT'}) ? $ENV{'XAS_ROOT'} : 'C:\\xas';

    $install_path = {
        script      => $path . '\\bin',
        sbin        => $path . '\\sbin',
        etc         => $path . '\\etc',
        'profile.d' => $path . '\\etc',
    };
}

my $class = Module::Build->subclass(code => <<'EOC');

    use strict;
    use warnings;
    use IO::File;
    use File::Find;
    use File::Basename;
    use File::Spec::Functions qw( catfile catdir rel2abs );

    sub ACTION_post_install {
        my $self = shift;

        # create xas owner/group

        unless ($^O eq 'MSWin32') {

            unless (getpwnam('xas')) {

                system("groupadd -f -r xas");
                system("useradd -r -g xas -d /var/lib/xas -s /sbin/nologin -c \"XAS\" xas");

            }

            # using the standard filesystem layout

            system("mkdir /etc/xas")       unless ( -e '/etc/xas');
            system("mkdir /var/log/xas")   unless ( -e '/var/log/xas');
            system("mkdir /var/lib/xas")   unless ( -e '/var/lib/xas');
            system("mkdir /var/run/xas")   unless ( -e '/var/run/xas');
            system("mkdir /var/spool/xas") unless ( -e '/var/spool/xas');

            # create some spool directories

            system("mkdir /var/spool/xas/alerts")   unless ( -e '/var/spool/xas/alerts');
            system("mkdir /var/spool/xas/logstash") unless ( -e '/var/spool/xas/logstash');

            # set ownership/permissions on the files/directories

            system("chown -R root:xas /etc/xas");
            system("chown -R xas:xas  /var/log/xas");
            system("chown -R xas:xas  /var/lib/xas");
            system("chown -R xas:xas  /var/run/xas");
            system("chown -R xas:xas  /var/spool/xas");

            system("chmod 0664 /var/spool/xas/alerts");
            system("chmod 0664 /var/spool/xas/logstash");

        } else {

            my $dir;
            my $base = defined($ENV{'XAS_ROOT'}) ? $ENV{'XAS_ROOT'} : 'C:\\xas';

            $dir = catdir($base, 'tmp');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'log');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'run');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'lib');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'spool');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'spool', 'alerts');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'spool', 'logstash');
            system("mkdir $dir") unless ( -e $dir);

        }

        return $self;

    }

    sub process_etc_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'etc');
        my $files = $self->find_etc_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_sbin_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'sbin');
        my $files = $self->find_sbin_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $self->make_executable($from);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_initd_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'init.d');
        my $files = $self->find_initd_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $self->make_executable($from);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_sysconf_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'sysconfig');
        my $files = $self->find_sysconf_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $self->make_executable($from);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_profiled_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'profile.d');
        my $files = $self->find_profiled_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $self->make_executable($from);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_logrotated_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'logrotate.d');
        my $files = $self->find_logrotated_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub find_etc_files { shift->find_all_files_no_svn('etc'); }
    sub find_sbin_files { shift->find_all_files_no_svn('sbin'); }
    sub find_initd_files { shift->find_all_files_no_svn('init.d'); }
    sub find_sysconf_files { shift->find_all_files_no_svn('sysconfig'); }
    sub find_profiled_files { shift->find_all_files_no_svn('profile.d'); }
    sub find_logrotated_files { shift->find_all_files_no_svn('logrotate.d'); }

    sub find_all_files_no_svn {
        my ($self, $dir) = @_;

        my $sub = sub {
            return 1 if (($File::Find::dir !~ /SVN/i or 
                          $File::Find::Dir !~ /GIT/i) and 
                         -f $File::Find::name);
        };

        return { map {$_, $_} @{ $self->rscan_dir($dir, $sub) } };

    }
EOC

my $builder = $class->new(
    module_name         => 'XAS',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kevin@kesteb.us>},
    dist_version_from   => 'lib/XAS.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires           => $requires,
    add_to_cleanup     => [ 'XAS-*' ],
    create_makefile_pl => 'traditional',
    install_path       => $install_path,
);

$builder->add_build_element('profiled');
$builder->add_build_element('msg');
$builder->create_build_script();

