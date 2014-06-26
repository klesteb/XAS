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

=item L<XAS::Base>

=item L<XAS::Class>

=item L<XAS::Constants>

=item L<XAS::Exceptions>

=item L<XAS::Factory>

=item L<XAS::Utils>

=item L<XAS::Apps::Logger>

=item L<XAS::Apps::Rotate>

=item L<XAS::Lib::App>

=item L<XAS::Lib::App::Daemon>

=item L<XAS::Lib::App::Services>

=item L<XAS::Lib::App::Services::Unix>

=item L<XAS::Lib::App::Services::Win32>

=item L<XAS::Lib::Mixins::Handlers>

=item L<XAS::Lib::Mixins::Keepalive>

=item L<XAS::Lib::Modules::Alerts>

=item L<XAS::Lib::Modules::Email>

=item L<XAS::Lib::Modules::Environment>

=item L<XAS::Lib::Modules::Locking>

=item L<XAS::Lib::Modules::Log>

=item L<XAS::Lib::Modules::Log::Console>

=item L<XAS::Lib::Modules::Log::Files>

=item L<XAS::Lib::Modules::Log::Logstash>

=item L<XAS::Lib::Modules::Log::Syslog>

=item L<XAS::Lib::Modules::Spool>

=item L<XAS::Lib::Net::Client>

=item L<XAS::Lib::Net::Server>

=item L<XAS::Lib::Net::POE::Client>

=item L<XAS::Lib::Service>

=item L<XAS::Lib::Service::Unix>

=item L<XAS::Lib::Service::Win32>

=item L<XAS::Lib::Session>

=item L<XAS::Lib::SSH::Client>

=item L<XAS::Lib::SSH::Server>

=item L<XAS::Lib::Stomp::Frame>

=item L<XAS::Lib::Stomp::Parser>

=item L<XAS::Lib::Stomp::POE::Client>

=item L<XAS::Lib::Stomp::POE::Filter>

=item L<XAS::Lib::Stomp::Utils>

=back

=head1 SUPPORT

Additional support is available at:

  http://scm.kesteb.us/trac

=head1 AUTHOR

Kevin Esteb, C<< <kevin at kesteb.us> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
