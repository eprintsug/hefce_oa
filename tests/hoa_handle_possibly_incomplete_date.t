#!/usr/bin/perl 

# two tests for each @test_dates, one test for undefined + two BEGIN tests.
use Test::More tests => 21; 
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repo = EPrints::Test::get_test_repository();

my @test_dates = (
	{
		epdate => '2016-03-18',
		default_to_start => undef,
		expectation => '2016-03-18',
	},
	{
		epdate => '2016-03-18',
		default_to_start => 0,
		expectation => '2016-03-18',
	},
	{
		epdate => '2016-03-18',
		default_to_start => 1,
		expectation => '2016-03-18',
	},
	{
		epdate => '2016-10',
		default_to_start => undef,
		expectation => '2016-10-31',
	},
	{
		epdate => '2016-10',
		default_to_start => 0,
		expectation => '2016-10-31',
	},
	{
		epdate => '2016-10',
		default_to_start => 1,
		expectation => '2016-10-01',
	},
	{
		epdate => '2017',
		default_to_start => undef,
		expectation => '2017-12-31',
	},
	{
		epdate => '2017',
		default_to_start => 0,
		expectation => '2017-12-31',
	},
	{
		epdate => '2017',
		default_to_start => 1,
		expectation => '2017-01-01',
	},
);


SKIP: {
	#one test outside of each-date loop
	skip "\$c->{hefce_oa}->{handle_possibly_incomplete_date} not defined or not callable", ((scalar @test_dates)*2)+1 unless 
		$repo->can_call( "hefce_oa", "handle_possibly_incomplete_date" );

	
	is( $repo->call( 
		[ "hefce_oa", "handle_possibly_incomplete_date" ],
		undef
	), undef, "undef returns no object" );

	foreach my $date ( @test_dates )
	{
		my $tp = $repo->call( 
			[ "hefce_oa", "handle_possibly_incomplete_date" ],
			$date->{epdate},
			$date->{default_to_start}
		);

		
		isa_ok( $tp, 'Time::Piece');
		is( $tp->strftime( "%Y-%m-%d" ), $date->{expectation}, "Date produced as expected: {$date->{expectation}}" );
		
	} 
}


