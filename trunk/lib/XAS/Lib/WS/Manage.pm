package XAS::Lib::WS::Manage;

our $VERSION = '0.01';

use Params::Validate qw( SCALAR HASHREF ARRAYREF );

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::WS::Base',
  utils   => ':validation dotid',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub enumerate {
    my $self = shift;
    my ($class) = validate_params(\@_, [
        { type => SCALAR },
    ]);
    
    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_enumerate_xml($uuid, $class);

    $self->_make_call($xml);

    return $self->_enumerate_response($uuid, $class);

}

sub get {
    my $self = shift;
    my ($class, $params) = validate_params(\@_, [
        { type => SCALAR },
        { type => HASHREF},
    ]);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_get_xml($uuid, $class, $params);

    $self->_make_call($xml);

    return $self->_get_response($uuid, $class);

}

sub invoke {
    my $self = shift;
    my ($action, $class, $params) = validate_params(\@_, [
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF },
    ]);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_invoke_xml($uuid, $class, $action, $params);

    $self->_make_call($xml);

    return $self->_invoke_response($uuid, $class, $action);

}

sub pull {
    my $self = shift;
    my ($class, $context, $items) = validate_params(\@_, [
        { type => SCALAR },
        { type => SCALAR },
        { type => ARRAYREF },
    ]);

    my $xml;
    my $uuid;
    my $running;

    do {

        $uuid = $self->uuid->create_str;
        $xml  = $self->_pull_xml($uuid, $class, $context);

        $self->_make_call($xml);

        $context = $self->_pull_response($uuid, $class, $items);

    } while ($context);

}

sub put {
    my $self = shift;
    my ($class, $key, $value, $params) = validate_params(\@_, [
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF },
    ]);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_put_xml($uuid, $class, $key, $value, $params);

    $self->_make_call($xml);

    return $self->_put_response($uuid, $class);

}

sub release {
    my $self = shift;
    my ($class, $context) = validate_params(\@_, [
        { type => SCALAR },
        { type => SCALAR },
    ]);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_release_xml($uuid, $class, $context);

    $self->_make_call($xml);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _enumerate_response {
    my $self  = shift;
    my $uuid  = shift;
    my $class = shift;

    my @items;
    my $context;
    my $xpath = "//n:EnumerationContext";

    $self->log->debug('entering - _enumerate_response()');

    $self->_check_relates_to($uuid);

    if (my $value = $self->xml->get_item($xpath)) {

        ($context) = $value =~ /uuid:(.*)/;

        $self->pull($class, $context, \@items);

    }

    return wantarray ? @items : \@items;

}

sub _get_response {
    my $self  = shift;
    my $uuid  = shift;
    my $class = shift;

    my $hash;
    my $xpath = "//p:$class";

    $self->_check_relates_to($uuid);

    if (my $elements = $self->xml->get_items($xpath)) {

        $hash = $self->_get_items($elements);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.get_response.noxpath',
            'ws_noxpath',
            $xpath
        );

    }

    return $hash;

}

sub _invoke_response {
    my $self  = shift;
    my $uuid  = shift;
    my $class  = shift;
    my $action = shift;

    my $rc = -1;
    my $xpath = sprintf('//p:%s_OUTPUT', $action);

    $self->_check_relates_to($uuid);

    if (my $elements = $self->xml->get_items($xpath)) {

        foreach my $element (@$elements) {

            if ($element->localname =~ /ReturnValue/) {

                $rc = $element->textContent;

            }

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.get_response.noxpath',
            'ws_noxpath',
            $xpath
        );

    }

    return $rc;

}

sub _pull_response {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;
    my $items = shift;

    my $context = undef;

    $self->_check_relates_to($uuid);

    if (my $value = $self->xml->get_item('//n:EnumerationContext')) {

        ($context) = $value =~ /uuid:(.*)/;

    } 

    $self->_get_enum_items($class, $items);

    return $context;

}

sub _put_response {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;

    my $hash;
    my $xpath = "//p:$class";

    $self->_check_relates_to($uuid);

    if (my $elements = $self->xml->get_items($xpath)) {

        $hash = $self->_get_items($elements);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.put_response.noxpath',
            'ws_noxpath',
            $xpath
        );

    }

    return $hash;

}

sub _get_enum_items {
    my $self = shift;
    my $class = shift;
    my $items = shift;

    my $xpath = sprintf('//p:%s', $class);

    $self->log->debug('entering _get_enum_items()');

    if (my $elements = $self->xml->get_items($xpath)) {

        my $hash = $self->_get_items($elements);

        push(@$items, $hash);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.get_enum_items.noxpath',
            'ws_noxpath',
            $xpath
        );

    }

}

sub _get_items {
    my $self = shift;
    my $elements = shift;

    my $hash = {};

    foreach my $element (@$elements) {

        my $key   = $element->localname;
        my $value = $element->textContent;

        $hash->{$key} = $value;

    }

    return $hash;

}

# ----------------------------------------------------------------------
# XML boilerplate - we're using heredoc for simplcity
# ----------------------------------------------------------------------

sub _enumerate_xml {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;
    
    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>                                                                                                                                                                                                                                                                    
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration" 
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" 
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd" 
  xmlns:b="http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd">
	<s:Header>
	  <a:To>
        $url
      </a:To>
	  <w:ResourceURI s:mustUnderstand="true">
        http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class
      </w:ResourceURI>
	  <a:ReplyTo>
		<a:Address s:mustUnderstand="true">
          http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
        </a:Address>
	  </a:ReplyTo>
	  <a:Action s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/09/enumeration/Enumerate
      </a:Action>
	  <w:MaxEnvelopeSize s:mustUnderstand="true">
        512000
      </w:MaxEnvelopeSize>
	  <a:MessageID>
        uuid:$uuid
      </a:MessageID>
	  <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
	  <p:DataLocale xml:lang="en-US" s:mustUnderstand="false"/>
      <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
	</s:Header>
	<s:Body>
	  <n:Enumerate>
	  </n:Enumerate>
	</s:Body>
</s:Envelope>
XML

    return $xml;

}

