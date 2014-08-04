package XAS::Lib::Mixins::Configs;

our $VERSION = '0.01';

use Config::IniFiles;
use Params::Validate ':all';

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'dotid compress',
  mixins  => 'load_configs',
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load_configs {
    my $self = shift;
    
    $self->{cfg} = Config::IniFiles->new(
        -file => $self->cfgfile->path,
    ) or do {
        $self->log('warn', compress(join('', @Config::IniFiles::errors)));
        $self->throw_msg(
            dotid($self->class) . '.init.badini',
            'badini',
            $self->cfgfile->path
        );
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Configs - A mixin for handling config files

=head1 SYNOPSIS

 use XAS::Class;
   version   => '0.01',
   base      => 'XAS::Base',
   mixin     => 'XAS::Lib::Mixins::Configs',
   accessors => 'cfg',
 ;

=head1 DESCRIPTION

This mixin provides a standardized way to load .ini files.

=head1 METHODS

=head2 load_configs()

This method will load a config file. It needs the following accessors
available to work correctly:

 $self->cfgfile
 
It initializes this item in the object hash:

 $self->{cfg}

It is best to call this method in the classes init() routine.

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
