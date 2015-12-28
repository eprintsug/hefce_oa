#!/usr/bin/perl

# see https://github.com/eprintsug/hefce_oa/issues/19
# without the hoa_update_ep hack this test will fail
# change hoa_update_ep to _poke and re-run to see database
# errors reported in #19

use Test::More tests => 4;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repo = EPrints::Test::get_test_repository();

my $epdata = {
	eprint_status => "archive",
	type => "article",
};
my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

$epdata = {
	format => "text/plain",
};
my $doc = $eprint->create_subdataobj( "documents", $epdata );
BAIL_OUT( "Failed to create doc object" ) if !defined $doc;

$doc->commit;

is( $eprint->value( "hoa_date_fcd" ), undef, "hoa_date_fcd not set" );

$doc->set_value( "content", "accepted" );
$doc->commit; # should run eprint level triggers via hoa_update_ep hack

isnt( $eprint->value( "hoa_date_fcd" ), undef, "hoa_date_fcd set" );

$eprint->delete;
