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
    my $flag = $eprint->value( "hoa_compliant" );

    for(qw(
        COMPLIANT
        DEP
        DEP_TIMING
        DEP_AAM
        DIS
        DIS_DISCOVERABLE
        ACC
        ACC_TIMING
        ACC_EMBARGO
        EX_DEP
        EX_ACC
        EX_TEC
        EX_OTH
    ))
    {
        my $h = $repo->xml->create_element( "h2" );
        $h->appendChild( $repo->call( [qw( hefce_oa render_test_title )], $repo, $_ ) );
        $page->appendChild( $h );

        if( $flag & HefceOA::Const->$_ )
        {
            $page->appendChild( $repo->render_message( "message", $self->html_phrase( "test:compliant" ) ) );
        }
        else
        {
            $page->appendChild( $repo->render_message( "warning", $self->html_phrase( "test:not_compliant" ) ) );
        }

        $page->appenChild( $repo->xml->create_element( "br" ) );
        $page->appendChild( $repo->call( [qw( hefce_oa render_test_details )], $repo, $_, $eprint ) );

        $page->appenChild( $repo->xml->create_element( "br" ) );
        $page->appendChild( $repo->call( [qw( hefce_oa render_test_policy )], $repo, $_, $eprint ) );
    }

    return $page;
}

1;
