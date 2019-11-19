#!/usr/bin/perl

use Test::More tests => 46;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my @ids = grep { EPrints::Repository->new($_)->dataset("eprint")->has_field("hoa_compliant"); } EPrints::Config::get_repository_ids;
BAIL_OUT( "Failed to find repository with module enabled" ) unless scalar @ids;
my $repo = EPrints::Repository->new( $ids[0] );

my @states = qw( inbox buffer archive );
my @types = qw( article conference_item book );
my @content = qw( submitted accepted published );

foreach my $state ( @states )
{
	foreach my $type ( @types )
	{
		foreach my $content ( @content )
		{
			my $epdata = {
				eprint_status => $state,
				type => $type,
			};
			my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
			BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

			$epdata = {
				content => $content,
			};
			my $doc = $eprint->create_subdataobj( "documents", $epdata );
			BAIL_OUT( "Failed to create doc object" ) if !defined $doc;

			my $flag = $eprint->value( "hoa_compliant" ) || 0;

			if( $state ne "inbox" && $type ne "book" && $content ne "submitted" )
			{
				is( $flag & HefceOA::Const::DEP_COMPLIANT, HefceOA::Const::DEP_COMPLIANT, "compliant deposit" );
				is( $eprint->value( "hoa_date_fcd" ), EPrints::Time::get_iso_date(), "date of fcd is today" );
				my $expected = $content eq "accepted" ? "AM" : "VoR";
				is( $eprint->value( "hoa_version_fcd" ), $expected, "version of fcd is $expected" );
			}
			else
			{
				isnt( $flag & HefceOA::Const::DEP_COMPLIANT, HefceOA::Const::DEP_COMPLIANT, "non-compliant deposit" );
			}

			$eprint->delete;
		}
	}
}
