# Workflow component
$c->{plugins}{"InputForm::Component::REF2029"}{params}{disable} = 0;

# REF2029 CC Dataobj
use EPrints::DataObj::REF2029_CC;
$c->{datasets}->{ref2029_cc} = {
    class => "EPrints::DataObj::REF2029_CC",
    sqlname => "ref2029_cc",
};

$c->add_dataset_field( 'ref2029_cc', { name => "compliant", type => "int", }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_dep', type=>"set", options => [qw(a b c )], input_style => "medium" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_acc', type=>"set", options => [qw(a b )], input_style => "medium" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_tec', type=>"set", options => [qw(a b )], input_style => "medium" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_fur', type=>"boolean" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_pub_agreement', type=>"boolean" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_other_repo', type=>"boolean" }, reuse => 1 );

# New EPrint field for new subobject
$c->add_dataset_field( 'eprint', { name => 'ref2029_cc', type=>"subobject", datasetid => 'ref2029_cc', dataobj_fieldname => 'eprintid', dataset_fieldname => '' } );


# Establish if the record falls with in the 2026 OA Compliance scope
# If it does create a REF2029 record

# TODO: Handle the record being updated/corrected to fall outside of the scope, 
# i.e. what happens when published date is changed to before Jan 2026?

$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    # we already have one, don't need more
    return if $eprint->is_set( "ref2029_cc" );

    # check if published after 1st Jan 2026
    my $JAN26 = Time::Piece->strptime( "2026-01-01", "%Y-%m-%d" );
    if( $eprint->is_set( "hoa_date_pub" ) )
    {
        my $pub;
        if( $repo->can_call( "hefce_oa", "handle_possibly_incomplete_date" ) )
        {
            $pub = $repo->call( [ "hefce_oa", "handle_possibly_incomplete_date" ], $eprint->value( "hoa_date_pub" ) );
        }
        if( !defined( $pub ) ) #above call can return undef - fallback to default
        {
            $pub = Time::Piece->strptime( $eprint->value( "hoa_date_pub" ), "%Y-%m-%d" );
        }

        if( $pub > $JAN26 )
        {
            my $ds = $repo->dataset( "ref2029_cc" );
            my $ref_cc = $ds->dataobj_class->create_from_data(
                $repo,
                {
                    eprintid => $eprint->id,
                }
            );
        }
    }

}, priority => 200 ); # needs to be called after the pub date has been set
