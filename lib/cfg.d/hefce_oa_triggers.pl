# date of first compliant deposit
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	return if $eprint->is_set( "hoa_date_fcd" );
	return if $eprint->value( "eprint_status" ) eq "inbox";

	for( $eprint->get_all_documents )
	{
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

	return unless $eprint->is_set( "hoa_date_fcd" );
	return if $eprint->is_set( "hoa_date_foa" );

	for( $eprint->get_all_documents )
	{
		next unless $_->value( "content" ) eq "accepted" || $_->value( "content" ) eq "published";
		next unless $_->is_public;
    		$eprint->set_value( "hoa_date_foa", EPrints::Time::get_iso_date() );
	}
}, priority => 200 );

$c->add_dataset_trigger( 'document', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $doc, $changed ) = @args{qw( repository dataobj changed )};

	return unless $doc->is_public;
	return if $doc->parent->is_set( "hoa_date_foa" );

	# make sure eprint->commit calls triggers..
	$doc->parent->{changed}->{_poke}++;
}, priority => 100 );


# set compliance flag
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    my $type = $eprint->value( "type" );
    unless( $type eq "article" || $type eq "conference_item" )
    {
        $eprint->set_value( "hoa_compliant", undef );
        return;
    }

    my $flag = 0;
    for(qw(
        DEP_TIMING
        DEP_AAM
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
