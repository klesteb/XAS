package XAS::Lib::Mixins::Process::Win32 ;

our $VERSION = '0.01';

use Win32::OLE('in');

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'proc_status',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub proc_status {
    my $self = shift;
    my ($pid) = $self->validate_params(\@_, [1]);
    
    my $stat = 0;

    # query wmi for the an existing process with this pid

    my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or
      $self->throw_msg(
          dotid($self->class) . '.stat_process.winole',
          'unexpected',
          'WMI connection failed'
      );

    my $colItems = $objWMIService->ExecQuery(
        "SELECT * FROM Win32_Process WHERE ProcessID = $pid",
        "WQL",
        wbemFlagReturnImmediately | wbemFlagForwardOnly
    );

    # win32 wmi ExecutionState codes
    # from http://msdn.microsoft.com/en-us/library/aa394372(v=vs.85).aspx
    #
    # unknown           - 0
    # other             - 1
    # ready             - 2
    # running           - 3
    # blocked           - 4
    # suspended blocked - 5
    # suspended ready   - 6

    foreach my $objItem (in $colItems) {

        if ($objItem->{ProcessId} eq $pid) {

            $stat = $objItem->{ExecutionState} + 0;
            last;

        }

    }

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Process::Win32 - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixins::Process'
;

=head1 DESCRIPTION

This mixin provides a method to check for running processes on Win32.

=head1 METHODS

=head2 proc_status($pid)

Check for the running process. It can return one of the following status codes.

    6 - Suspended ready
    5 - Suspended blocked
    4 - Blocked
    3 - Running
    2 - Ready
    1 - Other
    0 - Unknown

=over 4

=item B<$pid>

The process id to check for.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
