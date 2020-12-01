package EPrints::Plugin::Screen::Report::REF_Audit::Unpaywall;

use EPrints::Plugin::Screen::Report;
our @ISA = ( 'EPrints::Plugin::Screen::Report' );

use HefceOA::Const;
use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{appears} = undef;
	$self->{datasetid} = 'eprint';
	$self->{searchdatasetid} = 'archive';
	$self->{custom_order} = '-title/creators_name';
	$self->{report} = 'unpaywall';
    $self->{sconf} = 'unpaywall_report';
    $self->{export_conf} = 'unpaywall_report';
	$self->{sort_conf} = 'unpaywall_report';
	$self->{group_conf} = 'unpaywall_report';  
	
	return $self;
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

    # do we have a doi
    my $doi_field = "id_number";
    if( EPrints::Utils::is_set( $repo->get_conf( "hefce_oa", "eprintdoifield" ) ) )
    {
        #a) have we defined the doi_field within the hefce_oa conf?
        $doi_field = $repo->get_conf( "hefce_oa", "eprintdoifield" );
    }
    elsif( EPrints::Utils::is_set( $repo->get_conf( "datacitedoi", "eprintdoifield" ) ) )
    {
        #b) have we already defined the doi_field within the dataitedoi plugin?
        $doi_field = $repo->get_conf("datacitedoi","eprintdoifield");
    }    
    if( !$eprint->is_set( $doi_field ) )
    {
        push @problems, EPrints::XML::to_string( $repo->html_phrase( "audit_report:no_doi" ) );
    }

    # get audit record
    my $audit_ds = $repo->dataset( "hefce_oa_audit" );
    my $audit = $audit_ds->dataobj_class->get_audit_record( $repo, $eprint );
    if( !defined $audit )
    {
        push @problems, EPrints::XML::to_string( $repo->html_phrase( "audit_report:no_audit" ) );
    }  

    # and now the individual audit tests
    my $flag = $eprint->value( "hoa_compliant" ) || 0;
    for( qw( AUD_UP_OA AUD_UP_URL ) )
    {
        if( !( $flag & HefceOA::Const->$_ ) )
        {
            push @problems, EPrints::XML::to_string( $repo->html_phrase( "audit_report:$_" ) );
        }
    }       

	return @problems;
}

1;
