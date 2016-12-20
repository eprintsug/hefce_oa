#Define what types of items we're interested in
$c->{hefce_oa}->{item_types} = ['article', 'conference_item'];

#Default method to work out if something is in scope
#This can be overwritten to handle local field definitions e.g. if an article_type field has been added but
# only some article_types should be considered. 
$c->{hefce_oa}->{in_scope} = sub {
	my( $repo, $eprint ) = @_;
	
	my $type = $eprint->value( "type" );

	return 0 if !defined $type;
	
	return 1 if $type eq 'article';
	return 1 if $type eq 'conference_item' && $eprint->exists_and_set( "issn" );

	# we could fall back to old definition, but this would negate the check above for conference items
	# with an ISSN
	# return 1 if grep( /^$type$/, @{$repo->config( "hefce_oa", "item_types" )} );
	
	# default is out-of-scope
	return 0;
};


# date of first compliant deposit
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $eprint->dataset->has_field( "hoa_compliant" );

	return if $eprint->is_set( "hoa_date_fcd" );
	return if $eprint->value( "eprint_status" ) eq "inbox";

	for( $eprint->get_all_documents )
	{
		next unless $_->is_set( "content" );
		next unless $_->value( "content" ) eq "accepted" || $_->value( "content" ) eq "published";
    		$eprint->set_value( "hoa_date_fcd", EPrints::Time::get_iso_date() );
    		$eprint->set_value( "hoa_version_fcd", $_->value( "content" ) eq "accepted" ? "AM" : "VoR" );
	}
}, priority => 100 );

# date of first compliant open access
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $eprint->dataset->has_field( "hoa_compliant" );

	return unless $eprint->is_set( "hoa_date_fcd" );
	return if $eprint->is_set( "hoa_date_foa" );

	for( $eprint->get_all_documents )
	{
		next unless $_->is_set( "content" );
		next unless $_->value( "content" ) eq "accepted" || $_->value( "content" ) eq "published";
		next unless $_->is_public;
    		$eprint->set_value( "hoa_date_foa", EPrints::Time::get_iso_date() );
	}
}, priority => 200 );

$c->add_dataset_trigger( 'document', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $doc, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $doc->parent->dataset->has_field( "hoa_compliant" );

	return unless $doc->is_public;
	return if $doc->parent->is_set( "hoa_date_foa" );

	# make sure eprint->commit calls triggers..
	# see https://github.com/eprintsug/hefce_oa/issues/19
	$doc->parent->{changed}->{hoa_update_ep}++;
}, priority => 100 );


# set compliance flag
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_;
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $eprint->dataset->has_field( "hoa_compliant" );

	# try new function in config first; fall back to simpler item_types
	my $in_scope = 0;
	if( $repo->can_call( "hefce_oa", "in_scope" ) ){
		$in_scope = $repo->call( [ "hefce_oa", "in_scope" ], $repo, $eprint );
	} else { 
		my $type = $eprint->value( "type" );

		$in_scope = defined $type && grep( /^$type$/, @{$repo->config( "hefce_oa", "item_types" )} );
	}
	
	if( !$in_scope ){
		$eprint->set_value( "hoa_compliant", undef );
		return;
	}

	my $flag = 0;
	for(qw(
		DEP_COMPLIANT
		DEP_TIMING
		DEP
		DIS_DISCOVERABLE
		DIS
		ACC_TIMING
		ACC_EMBARGO
		ACC
		EX_DEP
		EX_ACC
		EX_TEC
		EX_OTH
		EX
		COMPLIANT
	))
	{
		$flag |= HefceOA::Const->$_ if $repo->call( [qw( hefce_oa run_test )], $repo, $_, $eprint, $flag );
	}

	$eprint->set_value( "hoa_compliant", $flag );

}, priority => 300 );
