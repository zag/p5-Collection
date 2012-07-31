#===============================================================================
#
#  DESCRIPTION:  Class for index collections
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Collection::Index;
use strict;
use warnings;
use Collection::CrcColl;
use Collection::AutoSQLnotUnique;
use base 'Collection::CrcColl';
#store records immediately
=head2 

    $col->put( id=>{record} )

=cut

sub put {
    my $self = shift;
    my %recs = @_;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $fields = $self->_fields;
    my %records =();
    while ( my ( $k, $v ) = each %recs ) {
    #clean undeclared fields
    # TODO:   Collection::ColCrc:    
    #             unless (exists $fields->{$key}) {
    #                #skip undeclared fields
    #              next; }
    my %dirty_record = ( %$v, $field=> $k ); #add id field for create
    my $record2save = {};
    while ( my ($k, $v ) = each %dirty_record ) {
            next unless exists $fields->{$k};
            $record2save->{$k} = $v
    }
    $records{$k} =  $record2save;

    };

    $self->_store(\%records);
}

#no any ActiveRecord
sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
     return $ref;
}

sub _store {
    my $self = shift;
    return $self->Collection::AutoSQLnotUnique::_store(@_)
}

sub list_ids {
    my $self = shift;
    return $self->Collection::AutoSQLnotUnique::list_ids(@_)
}

1;


