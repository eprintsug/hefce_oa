$c->{plugins}{"Screen::EPrint::HefceOA"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC::2015"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC::2016"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC::2017"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC::2018"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC::2019"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC::2020"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX::2015"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX::2016"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX::2017"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX::2018"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX::2019"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC_EX::2020"}{params}{disable} = 0;
$c->{plugins}{"Export::Report::CSV::REF_CC"}{params}{disable} = 0;

#set which can have a custom search, allowing their filter function to be overwridden
$c->{plugins}{"Screen::Report::REF_CC"}{params}{custom} = 1;
$c->{plugins}{"Screen::Report::REF_CC_EX"}{params}{custom} = 1;

push @{ $c->{user_roles}->{editor} }, qw{ +eprint/hefce_oa };
push @{ $c->{user_roles}->{admin} }, qw{ +eprint/hefce_oa };
push @{ $c->{user_roles}->{admin} }, qw{ +report/hefce_oa };

#set if embargoed records should appear in report as compliant
$c->{hefce_oa}->{embargo_as_compliant} = 0;

$c->{hefce_report}->{exportfields} = {
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
        ref_rioxx => [ qw(
        	rioxx2_free_to_read
                rioxx2_license_ref
                rioxx2_coverage
                rioxx2_source
                rioxx2_subject
                rioxx2_dateAccepted
                rioxx2_publication_date
                rioxx2_apc
                rioxx2_project
                rioxx2_version
                rioxx2_version_of_record
	)],
        ref_exceptions => [ qw(
                hoa_compliant
                hoa_problems
                hoa_ref_pan
                hoa_ex_dep
                hoa_ex_dep_txt
                hoa_ex_acc
                hoa_ex_acc_txt
                hoa_ex_tec
                hoa_ex_tec_txt
                hoa_ex_oth
                hoa_ex_oth_txt
	)],
};

$c->{hefce_report}->{exportfield_defaults} = [ qw( eprintid documents.content type title creators dates hoa_compliant hoa_problems ) ];

$c->{hefce_report}->{custom_export} = {
        hoa_compliant => sub {
		my( $dataobj, $plugin ) = @_;

                my $compliance = "Compliant";

                my $repo = $dataobj->repository;

                my $out_of_scope = $repo->call( [ "hefce_oa", "OUT_OF_SCOPE_reason" ], $repo, $dataobj );
                if( $out_of_scope eq "gold" )
                {
                        return "Out of scope (Gold OA)";
                }
                elsif( $out_of_scope eq "acc" || $out_of_scope eq "pub" )
                {
                        return "Out of scope (Pre April 2016)";
                }

                my @problems = $plugin->validate_dataobj( $dataobj );
                if( scalar( @problems ) > 0 )
                {
                        $compliance = "Not Compliant";
                }

                my $state = $plugin->get_state( $dataobj );
                if( defined $state && $state eq "#E19141" )
                {
                        $compliance = "Compliant pending open access";
                }
                return $compliance;
        },
        creators => sub {
        	my( $dataobj ) = @_;

                my @creator_names;
                my $creators = $dataobj->get_value( "creators" );
                foreach my $c ( @{$creators} )
                {
                	push @creator_names, EPrints::Utils::make_name_string( $c->{name} );
	        }
                return join( ";", @creator_names );
	},
        dates => sub {
		my( $dataobj ) = @_;

                my @date_strings;
                my $dates = $dataobj->get_value( "dates" );
                foreach my $d ( @{$dates} )
                {
			push @date_strings, $d->{date} . " (" . $d->{date_type} . ")";
                }
                return join( ";", @date_strings );
	},
};

####################################################
# Trigger to map exceptions from old to new values #
# Deposit exception (g) --> Further exception (b)  #
# Deposit exception (f) --> Gold OA (hoa_gold)     #
# Other exception --> Further exception (a)        #
####################################################
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_;
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# Deposit exception (g) --> Further exception (b)
	if( ( $eprint->is_set( "hoa_ex_dep" ) && $eprint->get_value( "hoa_ex_dep" ) eq "g" ) ||
   		( exists $changed->{hoa_ex_dep} && $changed->{hoa_ex_dep} eq "g" ) )
	{
		$eprint->set_value( "hoa_ex_fur", "b" );
	}

	# Deposit exception (f) --> Gold OA (hoa_gold)
	if( ( $eprint->is_set( "hoa_ex_dep" ) && $eprint->get_value( "hoa_ex_dep" ) eq "f" ) ||
   		( exists $changed->{hoa_ex_dep} && $changed->{hoa_ex_dep} eq "f" ) )
	{
		$eprint->set_value( "hoa_gold", "TRUE" );
	}	

	# Other exception --> Further exception (a)
	if( ( $eprint->is_set( "hoa_ex_oth" ) && $eprint->get_value( "hoa_ex_oth" ) eq "TRUE" ) ||
   		( exists $changed->{hoa_ex_oth} && $changed->{hoa_ex_oth} eq "TRUE" ) )
	{
		$eprint->set_value( "hoa_ex_fur", "a" );
		if( $eprint->is_set( "hoa_ex_oth_txt" ) )
		{
			$eprint->set_value( "hoa_ex_fur_txt", $eprint->get_value( "hoa_ex_oth_txt" ) );
		}
	}
	
}, priority => 50 );

