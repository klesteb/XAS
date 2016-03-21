package XAS::Lib::WS::Manage;

our $VERSION = '0.01';

use Params::Validate qw( SCALAR HASHREF ARRAYREF );

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::WS::Base',
  utils   => ':validation dotid',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -class    => { type => SCALAR },
        -selector => { type => SCALAR },
        -xml      => { type => SCALAR },
    });

    my $data     = $p->{'-xml'};
    my $class    = $p->{'-class'};
    my $resource = $p->{'-resource'};
    my $selector = $p->{'-selector'};

    my $object = sprintf('%s/%s', $resource, $class);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_create_xml($uuid, $object, $selector, $data);

    $self->_make_call($xml);

    return $self->_create_response($uuid);

}

sub delete {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -class    => { type => SCALAR },
        -selector => { type => SCALAR },
    });

    my $class    = $p->{'-class'};
    my $resource = $p->{'-resource'};
    my $selector = $p->{'-selector'};

    my $object = sprintf('%s/%s', $resource, $class);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_delete_xml($uuid, $object, $selector);

    $self->_make_call($xml);

    return $self->_delete_response($uuid);

}

sub enumerate {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -selector => { optional => 1, type => HASHREF, default => undef },
        -class    => { type => SCALAR },
    });

    my $class    = $p->{'-class'};
    my $resource = $p->{'-resource'};
    my $selector = $p->{'-selector'};

    my $object = sprintf('%s/%s', $resource, $class);

    my $xml;
    my $uuid = $self->uuid->create_str;

    if (defined($selector)) {

        $xml  = $self->_enumerate_filter_xml($uuid, $object, $selector)

    } else {

        $xml  = $self->_enumerate_xml($uuid, $object)

    }

    $self->_make_call($xml);

    return $self->_enumerate_response($uuid, $resource, $class);

}

sub get {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -class    => { type => SCALAR },
        -selector => { type => HASHREF }
    });

    my $class    = $p->{'-class'};
    my $resource = $p->{'-resource'};
    my $selector = $p->{'-selector'};

    my $object = sprintf('%s/%s', $resource, $class);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_get_xml($uuid, $object, $selector);

    $self->_make_call($xml);

    return $self->_get_response($uuid, $class);

}

sub invoke {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -action   => { type => SCALAR },
        -class    => { type => SCALAR },
        -selector => { type => HASHREF },
    });

    my $class    = $p->{'-class'};
    my $action   = $p->{'-action'};
    my $resource = $p->{'-resource'};
    my $selector = $p->{'-selector'};

    my $object  = sprintf('%s/%s', $resource, $class);
    my $oaction = sprintf('%s/%s', $object, $action);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_invoke_xml($uuid, $object, $oaction, $action, $selector);

    $self->_make_call($xml);

    return $self->_invoke_response($uuid, $class, $action);

}

sub pull {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -class    => { type => SCALAR },
        -context  => { type => SCALAR },
        -items    => { type => ARRAYREF },
    });

    my $items    = $p->{'-items'};
    my $class    = $p->{'-class'};
    my $context  = $p->{'-context'};
    my $resource = $p->{'-resource'};

    my $object = sprintf('%s/%s', $resource, $class);

    my $xml;
    my $uuid;
    my $running;

    do {

        $uuid = $self->uuid->create_str;
        $xml  = $self->_pull_xml($uuid, $object, $context);

        $self->_make_call($xml);

        $context = $self->_pull_response($uuid, $class, $items);

    } while ($context);

}

