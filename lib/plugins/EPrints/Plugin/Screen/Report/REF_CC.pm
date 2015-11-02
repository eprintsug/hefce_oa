package EPrints::Plugin::Screen::Report::REF_CC;

use EPrints::Plugin::Screen::Report;
our @ISA = ( 'EPrints::Plugin::Screen::Report' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{datasetid} = 'eprint';
	$self->{custom_order} = '-title/creators_name';
	$self->{appears} = [];
	$self->{report} = 'ref_cc';
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

	push @filters, { meta_fields => [ 'type' ], value => 'article conference_item', match => 'EQ', merge => 'ANY' };
	push @filters, { meta_fields => [ 'eprint_status' ], value => 'archive', match => 'EX' };

	return \@filters;
}

sub ajax_eprint
{
	my( $self ) = @_;

	my $repo = $self->repository;

	my $json = { data => [] };

	$repo->dataset( "eprint" )
	->list( [$repo->param( "eprint" )] )
	->map(sub {
		(undef, undef, my $eprint) = @_;

		return if !defined $eprint; # odd

		my $frag = $eprint->render_citation_link_staff;
		push @{$json->{data}}, { 
			datasetid => $eprint->dataset->base_id, 
			dataobjid => $eprint->id, 
			summary => EPrints::XML::to_string( $frag ),
#			grouping => sprintf( "%s", $eprint->value( SOME_FIELD ) ),
			problems => [ $self->validate_dataobj( $eprint ) ],
		};
	});

	print $self->to_json( $json );
}


sub validate_dataobj
{
	my( $self, $eprint ) = @_;

	my $repo = $self->{repository};

	my @problems;

	my $flag = $eprint->value( "hoa_compliant" );
	unless ( $flag & HefceOA::Const::COMPLIANT )
	{
		push @problems, $repo->phrase( "Plugin/Screen/EPrint/HefceOA:non_compliant" ); 
		foreach my $test ( qw(
			DEP_COMPLIANT
			DEP_TIMING
			DIS_DISCOVERABLE
			ACC_TIMING
			ACC_EMBARGO
		))
		{
			unless ( $flag & HefceOA::Const->$test )
			{
				push @problems, $repo->phrase( "hefce_oa:test_title:$test" ); 
			}
		}
	}

	return @problems;
}

1;
