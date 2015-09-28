# date of first deposit
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_STATUS_CHANGE, sub
{
    my( %args ) = @_; 
    my( $repo, $eprint, $old_status, $new_status ) = @args{qw( repository eprint old_status new_status )};

    return unless $old_status eq "inbox" && $new_status eq "buffer";
    return unless !$eprint->is_set( "hoa_date_dep" );

    $eprint->set_value( "hoa_date_dep", EPrints::Time::get_iso_date() );

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

}, priority => 100 );
