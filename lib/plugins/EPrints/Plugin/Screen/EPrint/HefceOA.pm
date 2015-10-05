package EPrints::Plugin::Screen::EPrint::HefceOA;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use HefceOA::Const;
use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "eprint_view_tabs",
			position => 3000,
		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return unless $self->{processor}->{eprint}->is_set( "hoa_compliant" );

	return $self->allow( "eprint/hefce_oa" );
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $page = $repo->xml->create_element( "div" ); # wrapper

	my $eprint = $self->{processor}->{eprint};
	my $flag = $eprint->value( "hoa_compliant" ) || 0;

	# overall compliance
	if( $flag & HefceOA::Const::COMPLIANT )
	{
            $page->appendChild( $repo->render_message( "message", $self->html_phrase( "compliant" ) ) );
        }
        else
        {
            $page->appendChild( $repo->render_message( "warning", $self->html_phrase( "non_compliant" ) ) );
        }
	$page->appendChild( $self->html_phrase( "render_test_description",
		description => $repo->html_phrase( "hefce_oa:test_description:COMPLIANT" )
	) );

	# tabs for individual requirements and exceptions
	my @labels;
	my @tabs;
	for(
		[ "DEP", [qw( DEP_COMPLIANT DEP_TIMING )] ],
		[ "DIS", [qw( DIS_DISCOVERABLE )] ],
		[ "ACC", [qw( ACC_TIMING ACC_EMBARGO )] ],
		[ "EX", [qw( EX_DEP EX_ACC EX_TEC EX_OTH )] ],
	)
	{
		my( $label, $tab ) = $self->render_tab( @$_ );
		push @labels, $label;
		push @tabs, $tab;
	}
	$page->appendChild( $repo->xhtml->tabs(
		\@labels,
		\@tabs,
		basename => "hoa_tabs",
	) );

	$page->appendChild( $repo->xml->create_element( "br" ) );

	# data used to check compliance
	my $box = $repo->make_element( "div", style=>"text-align: left" );
	$box->appendChild( EPrints::Box::render(
		id => "hoa_data",
		title => $self->html_phrase( "data:title" ),
		content => $self->render_data,
		collapsed => 1,
		session => $repo,
	) );
	$page->appendChild( $box );

	return $page;
}

sub render_data
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $eprint = $self->{processor}->{eprint};

	my $table = $repo->xml->create_element( "table", border => 0, cellpadding => 3 );

	foreach my $field ( qw( hoa_date_acc hoa_date_pub hoa_date_fcd eprint_status hoa_date_foa hoa_emb_len hoa_ref_pan ) )
	{
		my $tr = $repo->xml->create_element( "tr" );
		$table->appendChild( $tr );

		my $th = $repo->xml->create_element( "th", class => "ep_row" );
		$th->appendChild( $repo->html_phrase( "eprint_fieldname_$field" ) );
		$tr->appendChild( $th );

		my $td = $repo->xml->create_element( "td", class => "ep_row" );
		$td->appendChild( $eprint->is_set( $field ) ? $eprint->render_value( $field ) : $self->html_phrase( "data:unknown" ) );
		$tr->appendChild( $td );
	}

	return $table;
}

sub render_tab
{
	my( $self, $title, $tests ) = @_;

	return $self->render_exceptions_tab( $title, $tests ) if $title eq "EX";

	my $repo = $self->{repository};
	my $tab = $repo->xml->create_document_fragment;

	my $eprint = $self->{processor}->{eprint};
	my $flag = $eprint->value( "hoa_compliant" ) || 0;

	my $tab_title = $self->html_phrase( "render_tab_title",
		title => $repo->html_phrase( "hefce_oa:test_title:$title" ),
		class => $repo->xml->create_text_node( $flag & HefceOA::Const->$title ? "hoa_compliant" : "hoa_non_compliant" )
	);

	$tab->appendChild( $self->html_phrase( "render_test_description",
		description => $repo->html_phrase( "hefce_oa:test_description:$title" )
	) );

	my $sub = $repo->xml->create_document_fragment;
	for( @$tests )
	{
		$sub->appendChild( $self->html_phrase( "render_test",
			title => $repo->html_phrase( "hefce_oa:test_title:$_" ),
			description => $repo->html_phrase( "hefce_oa:test_description:$_" ),
			class => $repo->xml->create_text_node( $flag & HefceOA::Const->$_ ? "hoa_compliant" : "hoa_non_compliant" )
		) );
	}
	$tab->appendChild( $self->html_phrase( "render_tests", tests => $sub ) );

	return( $tab_title, $tab );
}

sub render_exceptions_tab
{
	my( $self, $title, $tests ) = @_;

	my $repo = $self->{repository};
	my $tab = $repo->xml->create_document_fragment;

	my $eprint = $self->{processor}->{eprint};
	my $flag = $eprint->value( "hoa_compliant" ) || 0;

	my $count = 0;
	unless( $flag & HefceOA::Const::EX )
	{
		$tab->appendChild( $self->html_phrase( "render_no_exceptions" ) );
	}
	else
	{
		my $ex = $repo->xml->create_document_fragment;
		for( qw( hoa_ex_dep hoa_ex_acc hoa_ex_tec hoa_ex_oth ) )
		{
			if( $eprint->is_set( $_ ) )
			{
				$ex->appendChild( $self->html_phrase( "render_exception", 
					title => $repo->html_phrase( "eprint_fieldname_$_" ),
					exception => $eprint->render_value( $_ ),
					explanation => $eprint->render_value( "$_\_txt" ),
				) );
				$count++;
			}
		}
		$tab->appendChild( $self->html_phrase( "render_exceptions", exceptions => $ex ) );
	}

	my $tab_title = $self->html_phrase( "render_exception_tab_title",
		count => $repo->xml->create_text_node( $count ),
	);

	return( $tab_title, $tab );
}

1;
