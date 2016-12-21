#!/usr/bin/perl

use Test::More tests => 1;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repo = EPrints::Test::get_test_repository();

#Dates before 1900 break Time::Piece
my $pub = "1899-12-31";

# default
my $epdata = {
	eprint_status => "archive",
	type => "article",
	date => $pub,
	date_type => "published",
};

my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;
is( $eprint->value( "hoa_date_pub" ), undef, "hoa_date_pub not set for pre-1900 dates" );
$eprint->delete;
