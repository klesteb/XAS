package XAS::Base;

our $MESSAGES;
our $VERSION = '0.05';
our $EXCEPTION = 'XAS::Exception';

use XAS::Factory;
use XAS::Exception;
use Params::Validate ':all';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'Badger::Base',
  utils      => 'dotid',
  auto_can   => '_auto_load',
  accessors  => 'env',
  filesystem => 'Dir',
  vars => {
    PARAMS => {
      -alerts => { optional => 1, default => 0 },
      -xdebug => { optional => 1, default => 0 },
    },
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub validation_exception {
    my $param = shift;
    my $class = shift;

    my $method = dotid($class) . '.invparams';
    $param = lcfirst($param);

    __PACKAGE__->throw_msg($method, 'invparams', $param);

}

sub validate_params {
    my $self   = shift;
    my $params = shift;
    my $specs  = shift;
    my $class  = shift;

    unless (defined($class)) {

        $class = (caller(1))[3];

    }

    my $results = validate_with(
        params => $params,
        called => $class,
        spec   => $specs,
        normalize_keys => sub {
            my $key = shift; 
            $key =~ s/^-//; 
            return lc $key;
        },
        on_fail => sub {
            my $param = shift;
            validation_exception($param, $class);
        },
    );

    return wantarray ? @$results : $results;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _auto_load {
    my $self = shift;
    my $name = shift;

    if ($name eq 'alert') {

        return sub { XAS::Factory->module('alert'); } 

    }

    if ($name eq 'email') {

        return sub { XAS::Factory->module('email'); } 

    }

    if ($name eq 'log') {

        return sub { 

            XAS::Factory->module('logger', {
                -type     => $self->env->logtype,
                -filename => $self->env->logfile,
                -process  => $self->env->script,
                -levels => {
                    debug => $self->env->xdebug,
                }
            }); 

        }

    }

    my ($package, $filename, $line) = caller(2);
    $self->throw_msg(
        dotid($self->class) . '.auto_load.invmethod',
        'invmethod',
        $name, $filename, $line
    );

}

sub _create_methods {
    my $self = shift;
    my $p = shift;

    no strict "refs";               # to register new methods in package
    no warnings;                    # turn off warnings

    while (my ($key, $value) = each(%$p)) {

        $self->{$key} = $value;

        *$key = sub {
            my $self = shift;
            return $self->{$key};
        };

    }

}

sub init {
    my $self = shift;

    # load the environment

    $self->{env} = XAS::Factory->module('environment');
    $XAS::Base::MESSAGES = $self->env->get_msgs();

    # process PARAMS

    my $class = $self->class;
    my $params = $self->class->hash_vars('PARAMS');
    my $p = $self->validate_params(\@_, $params, $class);

    # build our object

    $self->{config} = $p;
    $self->_create_methods($p);

    # set defaults

    $self->env->alerts($self->alerts);
    $self->env->xdebug($self->xdebug);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Base - The base class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
   vars => {
       PARAMS => {}
   }
 ;

=head1 DESCRIPTION

This module defines a base class for the XAS Environment and inherits from
L<Badger::Base|https://metacpan.org/pod/Badger::Base>. The package variable $PARAMS is used to hold 
the parameters that this class uses for initialization. Due to the pseudo 
inheritance of package variables provided by L<Badger::Class|https://metacpan.org/pod/Badger::Class>, these 
parameters can be changed or extended by inheriting classes. The parameters 
are validated using L<Params::Validate|https://metacpan.org/pod/Params::Validate>. Any parameters defined in $PARAMS 
auto-magically become accessors toward their values.

=head1 METHODS

=head2 new($parameters)

This is used to initialized the class. These parameters are validated using 
the validate_params() method. 

By default the parameter -xdebug is set to 0. This parameter is used to
turn on debugging output.

=head2 validate_params($params, $spec, $class)

This method is used to validate parameters. Internally this uses 
Params::Validate::validate_with() for the parameter validation. 

By convention, all named parameters have a leading dash. This method will 
strip off that dash and lower case the parameters name.

If an validation exception is thrown, the parameter name will have the dash 
stripped.

Based on the $spec, this can return an array or a hashref of validated
parameters and values. 

=over 4

=item B<$params>

An array ref to a set of parameters. 

=item B<$spec>

A validation spec as defined by L<Params::Validate|https://metacpan.org/pod/Params::Validate>.

=item B<$class>

An optional class that is calling this method. If one is not provided then
caller() is used to determine the calling method.

=back

=head2 validation_exception($param, $class)

This is a package level sub routine. It exists to provide a uniform exception
error message. It takes these parameters:

=over 4

=item B<$param>

The error message returned by L<Params::Validate|https://metacpan.org/pod/Params::Validate>.

=item B<$class>

The routine that the error occurred in.

=back

=head1 AUTOLOADING

Specific modules can be auto-loaded when a method name is invoked. The 
following methods have been defined:

=head2 alert

This will auto-load L<XAS::Lib::Modules::Alerts|XAS::Lib::Modules::Alerts>.
Please see that module for more details.

=head2 env

This will auto-load L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment>.
Please see that module for more details.

=head2 email

This will auto load L<XAS::Lib::Modules::Email|XAS::Lib::Modules::Email>.
Please see that module for more details.

=head2 log

This will auto load L<XAS::Lib::Modules::Log|XAS::Lib::Modules::Log>.
Please see that module for more details.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

TThis is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
