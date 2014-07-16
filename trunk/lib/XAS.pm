package XAS;

our $VERSION = '0.07';

1;

__END__

=head1 NAME

XAS - Middleware for Perl

=head1 DESCRIPTION

These are the base modules for writting applications within the XAS 
Middleware Framework. These modules provide a consistent and uniform
method for writting distributed applications.

=head1 SEE ALSO

=over 4

=item L<XAS::Base|XAS::Base>

=item L<XAS::Class|XAS::Class>

=item L<XAS::Constants|XAS::Constants>

=item L<XAS::Exception|XAS::Exception>

=item L<XAS::Factory|XAS::Factory>

=item L<XAS::Singleton|XAS::Singleton>

=item L<XAS::Utils|XAS::Utils>

=item L<XAS::Apps::Logger|XAS::Apps::Logger>

=item L<XAS::Apps::Rotate|XAS::Apps::Rotate>

=item L<XAS::Lib::App|XAS::Lib::App>

=item L<XAS::Lib::App::Daemon|XAS::Lib::App::Daemon>

=item L<XAS::Lib::App::Services|XAS::Lib::App::Services>

=item L<XAS::Lib::App::Services::Unix|XAS::Lib::App::Services::Unix>

=item L<XAS::Lib::App::Services::Win32|XAS::Lib::App::Services::Win32>

=item L<XAS::Lib::Curses::Root|XAS::Lib::Curses::Root>

=item L<XAS::Lib::Curses::Unix|XAS::Lib::Curses::Unix>

=item L<XAS::Lib::Curses::Win32|XAS::Lib::Curses::Win32>

=item L<XAS::Lib::Mixins::Handlers|XAS::Lib::Mixins::Handlers>

=item L<XAS::Lib::Mixins::Keepalive|XAS::Lib::Mixins::Keepalive>

=item L<XAS::Lib::Modules::Alerts|XAS::Lib::Modules::Alerts>

=item L<XAS::Lib::Modules::Email|XAS::Lib::Modules::Email>

=item L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment>

=item L<XAS::Lib::Modules::Locking|XAS::Lib::Modules::Locking>

=item L<XAS::Lib::Modules::Log|XAS::Lib::Modules::Log>

=item L<XAS::Lib::Modules::Log::Console|XAS::Lib::Modules::Log::Console>

=item L<XAS::Lib::Modules::Log::Files|XAS::Lib::Modules::Log::Files>

=item L<XAS::Lib::Modules::Log::Logstash|XAS::Lib::Modules::Log:::Logstash>

=item L<XAS::Lib::Modules::Log::Syslog|XAS::Lib::Modules::Log::Syslog>

=item L<XAS::Lib::Modules::Spool|XAS::Lib::Modules::Spool>

=item L<XAS::Lib::Net::Client|XAS::Lib::Net::Client>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

=item L<XAS::Lib::Net::POE::Client|XAS::Lib::Net::POE::Client>

=item L<XAS::Lib::Service|XAS::Lib::Service>

=item L<XAS::Lib::Services|XAS::Lib::Services>

=item L<XAS::Lib::Services::Unix|XAS::Lib::Services::Unix>

=item L<XAS::Lib::Services::Win32|XAS::Lib::Services::Win32>

=item L<XAS::Lib::Session|XAS::Lib::Session>

=item L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>

=item L<XAS::Lib::SSH::Exec|XAS::Lib::SSH::Exec>

=item L<XAS::Lib::SSH::Server|XAS::Lib::SSH::Server>

=item L<XAS::Lib::SSH::Shell|XAS::Lib::SSH::Shell>

=item L<XAS::Lib::Stomp::Frame|XAS::Lib::Stomp::Frame>

=item L<XAS::Lib::Stomp::Parser|XAS::Lib::Stomp::Parser>

=item L<XAS::Lib::Stomp::POE::Client|XAS::Lib::Stomp::POE::Client>

=item L<XAS::Lib::Stomp::POE::Filter|XAS::Lib::Stomp::POE::Filter>

=item L<XAS::Lib::Stomp::Utils|XAS::Lib::Stomp::Utils>

=back

=head1 SUPPORT

Additional support is available at:

=over 4

=item  L<http://scm.kesteb.us/trac>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
