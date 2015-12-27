#!/usr/bin/perl

use Test::More tests => 4;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repo = EPrints::Test::get_test_repository();

my $acc = localtime->add_months(-6)->strftime( "%Y-%m-%d" );
my $pub = localtime->add_months(-3)->strftime( "%Y-%m-%d" );

my $epdata = {
	eprint_status => "archive",
	type => "article",
	rioxx2_dateAccepted_input => $acc,
	rioxx2_publication_date_input => $pub,
};

SKIP: {
	skip "rioxx2 not installed", 2 unless $repo->dataset("eprint")->has_field("rioxx2_dateAccepted");

	my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
	BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

	is( $eprint->value( "hoa_date_acc" ), $acc, "hoa_date_acc automatically set from rioxx2.rioxx2_dateAccepted" );
	is( $eprint->value( "hoa_date_pub" ), $pub, "hoa_date_pub automatically set from rioxx2.rioxx2_publication_date" );
}