sub put {
    my $self = shift;
    my $p = validate_params(\@_, {
        -resource => { optional => 1, default => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2' },
        -class    => { type => SCALAR },
        -key      => { type => SCALAR },
        -value    => { type => SCALAR },
        -data     => { type => HASHREF },
    });

    my $key      = $p->{'-key'};
    my $data     = $p->{'-data'};
    my $value    = $p->{'-value'};
    my $class    = $p->{'-class'};
    my $resource = $p->{'-resource'};

    my $object = sprintf('%s/%s', $resource, $class);

    my $uuid = $self->uuid->create_str;
    my $xml  = $self->_put_xml($uuid, $object, $class, $key, $value, $data);

    $self->_make_call($xml);

    return $self->_put_response($uuid, $class);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _create_response {
    my $self = shift;
    my $uuid = shift;

    my $stat = 0;
    my $xpath = '//t:ResourceCreated';

    $self->log->debug('entering - _create_response()');

    $self->_check_relates_to($uuid);
    $self->_check_action('CreateResponse');

    $stat = 1 if ($self->xml->get_item($xpath));

    return $stat;

}

sub _delete_response {
    my $self = shift;
    my $uuid = shift;

    $self->log->debug('entering - _delete_response()');

    $self->_check_relates_to($uuid);
    $self->_check_action('DeleteResponse');

    return 1;

}

sub _enumerate_response {
    my $self     = shift;
    my $uuid     = shift;
    my $resource = shift;
    my $class    = shift;

    my @items;
    my $context;
    my $xpath = "//n:EnumerationContext";

    $self->log->debug('entering - _enumerate_response()');

    $self->_check_relates_to($uuid);
    $self->_check_action('EnumerateResponse');

    if (my $value = $self->xml->get_item($xpath)) {

        ($context) = $value =~ /uuid:(.*)/;

        $self->pull(
            -resource => $resource,
            -class    => $class,
            -context  => $context,
            -items    => \@items
        );

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
    $self->_check_action('GetResponse');

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
    my $response = sprintf('%sResponse', $action);
    my $xpath = sprintf('//p:%s_OUTPUT', $action);

    $self->_check_relates_to($uuid);
    $self->_check_action($response);

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
    $self->_check_action('PullResponse');

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
    $self->_check_action('PutResponse');

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
#
# XML for ws-manage Manage was taken from
# https://msdn.microsoft.com/en-us/library/cc251705.aspx
# ----------------------------------------------------------------------

sub _create_xml {
    my $self     = shift;
    my $uuid     = shift;
    my $resource = shift;
    my $params   = shift;
    my $xml_data = shift;

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
      $resource
    </w:ResourceURI>
    <a:ReplyTo>
      <a:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </a:Address>
    </a:ReplyTo>
    <a:Action s:mustUnderstand="true">
      http://schemas.xmlsoap.org/ws/2004/09/transfer/Create
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
    $xml_data
  </s:Body>
</s:Envelope>
XML

    my $selector = '';

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"%s\">%s</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub _delete_xml {
    my $self = shift;
    my $uuid = shift;
    my $resource = shift;
    my $params = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      $resource
    </w:ResourceURI>
    <a:ReplyTo>
      <a:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </a:Address>
    </a:ReplyTo>
    <a:Action s:mustUnderstand="true">
      http://schemas.xmlsoap.org/ws/2004/09/transfer/Delete
    </a:Action>
    <w:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </w:MaxEnvelopeSize>
    <a:MessageID>
      uuid:$uuid
    </a:MessageID>
    <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
    <w:SelectorSet>
      __SELECTOR__
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>
  <s:Body/>
</s:Envelope>
XML

    my $selector = '';

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"%s\">%s</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub _enumerate_xml {
    my $self = shift;
    my $uuid = shift;
    my $resource = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>                                                                                                                                                                                                          
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration"
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
  xmlns:b="http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      $resource
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
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>
  <s:Body>
    <n:Enumerate/>
  </s:Body>
</s:Envelope>
XML

    return $xml;

}

sub _enumerate_filter_xml {
    my $self = shift;
    my $uuid = shift;
    my $resource = shift;
    my $params = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>                                                                                                                                                                                                          
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration"
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
  xmlns:b="http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      $resource
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
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>
  <s:Body>
    <n:Enumerate>
      <w:Filter Dialect="http://schemas.dmtf.org/wbem/wsman/1/wsman/SelectorFilter">
        <w:SelectorSet>
          __SELECTOR__
        </w:SelectorSet>
      </w:Filter>
    </n:Enumerate>
  </s:Body>
</s:Envelope>
XML

    my $selector = '';

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"%s\">%s</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub _get_xml {
    my $self     = shift;
    my $uuid     = shift;
    my $resource = shift;
    my $params   = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      $resource
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
    <w:SelectorSet>
      __SELECTOR__
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>
  <s:Body/>
</s:Envelope>
XML

    my $selector = '';

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"%s\">%s</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub _invoke_xml {
    my $self = shift;
    my $uuid = shift;
    my $resource = shift;
    my $oaction = shift;
    my $action = shift;
    my $params = shift;

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
      $resource
    </w:ResourceURI>
    <a:ReplyTo>
      <a:Address s:mustUnderstand="true">
        http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
      </a:Address>
    </a:ReplyTo>
    <a:Action s:mustUnderstand="true">
      $oaction
    </a:Action>
    <w:MaxEnvelopeSize s:mustUnderstand="true">
      512000
    </w:MaxEnvelopeSize>
    <a:MessageID>
      uuid:$uuid
    </a:MessageID>
    <w:Locale xml:lang="en-US" s:mustUnderstand="false"/>
    <w:SelectorSet>
      __SELECTOR__
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>                                                                   
  <s:Body>
    <p:__INPUT__ xmlns:p="$resource"/>
  </s:Body>                                                                     
</s:Envelope>
XML

    my $selector = '';

    while (my ($key, $value) = each(%$params)) {

        $selector .= sprintf("<w:Selector Name=\"%s\">%s</w:Selector>\n", $key, $value);

    }

    chomp $selector;

    $xml =~ s/__INPUT__/$input/;
    $xml =~ s/__SELECTOR__/$selector/;

    return $xml;

}

sub _pull_xml {
    my $self = shift;
    my $uuid = shift;
    my $resource = shift;
    my $context = shift;

    my $url     = $self->url;
    my $timeout = $self->timeout;

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>                                                                                                                                                                                                          
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration"
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
  xmlns:b="http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd">
  <s:Header>
    <a:To>
      $url
    </a:To>
    <w:ResourceURI s:mustUnderstand="true">
      $resource
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
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>
  <s:Body>
    <n:Pull>
      <n:EnumerationContext>uuid:$context</n:EnumerationContext>
    </n:Pull>
    <n:Enumerate/>
  </s:Body>
</s:Envelope>
XML

    return $xml;

}

sub _put_xml {
    my $self  = shift;
    my $uuid  = shift;
    my $resource = shift;
    my $class = shift;
    my $key   = shift;
    my $value = shift;
    my $params = shift;

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
      $resource
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
    <w:SelectorSet>
      <w:Selector Name="$key">$value</w:Selector>
    </w:SelectorSet>
    <w:OperationTimeout>PT$timeout.000S</w:OperationTimeout>
  </s:Header>                                                                   
  <s:Body>
    <p:$class $resource>
    __MODIFY__
    </p:$class>
  </s:Body>                                                                     
</s:Envelope>
XML

    my $modify = '';

    while (my ($name, $data) = each(%$params)) {

        $modify .= sprintf("<p:%s>%s</p:%s>\n", $name, $data, $name);

    }

    chomp $modify;

    $xml =~ s/__MODIFY__/$modify/;

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
