package XAS::Factory;

our $VERSION = '0.01';

use Badger::Factory::Class
  debug   => 0,
  version => $VERSION,
  item    => 'module',
  path    => 'XAS::Lib XAS::Lib::Modules',
  modules => {
    alert       => 'XAS::Lib::Modules::Alerts',
    email       => 'XAS::Lib::Modules::Email',
    environment => 'XAS::Lib::Modules::Environment',
    log         => 'XAS::Lib::Modules::Log',
    logger      => 'XAS::Lib::Modules::Log',
    locking     => 'XAS::Lib::Modules::Locking',
    lockmgr     => 'XAS::Lib::Modules::Locking',
    spool       => 'XAS::Lib::Modules::Spool',
    spooler     => 'XAS::Lib::Modules::Spool',
  }
;

1;

__END__
  
=head1 NAME

XAS::Factory - A factory system for the XAS environment

=head1 SYNOPSIS

You can use this module in the following manner.

 use XAS::Factory;

 my $env = XAS::Factory->module('environment');

 ... or ...

 my $env = XAS:Factory->module('Environment');

Either of the above statements will load the XAS::Lib::Modules::Environment module.

=head1 DESCRIPTION

This module is a factory system for the XAS environment. It will load and
initialize modules on demand. The advantage is that you don't need to load
all your modules at the beginning of your program. You also don't need to
know where individual modules live. And this system can provide nice alias 
for long module names. This should lead to cleaner more readable programs.

=head1 MODULES

The following modules have been defined.

=over 4

=item B<alert>

This will load L<XAS::Lib::Modules::Alerts|XAS::Lib::Modules::Alerts>.

=item B<email>

This will load L<XAS::Lib::Modules::Email|XAS::Lib::Modules::Email>.

=item B<environment>

This will load L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment>

=item B<log logger>

This will load L<XAS::Lib::Modules::Log|XAS::Lib::Modules::Log>

=item B<locking lockmgr>

This will load L<XAS::Lib::Modules::Locking|XAS::Lib::Modules::Locking>.

=item B<spool spooler>

This will load L<XAS::Lib::Modules::Spool|XAS::Lib::Modules::Spool>.

=back

=head1 METHODS

=head2 module

This method loads the named module and passes any parameters to that module.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
