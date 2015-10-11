#!/usr/bin/perl

use Test::More tests => 52;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my $repo = EPrints::Test::get_test_repository();

# no embargo
foreach my $delta ( -3..3 )
{

	my $fcd = EPrints::Time::get_iso_date();
	my $foa = Time::Piece->strptime( $fcd, "%Y-%m-%d" )->add_months($delta)->strftime( "%Y-%m-%d" );

	my $epdata = {
		eprint_status => "archive",
		type => "article",
		hoa_date_fcd => $fcd,
		hoa_date_foa => $foa,
	};
	my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
	BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

	my $flag = $eprint->value( "hoa_compliant" );

	if( $delta <= 1 )
	{
		is( $flag & HefceOA::Const::ACC_TIMING, HefceOA::Const::ACC_TIMING, "open access within 1 month of deposit" );
	}
	else
	{
		isnt( $flag & HefceOA::Const::ACC_TIMING, HefceOA::Const::ACC_TIMING, "open access not within 1 months of deposit" );
	}

	$eprint->delete;
}

my @embargos = qw( 6 12 18 24 30 36 );

foreach my $embargo ( @embargos )
{
	foreach my $delta ( -3..3 )
	{

		my $fcd = EPrints::Time::get_iso_date();
		# pub date is $embargo months ago +/- $delta
		my $pub = Time::Piece->strptime( $fcd, "%Y-%m-%d" )->add_months(-$embargo)->add_months($delta)->strftime( "%Y-%m-%d" );

		my $epdata = {
			eprint_status => "archive",
			type => "article",
			hoa_date_fcd => $fcd,
			hoa_date_pub => $pub,
			hoa_emb_len => $embargo,
		};
		my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
		BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

		$epdata = {
			content => "accepted",
		};
		my $doc = $eprint->create_subdataobj( "documents", $epdata );
		BAIL_OUT( "Failed to create doc object" ) if !defined $doc;

		my $flag = $eprint->value( "hoa_compliant" );

		if( $delta >= -1 )
		{
			is( $flag & HefceOA::Const::ACC_TIMING, HefceOA::Const::ACC_TIMING, "open access within 1 month of embargo end date" );
		}
		else
		{
			isnt( $flag & HefceOA::Const::ACC_TIMING, HefceOA::Const::ACC_TIMING, "open access not within 1 months of embargo end date" );
		}

		$eprint->delete;
	}
}
