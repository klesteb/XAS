package XAS::Class;

use Badger::Class
  uber     => 'Badger::Class',
  constant => {
      UTILS     => 'XAS::Utils',
      CONSTANTS => 'XAS::Constants',
  }
;

1;

__END__

=head1 NAME

XAS::Class - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
     version => '0.01',
     base    => 'XAS::Base'
 ;

=head1 DESCRIPTION

This module ties the XAS environment to the base Badger object framework. It
exposes the defined constants and utilities that reside in L<XAS::Constants|XAS::Constants> and
L<XAS::Utils|XAS::Utils>. Which inherits from L<Badger::Constants|http://badgerpower.com/docs/Badger/Class.html> and 
L<Badger::Utils|http://badgerpower.com/docs/Badger/Utils.html>.

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
