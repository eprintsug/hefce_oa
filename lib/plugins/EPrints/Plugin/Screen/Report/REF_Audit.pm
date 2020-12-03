package EPrints::Plugin::Screen::Report::REF_Audit;

use EPrints::Plugin::Screen::Report;
our @ISA = ( 'EPrints::Plugin::Screen::Report' );

use HefceOA::Const;
use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{appears} = [];
	$self->{report} = 'audit';
	$self->{disable} = 1;
	
	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 if( !$self->SUPER::can_be_viewed );

	return $self->allow( 'report/hefce_oa' );
}

sub filters
{
    my( $self ) = @_;

    my @filters = @{ $self->SUPER::filters || [] };

    return \@filters;
}

sub items
{
    my( $self ) = @_;

    my $repo = $self->repository;

    my $ids = $repo->call( [ "hefce_oa", "get_eligible_eprints" ], $repo );

    my $ds = $repo->dataset( $self->{datasetid} );

    my $results = $ds->list( $ids );
    return $results;
}
