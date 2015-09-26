
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
}

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
    name => "hoa_date_dep",
    type => "date",
},

# deposit exceptions
{
    name => "hoa_ex_dep",
    type => "set",
    options => [qw( a b c d e f )],
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

# other exceptions
{
    name => "hoa_ex_oth",
    type => "boolean",
    input_style => "radio",
},
{
    name => "hoa_ex_oth_txt",
    type => "longtext",
},

;

for( @{ $c->{hefce_oa}->{profile} } )
{
    $c->add_dataset_field( "eprint", $_ );
}
