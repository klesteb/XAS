package XAS::Lib::Modules::Email;

our $VERSION = '0.02';

my $mailers;

BEGIN {
    $mailers = qr/^smtp$|^sendmail$/;
}

use Try::Tiny;
use MIME::Lite;
use File::Basename;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base Badger::Prototype',
  utils   => 'dotid',
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub send {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my $p = $self->validate_params(\@_, {
        -to         => 1, 
        -from       => 1, 
        -subject    => 1,
        -message    => {default => ' '}, 
        -attachment => 0
    });

    my $msg;

    try {

        MIME::Lite->send(
            $self->env->mxmailer, 
            $self->env->mxserver, 
            Timeout => $self->env->mxtimeout
        );

        $msg = MIME::Lite->new(
            To      => $p->{'to'},
            From    => $p->{'from'},
            Subject => $p->{'subject'},
            Type    => 'multipart/mixed'
        );

        $msg->attach(
            Type => 'TEXT',
            Data => $p->{'message'}
        );

        if (defined($p->{'attachment'})) {

            my $filename = $p->{'attachment'};
            my ($name, $path, $suffix) = fileparse($filename, qr{\..*});

            $msg->attach(
                Type         => 'AUTO',
                Path         => $filename,
                Filename     => $name . $suffix,
                Dispostition => 'attachment'
            );

        }

        $msg->send();

    } catch { 

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.send.undeliverable',
            'undeliverable', 
            $p->{'to'}, 
            $ex
        ); 

    };

}

# ------------------------------------------------------------------------
# Private methods
# ------------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Modules::Email - The Email module for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 package My::App;

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Lib::App'
 ;

 sub main {

    $self->email->send(
        -from    => "me\@localhost",
        -to      => "you\@localhost",
        -subject => "Testing",
        -message => "This is a test"
    );

 }

 1;

=head1 DESCRIPTION

This is the the module for sending email within the XAS environment. It is
implemented as a singleton. It can also be autoloaded when the method 'email'
is invokded.

=head1 METHODS

=head2 new

This method initializes the module. It takes the following parameters:

=over 4

=item B<-server>

The default is mail.example.com. This default can changed with the environment
variable MXSERVER. It can also be changed with the named parameter -server 
upon load or the server() method after loading.

=item B<-port>

The default is 25. This default can be changed with the environment variable
MXPORT. It can also be changed with the named parameter -port upon load or the
mailer() method after loading.

=item B<-mailer>

This defines how the email is sent. There are two ways to send email they
are a direct connection using smtp or queue the mail for transmittial using
sendmail. The default is "smtp". This can be changed to "sendmail" with 
the named parameter -mailer upon load or the mailer() method after loading.

=item B<-timeout>

This sets the timeout used for sending email. The default is 60 seconds. This
can be changed with the named parameter -timeout upon load or the timeout() 
method after loading.

=back

=head2 send

This method will send an email. It takes the following parameters:

=over 4

=item B<-to>

The SMTP address of the receipent.

=item B<-from>

The SMTP adderss of the sender.

=item B<-subject>

A subject line for the message.

=item B<-message>

The text of the message.

=item B<-attachment>

A filename to append to the message.

=back

=head1 MUTATORS

=head2 mailer

This method will set/return the current mailer. 

Example

    $mailer = $email->mailer;
    $email->mailer('sendmail');

=head2 timeout

This method will set/return the current timeout value for mail processing. 

Example

    $timeout = $email->timeout;
    $email->timeout('60');

=head2 server

This method will set/return the current mxserver value for mail processing. 

Example

    $server = $email->server;
    $email->server('relay.example.com');

=head2 port

This method will set/return the current mxport value for mail processing. 

Example

    $port = $email->port;
    $email->port('25');

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
