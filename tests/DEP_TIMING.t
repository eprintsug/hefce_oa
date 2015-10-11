#!/usr/bin/perl

use Test::More tests => 25;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my $repo = EPrints::Test::get_test_repository();

foreach my $delta ( -5..5 )
{
	my $fcd = EPrints::Time::get_iso_date();
	my $acc = Time::Piece->strptime( $fcd, "%Y-%m-%d" )->add_months($delta)->strftime( "%Y-%m-%d" );

	my $epdata = {
		eprint_status => "archive",
		type => "article",
		hoa_date_fcd => $fcd,
		hoa_date_acc => $acc,
	};
	my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
	BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

	my $flag = $eprint->value( "hoa_compliant" );

	if( $delta >= -3 )
	{
		is( $flag & HefceOA::Const::DEP_TIMING, HefceOA::Const::DEP_TIMING, "deposit within 3 months of acceptance" );
	}
	else
	{
		isnt( $flag & HefceOA::Const::DEP_TIMING, HefceOA::Const::DEP_TIMING, "deposit not within 3 months of acceptance" );
	}

	$eprint->delete;
}

foreach my $delta ( -5..5 )
{
	my $fcd = "2015-06-05";
	my $acc = Time::Piece->strptime( $fcd, "%Y-%m-%d" )->add_months(-6)->strftime( "%Y-%m-%d" ); # 6 months before deposit
	my $pub = Time::Piece->strptime( $fcd, "%Y-%m-%d" )->add_months($delta)->strftime( "%Y-%m-%d" );

	my $epdata = {
		eprint_status => "archive",
		type => "article",
		hoa_date_fcd => $fcd,
		hoa_date_acc => $acc,
		hoa_date_pub => $pub,
	};
	my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
	BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

	my $flag = $eprint->value( "hoa_compliant" );

	if( $delta >= -3 )
	{
		is( $flag & HefceOA::Const::DEP_TIMING, HefceOA::Const::DEP_TIMING, "deposit within 3 months of publication" );
	}
	else
	{
		isnt( $flag & HefceOA::Const::DEP_TIMING, HefceOA::Const::DEP_TIMING, "deposit not within 3 months of publication" );
	}

	$eprint->delete;
}
