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
	#avoid issues with multiple archives under <v3.3.13
	$self->{disable} = 1;
	
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
	elsif( $flag & HefceOA::Const::DEP && 
		$flag & HefceOA::Const::DIS &&
		$flag & HefceOA::Const::ACC_EMBARGO &&
		$self->could_become_ACC_TIMING_compliant )
	{
		#not currently compliant, but could be if embargo is released properly
        	my $div = $repo->make_element( "div", class=>"ep_msg_warning" );
        	my $content_div = $repo->make_element( "div", class=>"ep_msg_warning_content" );
        	my $table = $repo->make_element( "table" );
        	my $tr = $repo->make_element( "tr" );
        	$table->appendChild( $tr );

                my $td1 = $repo->make_element( "td" );
                my $imagesurl = $repo->get_conf( "rel_path" );
                $td1->appendChild( 
			$repo->make_element( 
				"img", 
				class => "ep_msg_warning_icon",
				src => "$imagesurl/style/images/hoa_future_compliance.png",
				alt => $self->phrase( "future_compliant_alt" )
			)
		);
                $tr->appendChild( $td1 );

        	my $td2 = $repo->make_element( "td" );
		my $emb_len = $eprint->value( "hoa_emb_len" ) || 0;
        	$tr->appendChild( $td2 );
        	$td2->appendChild( $self->html_phrase( 
			"future_compliant", 
			last_foa_date => $repo->xml->create_text_node( $self->calculate_last_compliant_foa_date->strftime( "%Y-%m-%d" ) ),
			hoa_emb_len => $repo->xml->create_text_node( $emb_len ),
		) );
        	$content_div->appendChild( $table );
        	$div->appendChild( $content_div );

		$page->appendChild( $div );
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
	return $self->render_access_tab( $title, $tests ) if $title eq "ACC";

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

sub render_access_tab
{
	my( $self, $title, $tests ) = @_;

	my $repo = $self->{repository};
	my $tab = $repo->xml->create_document_fragment;

	my $eprint = $self->{processor}->{eprint};
	my $flag = $eprint->value( "hoa_compliant" ) || 0;

	# special case: this item may become compliant when the embargo is released
	my $class = "hoa_non_compliant";
	if( $flag & HefceOA::Const::ACC )
	{
		$class = "hoa_compliant";
	}
	elsif( $self->could_become_ACC_TIMING_compliant && $flag & HefceOA::Const::ACC_EMBARGO )
	{
		$class="hoa_future_compliant";	
	}

	my $tab_title = $self->html_phrase( "render_tab_title",
		title => $repo->html_phrase( "hefce_oa:test_title:$title" ),
		class => $repo->xml->create_text_node( $class )
	);

	$tab->appendChild( $self->html_phrase( "render_test_description",
		description => $repo->html_phrase( "hefce_oa:test_description:$title" )
	) );

	my $sub = $repo->xml->create_document_fragment;
	for( @$tests )
	{
		my $test_class = ( $flag & HefceOA::Const->$_ ? "hoa_compliant" : "hoa_non_compliant" );
		if( $_ eq "ACC_TIMING" && $self->could_become_ACC_TIMING_compliant ){
			$test_class= "hoa_future_compliant";
		}
		$sub->appendChild( $self->html_phrase( "render_test",
			title => $repo->html_phrase( "hefce_oa:test_title:$_" ),
			description => $repo->html_phrase( "hefce_oa:test_description:$_" ),
			class => $repo->xml->create_text_node( $test_class )
		) );
	}
	$tab->appendChild( $self->html_phrase( "render_tests", tests => $sub ) );

	return( $tab_title, $tab );
}

sub could_become_ACC_TIMING_compliant
{
	my( $self ) = @_;

	my $last_compliant_date = $self->calculate_last_compliant_foa_date;
	return 1 if( $last_compliant_date && ( localtime() <= $last_compliant_date ) );

	return 0;
}

sub calculate_last_compliant_foa_date
{
	my( $self ) = @_;

	my $repo = $self->{repository};

	my $eprint = $self->{processor}->{eprint};

	my $len = $eprint->value( "hoa_emb_len" ) || 0;

	# $len will be tested to see whether it is a compliant number of months in ACC_EMBARGO
	if( $len > 0  )
        {
		#need pub date to calculate embargo release date
		return undef unless $eprint->is_set( "hoa_date_pub" );

                my $pub = Time::Piece->strptime( $eprint->value( "hoa_date_pub" ), "%Y-%m-%d" );
                my $end = $pub->add_months( $len ); # embargo end
		$end = $end->add_months( 1 ); #1-month grace period
                return $end;
        }		
        else # no embargo
        {
		return undef unless $eprint->is_set( "hoa_date_fcd" );

                my $fcd = Time::Piece->strptime( $eprint->value( "hoa_date_fcd" ), "%Y-%m-%d" );

                # oa with one month of deposit
		my $end = $fcd->add_months( 1 );
                return $end;
        }

	#returns if no last foa date can be calculated
}

1;
