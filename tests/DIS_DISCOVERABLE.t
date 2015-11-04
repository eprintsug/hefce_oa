#!/usr/bin/perl

use Test::More tests => 6;
use Cwd 'abs_path';
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my $repoid = abs_path(__FILE__);
$repoid =~ s/^.*?\/archives\/([^\/]+)\/tests\/.*?$/$1/;
my $repo = EPrints::Repository->new( $repoid );

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
