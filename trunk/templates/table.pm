package XAS::Model::Database::XXXX::Result::XXXX;

our $VERSION = '0.01';

use XAS::Class
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM'
;

__PACKAGE__->load_components( qw/ InflateColumn::DateTime OptimisticLocking / );
__PACKAGE__->table( 'XXXX' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        sequence          => 'XXXX_id_seq',
        is_nullable       => 0
    },


    revision => {
        data_type   => 'integer',
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

}

sub table_name {
    return __PACKAGE__;
}

1;

__END__
 
=head1 NAME

XAS::Model::Database::XXXX::Result::XXXX - Table defination for XAS Model

=head1 DESCRIPTION

The definition for the log table.

=head1 FIELDS

=head2 id

An automatic incremental index.

=over 4

=item B<data type> - bigint

=item B<sequence name> - 'XXXX_id_seq'

=item B<is nullable> - no

=back

=head2 revision

Used by L<DBIx::Class::OptimisticLocking|https://metacpan.org/pod/DBIx::Class::Optimisticlocking>
to manage changes for this record.

=over 4

=item B<data type> - integer
 
=item B<is nullable> - yes

=back

=head1 METHODS

=head2 sqlt_deploy_hook($sqlt_table)

This method is used when a database schema is being generated. It can be used
to add additional features.

=over 4

=item B<$sqlt_table>

The DBIx::Class class for this table.

=back

=head2 table_name

Used by the helper functions mixed in from L<XAS::Model::DBM|XAS::Model::DBM>.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, <kevin@kesteb.us>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
