
# Uses adminemail if not set
$c->{"hefce_oa"}->{"unpaywall_email"} = undef;

$c->{"hefce_oa"}->{"unpaywall_api_base"} = "http://api.unpaywall.org/v2/";

$c->{"hefce_oa"}->{"core_api_base"} ="https://core.ac.uk/api-v2";
$c->{"hefce_oa"}->{"core_api_key"} = "[enter core api key here]";


# get all eligible eprints
$c->{hefce_oa}->{get_eligible_eprints} = sub
{
    my( $session ) = @_;

    # create a search expression
    my $ds = $session->get_repository->get_dataset( "archive" );
    my $search_exp = EPrints::Search->new(
        session => $session,
        satisfy_all => 1,
        dataset => $ds,
    );

    # only relevant types
    my $types = join( ' ', @{$session->config( "hefce_oa", "item_types" )} );
    $search_exp->add_field(
        fields => [ $ds->field( 'type' ) ],
        value => $types,
        match => "EQ",
        merge => "ANY",
    );

    # only stuff accepted from April 2016
    $search_exp->add_field(
        fields => [ $ds->field( 'hoa_date_acc' ) ],
        value => "2016-04-",
        match => "IN",
    );

    # now filter out anything out of scope...
    my $list = $search_exp->perform_search;
    my @eligible_eprints;
    $list->map(sub{
        my($session, $dataset, $eprint) = @_;

        my $out_of_scope = $session->call( [ "hefce_oa", "run_test_OUT_OF_SCOPE" ], $session, $eprint );
        if( !$out_of_scope )
        {
            push @eligible_eprints, $eprint->id;
        }
    });

    return \@eligible_eprints;
};
