package XAS;

our $VERSION = '0.08';

1;

__END__

=head1 NAME

XAS - Middleware for Operations

=head1 DESCRIPTION

These are the base modules for writing applications within the XAS 
Middleware for Operations framework. These modules provide a consistent 
and uniform method for writing distributed applications.

=head1 SEE ALSO

=over 4

=item L<XAS::Base|XAS::Base>

=item L<XAS::Class|XAS::Class>

=item L<XAS::Constants|XAS::Constants>

=item L<XAS::Exception|XAS::Exception>

=item L<XAS::Factory|XAS::Factory>

=item L<XAS::Utils|XAS::Utils>

=item L<XAS::Apps::Logger|XAS::Apps::Logger>

=item L<XAS::Apps::Rotate|XAS::Apps::Rotate>

=item L<XAS::Lib::App|XAS::Lib::App>

=item L<XAS::Lib::App::Daemon|XAS::Lib::App::Daemon>

=item L<XAS::Lib::App::Service|XAS::Lib::App::Service>

=item L<XAS::Lib::App::Service::Unix|XAS::Lib::App::Service::Unix>

=item L<XAS::Lib::App::Service::Win32|XAS::Lib::App::Service::Win32>

=item L<XAS::Lib::Curl::HTTP|XAS::Lib::Curl::HTTP>

=item L<XAS::Lib::Mixins::Bufops|XAS::Lib::Mixins::Bufops>

=item L<XAS::Lib::Mixins::Configs|XAS::Lib::Mixins::Configs>

=item L<XAS::Lib::Mixins::Handlers|XAS::Lib::Mixins::Handlers>

=item L<XAS::Lib::Mixins::Iterator|XAS::Lib::Mixins::Iterator>

=item L<XAS::Lib::Mixins::JSON::Client|XAS::Lib::Mixins::JSON::Client>

=item L<XAS::Lib::Mixins::JSON::Server|XAS::Lib::Mixins::JSON::Server>

=item L<XAS::Lib::Mixins::Keepalive|XAS::Lib::Mixins::Keepalive>

=item L<XAS::Lib::Modules::Alerts|XAS::Lib::Modules::Alerts>

=item L<XAS::Lib::Modules::Email|XAS::Lib::Modules::Email>

=item L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment>

=item L<XAS::Lib::Modules::Locking|XAS::Lib::Modules::Locking>

=item L<XAS::Lib::Modules::Log|XAS::Lib::Modules::Log>

=item L<XAS::Lib::Modules::Log::Console|XAS::Lib::Modules::Log::Console>

=item L<XAS::Lib::Modules::Log::Files|XAS::Lib::Modules::Log::Files>

=item L<XAS::Lib::Modules::Log::Json|XAS::Lib::Modules::Log::Json>

=item L<XAS::Lib::Modules::Log::Syslog|XAS::Lib::Modules::Log::Syslog>

=item L<XAS::Lib::Modules::Spool|XAS::Lib::Modules::Spool>

=item L<XAS::Lib::Net::Client|XAS::Lib::Net::Client>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

=item L<XAS::Lib::Net::POE::Client|XAS::Lib::Net::POE::Client>

=item L<XAS::Lib::Pidfile|XAS::Lib::Pidfile>

=item L<XAS::Lib::Pidfile::Unix|XAS::Lib::Pidfile::Unix>

=item L<XAS::Lib::Pidfile::Win32|XAS::Lib::Pidfile::Win32>

=item L<XAS::Lib::POE::PubSub|XAS::Lib::POE::PubSub>

=item L<XAS::Lib::POE::Session|XAS::Lib::POE::Session>

=item L<XAS::Lib::POE::Service|XAS::Lib::POE::Service>

=item L<XAS::Lib::Process|XAS::Lib::Process>

=item L<XAS::Lib::Process::Unix|XAS::Lib::Process::Unix>

=item L<XAS::Lib::Process::Win32|XAS::Lib::Process::Win32>

=item L<XAS::Lib::Service|XAS::Lib::Service>

=item L<XAS::Lib::Service::Unix|XAS::Lib::Service::Unix>

=item L<XAS::Lib::Service::Win32|XAS::Lib::Service::Win32>

=item L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>

=item L<XAS::Lib::SSH::Client::Exec|XAS::Lib::SSH::Client::Exec>

=item L<XAS::Lib::SSH::Client::Shell|XAS::Lib::SSH::Client::Shell>

=item L<XAS::Lib::SSH::Client::Subsystem|XAS::Lib::SSH::Client::Subsystem>

=item L<XAS::Lib::SSH::Server|XAS::Lib::SSH::Server>

=item L<XAS::Lib::Stomp::Frame|XAS::Lib::Stomp::Frame>

=item L<XAS::Lib::Stomp::Parser|XAS::Lib::Stomp::Parser>

=item L<XAS::Lib::Stomp::POE::Client|XAS::Lib::Stomp::POE::Client>

=item L<XAS::Lib::Stomp::POE::Filter|XAS::Lib::Stomp::POE::Filter>

=item L<XAS::Lib::Stomp::Utils|XAS::Lib::Stomp::Utils>

=back

=head1 SUPPORT

Additional support is available at:

  http://www.kesteb.us/trac

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
