#!/usr/bin/perl

use Test::More tests => 6;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my $repo = EPrints::Test::get_test_repository();

my @states = qw( inbox buffer archive );

foreach my $state ( @states )
{
	my $epdata = {
		eprint_status => $state,
		type => "article",
	};
	my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
	BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

	my $flag = $eprint->value( "hoa_compliant" );

	if( $state eq "archive" )
	{
		is( $flag & HefceOA::Const::DIS_DISCOVERABLE, HefceOA::Const::DIS_DISCOVERABLE, "discoverable" );
	}
	else
	{
		isnt( $flag & HefceOA::Const::DIS_DISCOVERABLE, HefceOA::Const::DIS_DISCOVERABLE, "not discoverable" );
	}

	$eprint->delete;
}
