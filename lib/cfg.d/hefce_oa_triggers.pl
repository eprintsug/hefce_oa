#Define what types of items we're interested in
$c->{hefce_oa}->{item_types} = ['article', 'conference_item'];
# Define which document versions are 'good'
$c->{hefce_oa}->{document_content} = ['published', 'accepted'];

$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    return unless $eprint->dataset->has_field( "hoa_exclude" );

    if(!$eprint->is_set('hoa_exclude'))
    {
        $eprint->set_value('hoa_exclude', 'FALSE');
    }

    return EP_TRIGGER_OK;

}, priority => 100 );

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
        my $content = $_->value( "content" );
        next unless grep( /^$content$/, @{$repo->config( "hefce_oa", "document_content" )});
        $eprint->set_value( "hoa_date_fcd", defined $changed->{'hoa_date_fcd'} ? $changed->{'hoa_date_fcd'} : EPrints::Time::get_iso_date() ); # in the event fcd has been wiped by something, retrieve it from the $changed value
        $eprint->set_value( "hoa_version_fcd", $content eq "published" ? "VoR" : "AM" );
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
        my $content = $_->value( "content" );
        next unless grep( /^$content$/, @{$repo->config( "hefce_oa", "document_content" )} );
        next unless $_->is_public;
        # NB $changed has the *old* values in.
        $eprint->set_value( "hoa_date_foa", defined $changed->{'hoa_date_foa'} ? $changed->{'hoa_date_foa'} : EPrints::Time::get_iso_date() );
    }
}, priority => 200 );

# Sometimes a document is open-access fleetingly.
# This trigger now incorporates a 'foa_retraction_period' reckoning, based on a setting
# in the repository configuration. See:  zz_hefce_oa.pl
$c->add_dataset_trigger( 'document', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_; 
    my( $repo, $doc, $changed ) = @args{qw( repository dataobj changed )};

    # trigger only applies to repos with hefce_oa plugin enabled
    return unless $doc->parent->dataset->has_field( "hoa_compliant" );

    if( $doc->is_public )
    {
        return if $doc->parent->is_set( "hoa_date_foa" );
    }
    else
    {
        return unless $doc->parent->is_set( "hoa_date_foa" );
        return unless $repo->can_call( "hefce_oa", "commit_in_foa_retraction_period" );

        return unless $repo->call( [ "hefce_oa", "commit_in_foa_retraction_period" ], $repo, $doc->parent->value( "hoa_date_foa" ) );
        $doc->parent->set_value( "hoa_date_foa", undef );
    }

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

    my $type = $eprint->value( "type" );

    unless( defined $type && grep( /^$type$/, @{$repo->config( "hefce_oa", "item_types" )} ) )
    {
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
        EX_FUR
        EX
        AUD_UP_OA
        AUD_UP_URL
        AUD_CORE_DATES
        AUDIT
        COMPLIANT
    ))
    {
        $flag |= HefceOA::Const->$_ if $repo->call( [qw( hefce_oa run_test )], $repo, $_, $eprint, $flag );
    }
    $eprint->set_value( "hoa_compliant", $flag );

}, priority => 300 );
