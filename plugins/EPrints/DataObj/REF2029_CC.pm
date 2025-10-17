# A REF CC dataobj that will be used to store all things REF OA compliance
# related for an EPrint. This has two main advantages...
# 1) We don't need to add more fields to the EPrints table
# 2) All of our methods needed for assessing compliance can be made here

package EPrints::DataObj::REF2029_CC;

our @ISA = qw( EPrints::DataObj::SubObject );

use strict;
use Data::Dumper;

# The new method can simply return the constructor of the super class (Dataset)
sub new
{
    return shift->SUPER::new( @_ );
}

sub get_dataset_id
{
    my ($self) = @_;
    return "ref2029_cc";
}

sub get_parent_dataset_id
{
    "eprint";
}

sub get_parent_id
{
    my( $self ) = @_;

    return $self->get_value( "eprintid" );
}

sub get_system_field_info
{
    my( $class ) = @_;

    return
    (
        { name => "ref2029_ccid", type => "counter", required => 1, import => 0, show_in_html => 0, can_clone => 0, sql_counter => "ref2029_ccid" },

        { name => "eprintid", type => "itemref", datasetid => "eprint", required => 1 },
    );
}

sub commit
{
    my( $self, $force ) = @_;

    # this will call set_ref2029_cc_automatic_fields
    $self->update_triggers();

    if( scalar( keys %{$self->{changed}} ) == 0 )
    {
        # don't do anything if there isn't anything to do
        return( 1 ) unless $force;
    }

    return $self->SUPER::commit( $force );
}

sub create_from_data
{
    my( $class, $session, $data, $dataset ) = @_;

    my $self = $class->SUPER::create_from_data( $session, $data, $dataset );

    return undef unless defined $self;

    # this will call set_ref2029_cc_automatic_fields
    $self->update_triggers();

    $self->SUPER::commit();

    return $self;
}
