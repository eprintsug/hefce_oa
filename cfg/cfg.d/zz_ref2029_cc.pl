# https://2029.ref.ac.uk/guidance/ref-2029-open-access-policy/

# 7.5 Licensing requirements
# Array used to test license requirements
$c->{ref2029}->{licenses} = [qw(
    cc-by
    cc-by-nc
    cc-by-nd
    cc-by-nc-nd
    cc_by_4
    cc_by_nc_4
    cc_by_nd_4
    cc_by_nc_nd_4
    cc_by
    cc_by_nc
    cc_by_nd
    cc_by_nc_nd
)];

# Workflow component
$c->{plugins}{"InputForm::Component::REF2029"}{params}{disable} = 0;

# REF2029 CC Dataobj
use EPrints::DataObj::REF2029_CC;
$c->{datasets}->{ref2029_cc} = {
    class => "EPrints::DataObj::REF2029_CC",
    sqlname => "ref2029_cc",
};

# All articles and conference item records will have REF2029 CC records created
# For now we will just treat records published from Jan 26 as being in scope
# But in future we may want to add other options
$c->add_dataset_field( 'ref2029_cc', { name => 'scope', type=>"set", options =>[qw( out 21-25 26-28 )] }, reuse => 1 );

# Data used to check compliance
$c->add_dataset_field( 'ref2029_cc', { name => 'embargo', type=>"date", }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'licensed_foa', type=>"date", }, reuse => 1 );

# Results
$c->add_dataset_field( 'ref2029_cc', { name => 'compliant', type => "int", }, reuse => 1 );

# Exception Fields
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_dep', type=>"set", options => [qw( a b c )], input_style => "medium" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_dep_txt', type=>"longtext", sql_index=>0 } );

$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_acc', type=>"set", options => [qw( a b )], input_style => "medium" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_acc_txt', type=>"longtext", sql_index=>0 } );

$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_tec', type=>"set", options => [qw( a b )], input_style => "medium" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_tec_txt', type=>"longtext", sql_index=>0 } );

$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_fur', type=>"boolean" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_ex_fur_txt', type=>"longtext", sql_index=>0 } );

$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_pub_agreement', type=>"boolean" }, reuse => 1 );

# Override Flags
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_override', type=>"boolean" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_pre_compliant', type=>"boolean" }, reuse => 1 );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_pre_compliant_txt', type=>"longtext", sql_index=>0 } );
$c->add_dataset_field( 'ref2029_cc', { name => 'ref2029_gold_oa', type=>"boolean" }, reuse => 1 );

# New EPrint field for new subobject
$c->add_dataset_field( 'eprint', { name => 'ref2029_cc', type=>"subobject", datasetid => 'ref2029_cc', dataobj_fieldname => 'eprintid', dataset_fieldname => '' } );

# All potentially relevant records now get a REF2029 object, i.e. all articles and conference items
# This allows us to store events that we may need if the EPrint becomes in scope
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    # we already have one, don't need more
    return if $eprint->is_set( "ref2029_cc" );

    # is this a REF type?
    my $type = $eprint->value( "type" );
    if( defined $type && grep( /^$type$/, @{$repo->config( "hefce_oa", "item_types" )} ) )
    {
        # create the new record
        my $ds = $repo->dataset( "ref2029_cc" );
        my $ref_cc = $ds->dataobj_class->create_from_data(
            $repo,
            {
                eprintid => $eprint->id,
            }
        );

        # and calculate which OA scope it is in
        $ref_cc->calculate_scope;
    }                                  

}, priority => 300 );

# Update REF2029 record with any dates or info from the eprint
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    my $ref2029_cc = $eprint->value( "ref2029_cc" );

    $ref2029_cc->update_data if defined $ref2029_cc;

}, priority => 350 ); # needs to be called after the pub date has been set

# Set REF CC 2029 Compliance value
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;

    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    my $ref2029_cc = $eprint->value( "ref2029_cc" );

    $ref2029_cc->test_compliance if defined $ref2029_cc;

}, priority => 400 );
