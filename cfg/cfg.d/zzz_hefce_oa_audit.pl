
# Uses adminemail if not set
$c->{"hefce_oa"}->{"unpaywall_email"} = undef;

$c->{"hefce_oa"}->{"unpaywall_api_base"} = "http://api.unpaywall.org/v2/";

$c->{"hefce_oa"}->{"core_api_base"} ="https://core.ac.uk/api-v2";
$c->{"hefce_oa"}->{"core_api_key"} = "JETetiYKu5ksvW1yCmolMLIjXcOxUNZa";

# trigger to (re)commit eprint after 
$c->add_dataset_trigger( 'hefce_oa_audit', EPrints::Const::EP_TRIGGER_AFTER_COMMIT, sub
{
    my( %args ) = @_; 
    my( $repo, $audit, $changed ) = @args{qw( repository dataobj changed )};

    # If nothing changes but the date then there will be only 1 key in $changed
    if(scalar keys %{$changed} > 1){
        my $eprint = $repo->get_dataset("eprint")->dataobj($audit->value("eprintid"));
        $eprint->commit;
    }

}, priority => 100 );

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

# Audit Reports
$c->{plugins}{"Screen::Report::REF_Audit::Unpaywall"}{params}{disable} = 0;
$c->{unpaywall_report}->{export_plugins} = [ qw( Export::Report::CSV Export::Report::HTML Export::Report::JSON )];
$c->{unpaywall_report}->{exportfields} = {
    ref_core => [ qw(
        eprintid
        documents.content
        type
        title
        abstract
        creators
        publisher
        publication
        divisions
        dates
        id_number
        isbn
        issn
        official_url
    )],
    ref_audit=> [ qw(
        unpaywall_oa
        unpaywall_url
    )],
};

$c->{unpaywall_report}->{custom_export} = {
    unpaywall_oa => sub {
        my( $eprint, $plugin ) = @_;

        my $repo = $eprint->repository;
        my $audit_ds = $repo->dataset( "hefce_oa_audit" );
        my $audit = $audit_ds->dataobj_class->get_audit_record( $repo, $eprint );

        return $audit->get_value( "up_is_oa" );
    },
    unpaywall_url => sub {
        my( $eprint, $plugin ) = @_;

        my $repo = $eprint->repository;
        my $audit_ds = $repo->dataset( "hefce_oa_audit" );
        my $audit = $audit_ds->dataobj_class->get_audit_record( $repo, $eprint );

        return $audit->get_value( "up_url_for_pdf" );
    },
};