sub get_xml {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;
    my $params = shift;
    
    my $selector;
    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" 
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd">
  <s:Header>  
    <a:To>
      $url
    </a:To>                       
    <w:ResourceURI s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class
    </w:ResourceURI>
    <a:ReplyTo>
      <a:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </a:Address>
    </a:ReplyTo>
    <a:Action s:mustUnderstand="true">
      http://schemas.xmlsoap.org/ws/2004/09/transfer/Get
    </a:Action>
    <w:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </w:MaxEnvelopeSize>
    <a:MessageID>
      uuid:$uuid
    </a:MessageID>
    <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
    <p:DataLocale xml:lang="en-US" s:mustUnderstand="false"/>
    <w:SelectorSet>
      __SELECTOR__
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>
  <s:Body/>
</s:Envelope>
XML

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"%s\">%s</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub invoke_xml {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;
    my $action = shift;
    my $params = shift;

    my $selector;
    my $url     = $self->url;
    my $timeout = $self->timeout;
    my $input   = sprintf('%s_INPUT', $action);

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" 
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class
    </w:ResourceURI>
    <a:ReplyTo>
      <a:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </a:Address>
    </a:ReplyTo>
    <a:Action s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class/$action
    </a:Action>
    <w:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </w:MaxEnvelopeSize>
    <a:MessageID>
      uuid:$uuid
    </a:MessageID>
    <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
    <p:DataLocale xml:lang="en-US" s:mustUnderstand="false"/>                   
    <w:SelectorSet>
      __SELECTOR__
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>                                                                                       
  <s:Body>
    <p:__INPUT__ xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class"/>
  </s:Body>                                                                                          
</s:Envelope>
XML

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"$key\">$value</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__INPUT__/$input/;
    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub _pull_xml {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;
    my $context = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>                                                                                                                                                                                                                                                                    
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration" 
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" 
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd" 
  xmlns:b="http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd">
	<s:Header>
	  <a:To>
        $url
      </a:To>
	  <w:ResourceURI s:mustUnderstand="true">
        http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class
      </w:ResourceURI>
	  <a:ReplyTo>
		<a:Address s:mustUnderstand="true">
          http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
        </a:Address>
	  </a:ReplyTo>
	  <a:Action s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/09/enumeration/Pull        
      </a:Action>
	  <w:MaxEnvelopeSize s:mustUnderstand="true">
        512000
      </w:MaxEnvelopeSize>
	  <a:MessageID>
        uuid:$uuid
      </a:MessageID>
	  <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
	  <p:DataLocale xml:lang="en-US" s:mustUnderstand="false"/>
      <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
	</s:Header>
	<s:Body>
	  <n:Pull>
        <n:EnumerationContext>uuid:$context</n:EnumerationContext>
	  </n:Pull>
	  <n:Enumerate>
	  </n:Enumerate>
	</s:Body>
</s:Envelope>
XML
    
    return $xml;

}

sub _put_xml {
    my $self  = shift;
    my $uuid  = shift;
    my $class = shift;
    my $key   = shift;
    my $value = shift;
    my $params = shift;

    my $modify;
    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" 
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class
    </w:ResourceURI>
    <a:ReplyTo>
      <a:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </a:Address>
    </a:ReplyTo>
    <a:Action s:mustUnderstand="true">
      http://schemas.xmlsoap.org/ws/2004/09/transfer/Put
    </a:Action>
    <w:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </w:MaxEnvelopeSize>
    <a:MessageID>
      uuid:$uuid
    </a:MessageID>
    <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
    <p:DataLocale xml:lang="en-US" s:mustUnderstand="false"/>                   
    <w:SelectorSet>
      <w:Selector Name="$key">$value</w:Selector>
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>                                                                                       
  <s:Body>
    <p:$class http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class>
    __MODIFY__
  </s:Body>                                                                                          
</s:Envelope>
XML

    while (my ($name, $data) = each(%$params)) {

        $modify .= sprintf("<p:%s>%s</p:%s>\n", $name, $data, $name);

    }

    chomp $modify;

    $xml =~ s/__MODIFY__/$modify/;

    return $xml;

}

sub _release_xml {
    my $self = shift;
    my $uuid = shift;
    my $class = shift;
    my $context = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>                                                                                                                                                                                                                                                                    
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration" 
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" 
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd" 
  xmlns:b="http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd">
	<s:Header>
	  <a:To>
        $url
      </a:To>
	  <w:ResourceURI s:mustUnderstand="true">
        http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/$class
      </w:ResourceURI>
	  <a:ReplyTo>
		<a:Address s:mustUnderstand="true">
          http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
        </a:Address>
	  </a:ReplyTo>
	  <a:Action s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/09/enumeration/Release
      </a:Action>
	  <w:MaxEnvelopeSize s:mustUnderstand="true">
        512000
      </w:MaxEnvelopeSize>
	  <a:MessageID>
        uuid:$uuid
      </a:MessageID>
	  <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
	  <p:DataLocale xml:lang="en-US" s:mustUnderstand="false"/>
      <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
	</s:Header>
	<s:Body>
	  <n:Release
        <n:EnumerationContext>uuid:$context</n:EnumerationContext>
	  </n:Release
	  <n:Enumerate>
	  </n:Enumerate>
	</s:Body>
</s:Envelope>
XML

    return $xml;

}

1;

__END__

=head1 NAME

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

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
