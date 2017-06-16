package EPrints::Plugin::Screen::Report::REF_CC;

use EPrints::Plugin::Screen::Report;
our @ISA = ( 'EPrints::Plugin::Screen::Report' );

use HefceOA::Const;
use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{datasetid} = 'archive';
	$self->{custom_order} = '-title/creators_name';
	$self->{appears} = [];
	$self->{report} = 'ref_cc';
	$self->{disable} = 1;

	$self->{exportfields} = {
		ref_core => [ qw(
			eprintid
			type
			title
			abstract
			creators
			publisher
			divisions
			dates
			id_number
			isbn
			issn
			official_url						
		)],
		ref_rioxx => [ qw(
			rioxx2_free_to_read
			rioxx2_license_ref
			rioxx2_coverage
			rioxx2_source
			rioxx2_subject
			rioxx2_dateAccepted
			rioxx2_publication_date
			rioxx2_apc
			rioxx2_project
			rioxx2_version
			rioxx2_version_of_record
		)],
		ref_exceptions => [ qw(
		        hoa_compliant
                	hoa_ref_pan
	                hoa_ex_dep
	                hoa_ex_dep_txt
	                hoa_ex_acc
	                hoa_ex_acc_txt
	                hoa_ex_tec
	                hoa_ex_tec_txt
	                hoa_ex_oth
               		hoa_ex_oth_txt
		)],
	};

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

	#only report on the types we're interest in
	my $session = $self->{session};
        my $types = join( ' ', @{$session->config( "hefce_oa", "item_types" )} );

	push @filters, { meta_fields => [ 'type' ], value => $types, match => 'EQ', merge => 'ANY' };
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
			state => $self->get_state( $eprint ),
		};
	});

	print $self->to_json( $json );
}

#define any custom validation states
sub get_state
{
        my( $self, $eprint ) = @_;

        my $repo = $self->{repository};

        my $flag = $eprint->value( "hoa_compliant" );
	unless ( $flag & HefceOA::Const::COMPLIANT )
        {
        	if( $flag & HefceOA::Const::DEP &&
                	        $flag & HefceOA::Const::DIS &&
                        	$flag & HefceOA::Const::ACC_EMBARGO &&
	                        $repo->call( ["hefce_oa", "could_become_ACC_TIMING_compliant"], $repo, $eprint ) ) #will be compliant in future, nothing administrator can do
        	{
	                return "#E19141"; #orange
        	}
	}
	return undef;
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
		if( $flag & HefceOA::Const::DEP &&
                	$flag & HefceOA::Const::DIS &&
	                $flag & HefceOA::Const::ACC_EMBARGO &&
        	        $repo->call( ["hefce_oa", "could_become_ACC_TIMING_compliant"], $repo, $eprint ) )
		{
			push @problems,  EPrints::XML::to_string( $repo->html_phrase( "report_future_compliant", last_foa_date => $repo->xml->create_text_node( $repo->call( [ "hefce_oa", "calculate_last_compliant_foa_date" ], $repo, $eprint )->strftime( "%Y-%m-%d" ) ) ) );
		}
	}

	return @problems;
}

1;
