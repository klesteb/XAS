#
# Boiler plate Build.PL
#
# Should work with Win32 and Linux. Replace XXX with something usefull.
#

use strict;
use warnings FATAL => 'all';
use Module::Build;

my $requires = {
    'XAS' => '0.07',
};
    
my $sysconfig = ( -e '/etc/default' ) ? '/etc/default' : '/etc/sysconfig';
my $install_path = {
    etc           => '/etc/xas',
    sbin          => '/usr/sbin',
    script        => '/usr/bin',
    sysconfig     => $sysconfig,
    'init.d'      => '/etc/init.d',
    'profile.d'   => '/etc/profile.d',
    'logrotate.d' => '/etc/logrotate.d'
};

if ($^O eq 'MSWin32') {

    my $path = defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : 'C:\\xas';

    my $install_path = {
        etc    => $path . '\\etc',
        sbin   => $path . '\\sbin',
        script => $path . '\\bin',
    };

}

my $class = Module::Build->subclass(code => <<'EOC');

    use strict;
    use warnings;

    use IO::File;
    use File::Find;
    use File::Basename;
    use File::Spec::Functions qw( catfile catdir rel2abs );

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

    sub find_etc_files { shift->find_all_files_no_scm('etc'); }
    sub find_sbin_files { shift->find_all_files_no_scm('sbin'); }
    sub find_initd_files { shift->find_all_files_no_scm('init.d'); }
    sub find_sysconf_files { shift->find_all_files_no_scm('sysconfig'); }
    sub find_profiled_files { shift->find_all_files_no_scm('profile.d'); }
    sub find_logrotated_files { shift->find_all_files_no_scm('logrotate.d'); }

    sub find_all_files_no_scm {
        my ($self, $dir) = @_;

        my $sub = sub {
            return 1 if (($File::Find::dir !~ /SVN/i or
                          $File::Find::dir !~ /GIT/i ) and 
                          -f $File::Find::name);
        };

        return { map {$_, $_} @{ $self->rscan_dir($dir, $sub) } };

    }

EOC

my $builder = $class->new(
    module_name         => 'XXX',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kevin@kesteb.us>},
    dist_version_from   => 'lib/XXX.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'XXX-*' ],
    create_makefile_pl => 'traditional',
    install_path       => $install_path,
    requires           => $requires
);

$builder->add_build_element('msg');
$builder->create_build_script();

