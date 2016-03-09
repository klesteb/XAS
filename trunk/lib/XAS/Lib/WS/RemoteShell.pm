package XAS::Lib::WS::RemoteShell;

our $VERSION = '0.02';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::WS::Base',
  codec     => 'base64',
  accessors => 'created command_id shell_id stderr stdout exitcode',
  vars => {
    PARAMS => {
      -keep_alive  => { optional => 1, default => 1 },
      -auth_method => { optional => 1, default => 'basic', regex => qr/any|noauth|basic|digest|ntlm|negotiate/ },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# XML for ws-manage RemoteShell was taken from
# http://msdn.microsoft.com/en-us/library/cc251731.aspx
#
# Some may think it is cheesy to use heredoc for the raw xml, but this
# stuff is boilerplate and it is easier then using SOAP::Lite or
# manually creating a SOAP XML document with XML::LibXML.
#

sub create {
    my $self = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;
    my $uuid    = $self->uuid->create_str;

    $self->log->debug(sprintf('create: uuid - %s', $uuid));

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>
      $url
    </wsa:To>
    <wsman:ResourceURI s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
    </wsman:ResourceURI>
    <wsa:ReplyTo>
      <wsa:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action s:mustUnderstand="true">
      http://schemas.xmlsoap.org/ws/2004/09/transfer/Create
    </wsa:Action>
    <wsman:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </wsman:MaxEnvelopeSize>
    <wsa:MessageID>
      uuid:$uuid
    </wsa:MessageID>
    <wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
    <wsman:OptionSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <wsman:Option Name="WINRS_NOPROFILE">TRUE</wsman:Option>
      <wsman:Option Name="WINRS_CODEPAGE">437</wsman:Option>
    </wsman:OptionSet>
    <wsman:OperationTimeout>
      PT$timeout.000S
    </wsman:OperationTimeout>
  </s:Header>
  <s:Body>
    <rsp:Shell xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell">
      <rsp:InputStreams>stdin</rsp:InputStreams>
      <rsp:OutputStreams>stdout stderr</rsp:OutputStreams>
    </rsp:Shell>
  </s:Body>
</s:Envelope>
XML

    $self->_make_call($xml);

    return $self->_create_response($uuid);

}

sub command {
    my $self = shift;
    my ($command) = $self->validate_params(\@_, [1]);

    my $url      = $self->url;
    my $timeout  = $self->timeout;
    my $shell_id = $self->shell_id;
    my $uuid     = $self->uuid->create_str;

    $self->{'stdout'} = '';
    $self->{'stderr'} = '';
    $self->{'exitcode'} = 0;

    $self->log->debug(sprintf('command: uuid - %s', $uuid));
    $self->log->debug(sprintf('command: shell_id - %s', $shell_id));

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>
      $url
    </wsa:To>
    <wsman:ResourceURI s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
    </wsman:ResourceURI>
    <wsa:ReplyTo>
      <wsa:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Command
    </wsa:Action>
    <wsman:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </wsman:MaxEnvelopeSize>
    <wsa:MessageID>
      uuid:$uuid
    </wsa:MessageID>
    <wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
    <wsman:SelectorSet>
      <wsman:Selector Name="ShellId">
        $shell_id
      </wsman:Selector>
    </wsman:SelectorSet>
    <wsman:OptionSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <wsman:Option Name="WINRS_CONSOLEMODE_STDIN">TRUE</wsman:Option>
    </wsman:OptionSet>
    <wsman:OperationTimeout>PT$timeout.000S</wsman:OperationTimeout>
  </s:Header>
  <s:Body>
    <rsp:CommandLine xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell">
      <rsp:Command>
        &quot;$command&quot;
      </rsp:Command>
    </rsp:CommandLine>
  </s:Body>
</s:Envelope>
XML

    $self->_make_call($xml);
    $self->_command_response($uuid);

}

sub send {
    my $self = shift;
    my ($buffer) = $self->validate_params(\@_, [1]);

    my $url        = $self->url;
    my $timeout    = $self->timeout;
    my $shell_id   = $self->shell_id;
    my $command_id = $self->command_id;
    my $uuid       = $self->uuid->create_str;

    $buffer = encode($buffer);

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>
      $url
    </wsa:To>
    <wsa:ReplyTo>
      <wsa:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Send
    </wsa:Action>
    <wsman:MaxEnvelopeSize s:mustUnderstand="true">153600</wsman:MaxEnvelopeSize>
    <wsa:MessageID>
      uuid:$uuid
    </wsa:MessageID>
    <wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
    <wsman:ResourceURI xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
    </wsman:ResourceURI>
    <wsman:SelectorSet
      xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
      xmlns="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      <wsman:Selector Name="ShellId">
        $shell_id
      </wsman:Selector>
    </wsman:SelectorSet>
      <wsman:OperationTimeout>PT$timeout.000S</wsman:OperationTimeout>
  </s:Header>
  <s:Body>
    <rsp:Send xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell">
      <rsp:Stream
        xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell"
        Name="stdin" CommandId="$command_id">
        $buffer
      </rsp:Stream>
    </rsp:Send>
  </s:Body>
</s:Envelope>
XML

    $self->_make_call($xml);

    return $self->_send_response($uuid);

}

sub receive {
    my $self = shift;

    my $running    = 1;
    my $url        = $self->url;
    my $timeout    = $self->timeout;
    my $shell_id   = $self->shell_id;
    my $command_id = $self->command_id;
    my $uuid       = $self->uuid->create_str;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>
      $url
    </wsa:To>
    <wsa:ReplyTo>
      <wsa:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Receive
    </wsa:Action>
    <wsman:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </wsman:MaxEnvelopeSize>
    <wsa:MessageID>
      uuid:$uuid
    </wsa:MessageID>
    <wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
    <wsman:ResourceURI xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
    </wsman:ResourceURI>
    <wsman:SelectorSet
      xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
      xmlns="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      <wsman:Selector Name="ShellId">
        $shell_id
      </wsman:Selector>
    </wsman:SelectorSet>
    <wsman:OperationTimeout>PT$timeout.000S</wsman:OperationTimeout>
  </s:Header>
  <s:Body>
    <rsp:Receive
      xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell"
      SequenceId="0">
      <rsp:DesiredStream CommandId="$command_id">
        stdout stderr
      </rsp:DesiredStream>
    </rsp:Receive>
    </s:Body>
</s:Envelope>
XML

    while ($running) {

        $self->_make_call($xml);
        $running = $self->_receive_response($uuid);

    }

}

sub signal {
    my $self = shift;

    my $url        = $self->url;
    my $timeout    = $self->timeout;
    my $shell_id   = $self->shell_id;
    my $command_id = $self->command_id;
    my $uuid       = $self->uuid->create_str;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>
      $url
    </wsa:To>
    <wsa:ReplyTo>
      <wsa:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Signal
    </wsa:Action>
    <wsman:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </wsman:MaxEnvelopeSize>
    <wsa:MessageID>
      uuid:$uuid
    </wsa:MessageID>
    <wsman:Locale xml:lang="en-US" s:mustUnderstand="false"/>
    <wsman:ResourceURI xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
    </wsman:ResourceURI>
    <wsman:SelectorSet xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
      xmlns="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      <wsman:Selector Name="ShellId">
        $shell_id
      </wsman:Selector>
    </wsman:SelectorSet>
    <wsman:OperationTimeout>PT$timeout.000S</wsman:OperationTimeout>
  </s:Header>
  <s:Body>
    <rsp:Signal
      xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell"
      CommandId="$command_id">
      <rsp:Code>
        http://schemas.microsoft.com/wbem/wsman/1/windows/shell/signal/terminate
      </rsp:Code>
    </rsp:Signal>
  </s:Body>
</s:Envelope>
XML

    $self->_make_call($xml);

    return $self->_signal_response($uuid);

}

sub delete {
    my $self = shift;

    my $url      = $self->url;
    my $timeout  = $self->timeout;
    my $shell_id = $self->shell_id;
    my $uuid     = $self->uuid->create_str;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>
      $url
    </wsa:To>
    <wsa:ReplyTo>
      <wsa:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action s:mustUnderstand="true">
      http://schemas.xmlsoap.org/ws/2004/09/transfer/Delete
    </wsa:Action>
    <wsman:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </wsman:MaxEnvelopeSize>
    <wsa:MessageID>
      uuid:$uuid
    </wsa:MessageID>
    <wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
    <wsman:ResourceURI xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
      http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
    </wsman:ResourceURI>
    <wsman:SelectorSet
      xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
      xmlns="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
        <wsman:Selector Name="ShellId">
          $shell_id
        </wsman:Selector>
    </wsman:SelectorSet>
    <wsman:OperationTimeout>PT$timeout.000S</wsman:OperationTimeout>
  </s:Header>
  <s:Body></s:Body>
</s:Envelope>
XML

    $self->_make_call($xml);

    return $self->_delete_response($uuid);

}

sub destroy {
    my $self = shift;

    if ($self->created) {

        $self->signal();
        $self->delete();

    }

}

sub DESTROY {
    my $self = shift;

    $self->destroy();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _check_relates_to {
    my $self = shift;
    my $uuid = shift;

    my $temp;
    my $xpath = '//a:RelatesTo';

    $temp = $self->xml->get_item($xpath);
    ($temp) = $temp =~ /uuid:(.*)/;

    $self->log->debug(sprintf('check_relates_to: %s = %s', $uuid, $temp));

    unless ($temp eq $uuid) {

        $self->throw_msg(
            dotid($self->class) . '.check_relates_to.wronguuid',
            'ws_wronguuid'
        );

    }

}

sub _check_command_id {
    my $self = shift;
    my $uuid = shift;

    $self->log->debug(sprintf('check_command_id: %s = %s', $uuid, $self->command_id));

    unless ($uuid eq $self->command_id) {

        $self->throw_msg(
            dotid($self->class) . '.check_command_id.wrongid',
            'ws_wrongid'
        );

    }

}

sub _create_response {
    my $self = shift;
    my $uuid = shift;

    my $xpath;
    my $stat = 0;

    $self->_check_relates_to($uuid);

    if ($self->xml->get_item('//x:ResourceCreated')) {

        if (my $item = $self->xml->get_item('//rsp:ShellId')) {

            $self->{'shell_id'} = $item;
            $self->log->debug(sprintf('create_response: shell_id = %s', $self->shell_id));

            $stat = 1;

        } else {

            $self->throw_msg(
                dotid($self->class) . '._create_response.shell_id',
                'ws_noshellid',
            );

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '._create_response.resourcecreated',
            'ws_noresource',
        );

    }

    return $stat;

}

sub _command_response {
    my $self = shift;
    my $uuid = shift;

    my $xpath = '//rsp:CommandId';

    $self->_check_relates_to($uuid);

    if (my $id = $self->xml->get_item($xpath)) {

        $self->{'command_id'} = $id;

    } else {

        $self->throw_msg(
            dotid($self->class) . '._command_reponse.command_id',
            'ws_nocmdid',
        );

    }

}

sub _receive_response {
    my $self = shift;
    my $uuid = shift;

    my $running = 1;
    my $xpath = '//rsp:ReceiveResponse';

    $self->_check_relates_to($uuid);

    my $elements = $self->xml->get_items($xpath);

    foreach my $element (@$elements) {

        if ($element->nodeName =~ /Stream/) {

            my $name = $element->getAttribute('Name');
            my $id   = $element->getAttribute('CommandId');

            $self->_check_command_id($id);

            if ($name =~ /stdout/) {

                if (my $stuff = $element->textContent) {

                    $self->{'stdout'} .= decode($stuff);

                }

            } elsif ($name =~ /stderr/) {

                if (my $stuff = $element->textContent) {

                    $self->{'stderr'} .= decode($stuff);

                }

            }

        } elsif ($element->nodeName =~ /CommandState/) {

            my $state = $element->getAttribute('State');
            my $id    = $element->getAttribute('CommandId');

            $self->_check_command_id($id);

            $running = ($state =~ /Running/ || 0);

            if (my $children = $element->childNodes) {

                foreach my $child (@$children) {

                    if ($child->nodeName =~ /ExitCode/) {

                        $self->{'exitcode'} = $child->textContent;

                    }

                }

            }

        }

    }

    return $running;

}

sub _send_response {
    my $self = shift;
    my $uuid = shift;

    my $stat = 0;
    my $xpath = '//rsp:SendResponse';

    $self->_check_relates_to($uuid);

    $stat = 1 if ($self->xml->get_items($xpath));

    return $stat;

}

sub _signal_response {
    my $self = shift;
    my $uuid = shift;

    my $stat = 0;
    my $xpath = '//rsp:SignalResponse';

    $self->_check_relates_to($uuid);

    $stat = 1 if ($self->xml->get_item($xpath));

    return $stat;

}

sub _delete_response {
    my $self = shift;
    my $uuid = shift;

    my $stat = 0;
    my $xpath = '//rsp:DeleteResponse';

    $self->_check_relates_to($uuid);

    $stat = 1 if ($self->xml->get_item($xpath));

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'created'} = 0;

    return $self;

}

1;

__END__

=head1 NAME

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::WS::RemoteShell;

 my $wsman = XAS::Lib::WS::RemoteShell->new(
    -username => 'Administrator',
    -password => 'password',
    -url      => 'http://localhost:5985/wsman',
 );

 # this appears to be the sequence that winrs uses.

 if ($wsman->create()) {

     $wsman->command('dir');
     $wsman->receive();
     $wsman->signal();
     $wsman->delete();

 }

 printf("%s", $wsman->stdout);
 printf("exit code: %s\n", $wsman->exitcode);

=head1 DESCRIPTION

This package implements a client for the RemoteShell feature of WS-Manage. 
Getting the RemoteShell feature working under Windows is not easy. The 
reasons for these problems may be hidden in a Knowledge Base articule on 
MSDN. These problems are mostly related to authentication and quirks of the
winrm server.

On Windows 2013 R2 the "Windows Remote Management Server" needs to be 
configured as follows:

From a powershell console.

 ps> cd WSman:\localhost\
 ps> cd Client
 ps> set-item AllowUnencrypted $true
 ps> set-item TrustedHosts "*"
 ps> dir
 ps> cd ..\Service
 ps> set-item AllowUnencrypted $true
 ps> cd Auth
 ps> set-item Basic $true
 ps> dir
 ps> cd ..
 ps> dir
 ps> cd ..

Other versions of Windows are done similarily. This will allow connections 
from a none Windows box. These connections will be in clear text. 
B<This should not be used on the public internet>.

This configuration will allow for an unencrypted HTTP connection with BASIC 
Authentication to a local user account, on the target box. You may wish to 
use the local Administrator account.

The usage of SSL for security will require additional configuration. Which 
is not documented well. By default, Windows doesn't listen on port 5986.

Using a Domain account requires kerberos authentication. I have not gotten this
to work with RemoteShell. It may require additional configuration for that
to work. But this configuration is not documented. Hence, the current usage. 
Once again, refer to that mythical Knowledge Base articule on MSDN.

The Linux version (L<OpenWSMAN v2.2.3|https://openwsman.github.io/>) doesn't 
implement the RemoteShell feature.

=head1 METHODS

=head2 new

This class inherits from L<XAS::Lib::WS::Base|XAS::Lib::WS::Base> and takes 
the same parameters. The parameters:

    -keep_alive
    -auth_method

Have been defaulted to approbriate values.

=head2 create

This method makes the initial connection to the server and creates a remote
shell. It returns TRUE if it was successful.

=head2 command($command)

This method will send a command to the server to be executed by the shell.

=over 4

=item B<$command>

The command string to send.

=back

=head2 send

This method will send a buffer to the remote shell. 

=head2 receive

This method will receive output from the remote shell. This will include
output for STDOUT and STDERR. The exit code will also be retrieved from the
command.

=head2 signal

This method will send a "terminate" signal to the remote shell.

=head2 delete

This method will delete the remote shell.

=head2 stdout

This method returns the output from STDOUT.

=head2 stderr

This method returns the output from STDERR.

=head2 exitcode

This method returns the exit code.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::WS::Base|XAS::Lib::WS::Base>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
