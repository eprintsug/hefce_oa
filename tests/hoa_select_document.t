#!/usr/bin/perl 

use Test::More tests => 13;
use Time::Piece;
use strict;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "HefceOA::Const" ); }

my $repo = EPrints::Test::get_test_repository();

my $epdata = {
	eprint_status => "archive",
	type => "article",
};

my $rundate = EPrints::Time::get_iso_date();
my $embargo = Time::Piece->strptime( $rundate, "%Y-%m-%d" ); #->add_months(-$embargo)->add_months($delta)->strftime( "%Y-%m-%d" );
my $invalid_doc_data = {
                formatdesc => "submitted",
                content => "submitted",
		format => "text/plain",
};
my @valid_docs_data = (
	{
		content => "accepted",
		formatdesc => "accepted+staffonly",
		security => "staffonly",
		format => "text/plain",
	},
	{
		formatdesc => "published+staffonly",
		content => "published",
		security => "staffonly",
		format => "text/plain",
	},
	{
		formatdesc => "accepted+long_partial_date_embargo",
		content => "accepted",
		security => "staffonly",
		date_embargo => $embargo->add_months(20)->strftime( "%Y-%m" ), #should default to end of month
		format => "text/plain",
	},
	{
		formatdesc => "accepted+long_embargo",
		content => "accepted",
		security => "staffonly",
		date_embargo => $embargo->add_months(20)->strftime( "%Y-%m-15" ), #should be preferred to end-of-month
		format => "text/plain",
	},
	{
		formatdesc => "accepted+short_embargo",
		content => "accepted",
		security => "staffonly",
		date_embargo => $embargo->add_months(10)->strftime( "%Y-%m-%d" ),
		format => "text/plain",
	},
	{
		formatdesc => "published+short_embargo",
		content => "published",
		security => "staffonly",
		date_embargo => $embargo->add_months(10)->strftime( "%Y-%m-%d" ),
		format => "text/plain",
	},
	{
		formatdesc => "accepted+public",
		content => "accepted",
		security => "public",
		format => "text/plain",
	},
	{
		formatdesc => "published+public",
		content => "published",
		security => "public",
		format => "text/plain",
	},
	
);

SKIP: {
	#two tests outside of each-valid-doc loop
	skip "\$c->{hefce_oa}->{select_document} not defined or not callable", ( scalar @valid_docs_data+2 ) unless $repo->can_call( "hefce_oa", "select_document" );

	my $eprint = $repo->dataset( "eprint" )->create_dataobj( $epdata );
	BAIL_OUT( "Failed to create eprint object" ) if !defined $eprint;

	# no documents
	is( $repo->call( [ "hefce_oa", "select_document" ], $repo, $eprint ), undef, "no docs = no valid docs" );

	#one non-valid doc
	my $invalid_doc = $eprint->create_subdataobj( "documents", $invalid_doc_data );
        BAIL_OUT( "Failed to create doc object" ) if !defined $invalid_doc;

	is( $repo->call( [ "hefce_oa", "select_document" ], $repo, $eprint ), undef, "One invalid doc = no valid docs" );

	foreach my $docdata ( @valid_docs_data )
	{
		my $doc = $eprint->create_subdataobj( "documents", $docdata );
                BAIL_OUT( "Failed to create doc object" ) if !defined $doc;

		my $expectation = $docdata->{formatdesc};
		my $selected_doc = $repo->call( [ "hefce_oa", "select_document" ], $repo, $eprint);
		BAIL_OUT( "Failed to select a document" ) if !defined $selected_doc;

		my $fdesc = $selected_doc->value( "formatdesc" );
		#is( $selected_doc->value( "formatdesc" ), $expectation, "Document format as expected: $expectation." );  
		is( $fdesc, $expectation, "Document format as expected: $expectation." );  
	}

	$eprint->delete;
}

