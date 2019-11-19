#!/usr/bin/perl

use Test::More tests => 27;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my @ids = grep { EPrints::Repository->new($_)->dataset("eprint")->has_field("hoa_compliant"); } EPrints::Config::get_repository_ids;
BAIL_OUT( "Failed to find repository with module enabled" ) unless scalar @ids;
my $repo = EPrints::Repository->new( $ids[0] );

my @embargos = ( undef, qw( 0 6 12 18 24 30 36 ) );
my @panels = ( undef, qw( AB CD ) );

foreach my $embargo ( @embargos )
{
	foreach my $panel ( @panels )
	{
		my $epdata = {
			eprint_status => "archive",
			type => "article",
			hoa_emb_len => $embargo,
			hoa_ref_pan => $panel,
		};
		my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
		BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

		my $flag = $eprint->value( "hoa_compliant" );

		$panel = "AB" unless defined $panel;
		$embargo = 0 unless defined $embargo;

		if( 
			( $panel eq "AB" && $embargo <= 12 )
			||
			( $panel eq "CD" && $embargo <= 24 )
		)
		{
			is( $flag & HefceOA::Const::ACC_EMBARGO, HefceOA::Const::ACC_EMBARGO, "embargo length ok" );
		}
		else
		{
			isnt( $flag & HefceOA::Const::ACC_EMBARGO, HefceOA::Const::ACC_EMBARGO, "embargo length not ok" );
		}

		$eprint->delete;
	}
}
