package XAS::Lib::Mixins::Iterator;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'items first last next prev size position',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub items {
    my $self = shift;

    my $values = [];
    my $table = $self->{'__table'};

    if (defined($self->{$table})) {

        $values = $self->{$table};

    }

    return wantarray ? @$values : $values;

}

sub first {
    my $self = shift;

    my $table = $self->{'__table'};
    my $postion = $self->{'__postion'} = 0;

    return $self->{$table}->[$postion];

}

sub last {
    my $self = shift;

    my $table = $self->{'__table'};
    my $position = $self->{'__position'} = $self->size - 1;

    return $self->{$table}->[$position];

}

sub next {
    my $self = shift;

    my $table = $self->{'__table'};

    if ($self->{'__position'} + 1 < $self->size){

        my $position = $self->{'__position'} += 1;
        return $self->{$table}->[$position];

    }

    return undef;

}

sub prev {
    my $self = shift;

    my $table = $self->{'__table'};

    if ($self->{'__position'} - 1 > -1) {

        my $position = $self->{'__position'} -= 1;
        return $self->{$table}->[$position];

    }

    return undef;

}

sub size {
    my $self = shift;

    my $table = $self->{'__table'};

    return scalar(@{$self->{$table}});

}

sub position {
    my $self = shift;
    my $pos  = shift;

    if (defined($pos)) {

        $self->{'__position'} = $pos if (($pos >= 0 ) && ($pos < ($self->size - 1)));

    }

    return $self->{'__position'};

}

sub init_iterator {
    my $self = shift;
    my ($table) = $self->validate_params(\@_, [ 
        { optional => 1, default => 'table' }
    ]);

    $self->{'__position'} = 0;
    $self->{'__table'} = $table;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Iterator - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class;
   version   => '0.01',
   base      => 'XAS::Base',
   mixin     => 'XAS::Lib::Mixins::Iterator',
   accessors => 'cfg'
 ;

 sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->init_iterator('cfg');

    return $self;

 }

=head1 DESCRIPTION

This is a general purpose iterator mixin. It is for handling an array of
objects. It inserts the following items into the current object.

  __position 
  __table

Which are used for bookkeeping.

=head1 METHODS

=head2 init_iterator($table)

This method initializes the iterator. It takes an option parameter. This 
parameter defaults to the value of 'table'.

=head2 items

This method returns all of the items in the table.

=head1 first

This method returns the first item from the table.

=head2 next

This method returns the next item from the table or undef if at the end
of the table.

=head2 prev

This method returns the previous item from the table or undef if at the
beginning of the table.

=head2 last

This method returns the last item from the table.

=head2 size

Return the number of items in the table.

=head2 position

Set the current position in the table.

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
