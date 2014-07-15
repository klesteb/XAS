package XAS::Lib::Modules::Email;

our $VERSION = '0.02';

use Try::Tiny;
use MIME::Lite;
use File::Basename;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Singleton',
  utils   => 'dotid compress',
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub send {
    my $self = shift;

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
            compress($ex)
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
implemented as a singleton. It can also be auto-loaded when the method 'email'
is invoked.

=head1 METHODS

=head2 new

This method initializes the module. It uses parameters from 
L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment> to set defaults.

=head2 send

This method will send an email. It takes the following parameters:

=over 4

=item B<-to>

The SMTP address of the recipient.

=item B<-from>

The SMTP address of the sender.

=item B<-subject>

A subject line for the message.

=item B<-message>

The text of the message.

=item B<-attachment>

A file name to append to the message.

=back

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
