
push @{ $c->{hefce_oa}->{profile} },

# raison d'être
{
    name => "hoa_compliant",
    type => "int",
},

{
    name => "hoa_emb_len",
    type => "int",
},

{
    name => "hoa_ref_pan",
    type => "set",
    options => [qw( AB CD )],
    input_style => "medium",
},

# dates
{
    name => "hoa_date_acc",
    type => "date",
},
{
    name => "hoa_date_pub",
    type => "date",
},
{
    name => "hoa_date_fcd", # first compliant deposit
    type => "date",
},
{
    name => "hoa_date_foa", # first compliant open access
    type => "date",
},

# version of first compliant deposit
{
    name => "hoa_version_fcd",
    type => "set",
    options => [qw( AM VoR )],
},

# deposit exceptions
{
    name => "hoa_ex_dep",
    type => "set",
    options => [qw( a b c d e )],
    input_style => "medium",
},
{
    name => "hoa_ex_dep_txt",
    type => "longtext",
},

# access exceptions
{
    name => "hoa_ex_acc",
    type => "set",
    options => [qw( a b c )],
    input_style => "medium",
},
{
    name => "hoa_ex_acc_txt",
    type => "longtext",
},

# technical exceptions
{
    name => "hoa_ex_tec",
    type => "set",
    options => [qw( a b c )],
    input_style => "medium",
},
{
    name => "hoa_ex_tec_txt",
    type => "longtext",
},

# further exceptions
{
    name => "hoa_ex_fur",
    type => "set",
    options => [qw( a b )],
    input_style => "medium",
},
{
    name => "hoa_ex_fur_txt",
    type => "longtext",
},

# other exceptions - now redundant but used for mapping over values
{
    name => "hoa_ex_oth",
    type => "boolean",
    input_style => "radio",
},
{
    name => "hoa_ex_oth_txt",
    type => "longtext",
},

# internal flag
{
    name => "hoa_update_ep",
    type => "int",
},

# exclude option
{
    name => 'hoa_exclude',
    type => 'boolean',
},

# gold OA option
{
    name => 'hoa_gold',
    type => 'boolean',
},


# virtual field for report exports
{
    name => 'hoa_problems',
    type => 'text',
    virtual => 1,
    render_value => 'render_hoa_problems',
},

# compliance override option
{
    name => 'hoa_override',
    type => 'boolean',
    sql_index => 0,
},

# reason for compliance override
{
    name => "hoa_override_txt",
    type => "longtext",
    sql_index => 0,
},

;

for( @{ $c->{hefce_oa}->{profile} } )
{
    $c->add_dataset_field( "eprint", $_ );
}

$c->{render_hoa_problems} = sub {

        my( $repo, $field, $value, $alllangs, $nolink, $eprint ) = @_;

	my @problems;

	my $out_of_scope = $repo->call( [ "hefce_oa", "OUT_OF_SCOPE_reason" ], $repo, $eprint );
        if( $out_of_scope )
        {
       		my $frag = $repo->make_doc_fragment;
	        $frag->appendChild( $repo->html_phrase( "hefce_oa:out_of_scope:$out_of_scope" ) );
		return $frag;
	}

        my $flag = $eprint->value( "hoa_compliant" );
        unless ( $flag & HefceOA::Const::COMPLIANT )
        {
                push @problems, $repo->phrase( "Plugin/Screen/EPrint/HefceOA:non_compliant" );
                foreach my $test ( qw(
                        DEP_COMPLIANT
                        DEP_TIMING
                        DIS_DISCOVERABLE
                        ACC_TIMING
                        ACC_EMBARGO
                ))
                {
                        unless ( $flag & HefceOA::Const->$test )
                        {
                                push @problems, $repo->phrase( "hefce_oa:test_title:$test" );
                        }
                }
                if( $flag & HefceOA::Const::DEP &&
                        $flag & HefceOA::Const::DIS &&
                        $flag & HefceOA::Const::ACC_EMBARGO &&
                        $repo->call( ["hefce_oa", "could_become_ACC_TIMING_compliant"], $repo, $eprint ) )
                {
                        push @problems,  EPrints::XML::to_string( $repo->html_phrase( "report_future_compliant", last_foa_date => $repo->xml->create_text_node( $repo->call( [ "hefce_oa", "calculate_last_compliant_foa_date" ], $repo, $eprint )->strftime( "%Y-%m-%d" ) ) ) );
                }
        }
    
        my $frag = $repo->make_doc_fragment;

	my $problems_string = join(';', @problems);
        $frag->appendChild( $repo->xml->create_text_node( $problems_string ) );
        return $frag;
};


