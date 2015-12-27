#!/usr/bin/perl

use Test::More tests => 3;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repo = EPrints::Test::get_test_repository();

my $pub = localtime->add_months(-3)->strftime( "%Y-%m-%d" );

# default
my $epdata = {
	eprint_status => "archive",
	type => "article",
	date => $pub,
	date_type => "published",
};

my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;
is( $eprint->value( "hoa_date_pub" ), $pub, "hoa_date_pub automatically set from default.date" );
$eprint->delete;
