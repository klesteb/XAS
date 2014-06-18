package XAS::Base;

our $VERSION = '0.03';
our $EXCEPTION = 'XAS::Exception';
our ($SCRIPT)  = ( $0 =~ m#([^\\/]+)$# );

use XAS::Factory;
use XAS::Exception;
use Params::Validate ':all';

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'Badger::Base',
  utils    => 'dotid',
  auto_can => '_auto_load',
  messages => {
    exception     => '%s: %s',
    invparams     => 'invalid parameters passed, reason: %s',
    invmethod     => 'invalid method "%s", unable to auto load',
    nospooldir    => 'no spool directory defined',
    unknownos     => 'unknown OS: %s',
    unexpected    => 'unexpected error: %s',
    unknownerror  => 'unknown error: %s',
    undeliverable => 'unable to send mail to %s; reason: %s',
    noserver      => 'unable to connect to %s; reason: %s',
    nodelivery    => 'unable to send message to %s; reason: %s',
    sequence      => 'unable to retrieve sequence number from %s',
    write_packet  => 'unable to write a packet to %s',
    read_packet   => 'unable to read a packet from %s',
    lock_error    => 'unable to acquire a lock on %s',
    invperms      => 'unable to change file permissions on %s',
    badini        => 'unable to load config file: %s',
    signaled      => '%s: recieved signal %s',
  },
  vars => {
    PARAMS => {
      -xdebug => { optional => 1, default => 0 }
    }
  }
;

#use Data::Dumper;

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

    if ($name eq 'alerts') {

        return sub { XAS::Alerts->new(); } 

    }

    if ($name eq 'env') {

        return sub { XAS::Factory->module('environment'); } 

    }

    if ($name eq 'email') {

        return sub { XAS::Factory->module('email'); } 

    }

    if ($name eq 'log') {

        return sub { 

            XAS::Factory->module('logger', {
                -type     => $self->env->logtype,
                -filename => $self->env->logfile,
                -levels => {
                    debug => $self->debugging ? 1 : 0,
                }
            }); 

        }

    }

    $self->throw_msg(
        dotid($self->class) . '.auto_load.invmethod',
        'invmethod',
        $name
    );

}

sub init {
    my $self = shift;

    # process PARAMS

    my $class = $self->class;
    my $params = $self->class->hash_vars('PARAMS');
    my $p = $self->validate_params(\@_, $params, $class);

    # build our object

    $self->{config} = $p;

    no strict "refs";               # to register new methods in package
    no warnings;                    # turn off warnings

    while (my ($key, $value) = each(%$p)) {

        $self->{$key} = $value;

        *$key = sub {
            my $self = shift;
            return $self->{$key};
        };

    }

    $self->debugging($self->xdebug);

    return $self;

}

package # hide from PAUSE
  XAS::Alerts;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base Badger::Prototype',
;

sub check {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    return $self->{enabled};

}

sub on {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my ($enable) = $self->validate_params(\@_, [ 
        { optional => 1, default => undef, regex => qr/0|1/ } 
    ]);

    $self->{enabled} = $enable if (defined($enable));

    return $self->{enabled};

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{enabled} = 0;

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
L<Badger::Base>. The package variable $PARAMS is used to hold 
the parameters that this class uses for initialization. Due to the psuedo 
inheritence of package variables provided by L<Badger::Class>, these 
parameters can be changed or extended by inheriting classes. The parameters 
are validated using L<Params::Validate>. Any parameters defined in $PARAMS 
automagically become accessors toward their values.

=head1 METHODS

=head2 new($parameters)

This is used to initialized the class. These parameters are validated using 
the validate_params() method. 

By default the parameter -xdebug is set to 0. This parameter is used to
turn on debugging output.

=head2 validate_params($params, $spec, $class)

This method is used to validate paramters. Internally this uses 
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

A vaildation spec as defined by L<Params::Validate>.

=item B<$class>

An optional class that is calling this method. If one is not provided then
caller() is used to determine the calling method.

=back

=head2 validation_exception($param, $class)

This is a package level sub routine. It exists to provide a uniform exception
error message. It takes these parameters:

=over 4

=item B<$param>

The error message returned by L<Params::Validate>.

=item B<$class>

The rountine that the error occured in.

=back

=head1 AUTOLOADING

Specific modules can be autoloaded when a method name is invoked. The 
following methods have been defined:

=head2 alert

This will autoload L<XAS::Lib::Modules::Alerts>. Please see that module
for more details.

=head2 env

This will autoload L<XAS::Lib::Modules::Environment>. Please see that module
for more details.

=head2 email

This will autoload L<XAS::Lib::Modules::Email>. Please see that module
for more details.

=head2 log

This will autoload L<XAS::Lib::Modules::Log>. Please see that module 
for more details.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
