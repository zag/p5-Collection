package Collection;

#$Id$

=head1 NAME

Collection - Collections of data or objects.

=head1 SYNOPSIS

    use Collection;
    @Collection::AutoSQL::ISA = qw(Collection);

=head1 DESCRIPTION

A collection - sometimes called a container - is simply an object that groups multiple elements into a single unit. Collections are used to store, retrieve, manipulate, and communicate aggregate data.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Collection::Utl::ActiveRecord;
use Collection::Utl::Base;
use Collection::Utl::LazyObject;
@Collection::ISA     = qw(Collection::Utl::Base);
$Collection::VERSION = '0.37';
attributes qw( _obj_cache );

sub _init {
    my $self = shift;
    $self->_obj_cache( {} );
    $self->SUPER::_init(@_);
}

=head2 _store( {ID1 => <ref to object1>[, ID2 => <ref to object2>, ...]} )

Method for store changed objects. Called with ref to hash :

 {
    ID1 => <reference to object1>
    [,ID2 => <reference to object2>,...]
 }

=cut

sub _store {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _store method";
}

=head2 _fetch({id=>ID1} [, {id=>ID2}, ...])

Read data for given IDs. Must return reference to hash, where keys is IDs,
values is readed data.
For example:

    return {1=>[1..3],2=>[5..6]}
    
=cut

sub _fetch {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _fetch method";
}

=head2 _create(<user defined>)

Create recods in data storage.

Parametrs:

    user defined format

Result:
Must return reference to hash, where keys is IDs, values is create records of data

=cut

sub _create {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _create method";
}

=head2 _delete(ID1[, ID2, ...]) or ({  id=>ID1 } [, {id => ID2 }, ...])

Delete records in data storage for given IDs.

Parametrs:
array id IDs

    ID1, ID2, ...

or array of refs to HASHes

    {  id=>ID1 }, {id => ID2 }, ...
 

Format of parametrs depend method L<delete>

=cut

sub _delete {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _delete method";
}

=head2 _prepare_record( ID1, <reference to readed by _create record>)

Called before insert readed objects into collection.
Must return ref to data or object, which will insert to callection.

=cut

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    return $ref;
}

=head2 create(<user defined>)

Public method for create objects.


=cut

sub create {
    my $self     = shift;
    my $coll_ref = $self->_obj_cache();
    my $results  = $self->_create(@_);
    return $self->fetch( keys %$results );
}

=head2 fetch_one(ID1)

Public method. Fetch object from collection for given ID.
Return ref to objects or undef unless exists.

=cut

sub fetch_object {
    die $_[0]->_deprecated('fetch_one');
}

sub fetch_one {
    my ( $self, $id ) = @_;
    my $res;
    if ( my $item_refs = $self->fetch($id) ) {
        $res = $item_refs->{$id};
    }
    return $res;
}

=head2 fetch(ID1 [, ID2, ...])

Public method. Fetch objects from collection for given IDs.
Return ref to HASH, where where keys is IDs, values is objects refs.


Parametrs:


=cut

sub fetch_objects {
    die $_[0]->_deprecated('fetch');
}

sub fetch {
    my $self = shift;
    my (@ids) =
      map { ref($_) ? $_ : { id => $_ } } grep { defined $_ } @_;
    return unless @ids;
    my $coll_ref = $self->_obj_cache();
    my (@fecth) =
      grep { !exists $_->{id} or !exists $coll_ref->{ $_->{id} } } @ids;
    if ( scalar(@fecth)
        && ( my $results = $self->_fetch(@fecth) ) )
    {

        map {
            my $ref = $self->_prepare_record( $_, $results->{$_} );
            $coll_ref->{$_} = $ref if ref($ref);
          }

          #filter aleady loaded objects
          grep { !exists $coll_ref->{$_} }
          keys %{$results};
        push @ids, map { { id => $_ } } keys %{$results};
    }
    return {
        map { $_->{id} => $coll_ref->{ $_->{id} } }
          grep { exists $_->{id} and exists $coll_ref->{ $_->{id} } } @ids
    };
}

=head2 release(ID1[, ID2, ...])

Release from collection objects with IDs. Only delete given keys from collection or all if empty

=cut

sub release_objects {
    die $_[0]->_deprecated('release');
}

sub release {
    my $self = shift;
    my (@ids) = map { ref($_) ? $_ : { id => $_ } } @_;
    my $coll_ref = $self->_obj_cache();
    unless (@ids) {
        my $res = [ map { { id => $_ } } keys %$coll_ref ];
        undef %{$coll_ref};
        return $res;
    }
    else {

        [
            map {
                delete $coll_ref->{ $_->{id} };
                $_
              }
              map { ref($_) ? $_ : { id => $_ } } @ids
        ];
    }    #else
}

=head2 store([ID1,[ID2,...]]) 

Call _store for changed objects.
Store all  all loaded objects without parameters:

    $simple_collection->store(); #store all changed

or (for 1,2,6 IDs )

    $simple_collection->store(1,2,6);

=cut

sub store_changed {
    die $_[0]->_deprecated('store');

}

sub store {
    my $self      = shift;
    my @store_ids = @_;
    my $coll_ref  = $self->_obj_cache();
    @store_ids = keys %$coll_ref unless @store_ids;
    my %to_store;
    foreach my $id (@store_ids) {
        my $ref = $coll_ref->{$id};
        next unless ref($ref);
        if ( ( ref($ref) eq 'HASH' ) ? $ref->{_changed} : $ref->_changed() ) {
            $to_store{$id} = $ref;
        }
    }
    if (%to_store) {
        $self->_store( \%to_store );
    }
}

=head2 delete(ID1[,ID2, ...])

Release from collections and delete from storage (by calling L<_delete>)
objects ID1,ID2...

    $simple_collection->delete(1,5,84);


=cut

sub delete_objects {
    die $_[0]->_deprecated('delete');
}

sub delete {
    my $self = shift;
    my (@ids) = map { ref($_) ? $_ : { id => $_ } } @_;
    $self->release(@ids);
    $self->_delete(@ids);
}

=head2 get_lazy(ID1)

Method for base support lazy load objects from data storage.
Not really return lazy object.

=cut

sub get_lazy_object {
    die $_[0]->_deprecated('get_lazy');

}

sub get_lazy {
    my ( $self, $id ) = @_;
    return new Collection::Utl::LazyObject:: sub { $self->fetch_one($id) };
}

=head2

=cut

sub get_changed_id {
    my $self     = shift;
    my $coll_ref = $self->_obj_cache();
    my @changed  = ();
    while ( my ( $id, $value ) = each %$coll_ref ) {
        if ( ref($value) eq 'HASH' ) {
            if ( my $obj = tied $value ) {
                push @changed, $id if $obj->_changed();
            }
            else {
                push @changed, $id if $value->{_changed};
            }
        }
        else {
            push @changed, $id if $value->_changed();
        }
    }
    return \@changed;
}

sub list_ids {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an list_ids method";
}
1;
__END__


=head1 SEE ALSO

Collection::AutoSQL, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

