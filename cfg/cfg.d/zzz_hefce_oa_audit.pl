
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


# HEFCE OA Audit DataObj
{
no warnings;

package EPrints::DataObj::HefceOA_Audit;

@EPrints::DataObj::HefceOA_Audit::ISA = qw( EPrints::DataObj );

sub get_dataset_id { "hefce_oa_audit" }

sub get_url { shift->uri }

sub get_defaults
{
    my( $class, $session, $data, $dataset ) = @_;

    $data = $class->SUPER::get_defaults( @_[1..$#_] );

    return $data;
}

# define the dataset
$c->{datasets}->{hefce_oa_audit} = {
    class => "EPrints::DataObj::HefceOA_Audit",
    sqlname => "hefce_oa_audit",
    name => "hefce_oa_audit",
    columns => [qw( auditid )],
    index => 1,
    import => 1,
};

# define fields
$c->{fields}->{hefce_oa_audit} = [] if !defined $c->{fields}->{hefce_oa_audit};
unshift @{$c->{fields}->{hefce_oa_audit}}, (
    { 
        name => "auditid",
        type => "counter",
        required => 1,
        can_clone => 0,
        sql_counter => "auditid"
    },
    { 
        name => "eprintid",
        type => "itemref",
        datasetid => "eprint",
        required => 1,
        show_in_html => 0
    },
    { 
        name => "up_datestamp", 
        type => "timestamp",
        required => 0,
        import => 0,
        render_res => "minute",
        render_style => "short",
        can_clone => 0
    },
    { 
        name => "core_datestamp", 
        type => "timestamp",
        required => 0,
        import => 0,
        render_res => "minute",
        render_style => "short",
        can_clone => 0
    },
    # Unpaywall fields
    { 
        name => 'up_is_oa', 
        type => 'boolean' 
    },
    {
        name => 'up_ur_for_pdf',
        type => 'url',
    },
    {
        name => 'up_locations',
        type => 'compound',
        multiple => 1,
        fields => [
            {
                sub_name => 'url',
                type  => 'url',
            },
            {
                sub_name => 'pmh_id',
                type  => 'text',
                allow_null => 1,
            },
            {
                sub_name => 'is_best',
                type  => 'boolean',
            },
        ],
    },
    # CORE fields
    {
        name => 'core_sources',
        type => 'compound',
        multiple => 1,
        fields => [
            {
                sub_name => 'core_id',
                type  => 'int',
            },
            {
                sub_name => 'datePublished',
                type  => 'text',
                allow_null => 1,
            },
            {
                sub_name => 'depositedDate',
                type  => 'timestamp',
                allow_null => 1,
            },
            {
                sub_name => 'publishedDate',
                type  => 'timestamp',
                allow_null => 1,
            },
            {
                sub_name => 'acceptedDate',
                type  => 'timestamp',
                allow_null => 1,
            },
        ],
    },  
);

}
