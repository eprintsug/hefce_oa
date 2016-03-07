use Date::Parse;
use HefceOA::Const;
use Time::Piece;

$c->{hefce_oa}->{run_test} = sub {
    my( $repo, $test, $eprint, $flag ) = @_;

    if( $repo->can_call( "hefce_oa", "run_test_$test" ) )
    {
        return $repo->call( [ "hefce_oa", "run_test_$test" ], $repo, $eprint, $flag );
    }

    return 0;
};

$c->{hefce_oa}->{run_test_COMPLIANT} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $flag & HefceOA::Const::EX_DEP;

    return 1 if
        $flag & HefceOA::Const::EX_ACC &&
        $flag & HefceOA::Const::DEP &&
        $flag & HefceOA::Const::DIS;

    return 1 if $flag & HefceOA::Const::EX_TEC;

    return 1 if $flag & HefceOA::Const::EX_OTH;

    return 1 if
        $flag & HefceOA::Const::DEP &&
        $flag & HefceOA::Const::DIS &&
        $flag & HefceOA::Const::ACC;

    return 0;
};

$c->{hefce_oa}->{run_test_DEP} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::DEP_COMPLIANT &&
        $flag & HefceOA::Const::DEP_TIMING;

    return 0;
};

$c->{hefce_oa}->{run_test_DIS} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $flag & HefceOA::Const::DIS_DISCOVERABLE;

    return 0;
};

$c->{hefce_oa}->{run_test_ACC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::ACC_TIMING &&
        $flag & HefceOA::Const::ACC_EMBARGO;

    return 0;
};

$c->{hefce_oa}->{run_test_EX_DEP} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_dep" );

    return 0;
};

$c->{hefce_oa}->{run_test_EX_ACC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_acc" );

    return 0;
};

$c->{hefce_oa}->{run_test_EX_TEC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_tec" );

    return 0;
};

$c->{hefce_oa}->{run_test_EX_OTH} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_oth" );

    return 0;
};

$c->{hefce_oa}->{run_test_DEP_TIMING} = sub {
	my( $repo, $eprint, $flag ) = @_;

	return 0 unless $eprint->is_set( "hoa_date_fcd" );
	
	my $dep = Time::Piece->strptime( $eprint->value( "hoa_date_fcd" ), "%Y-%m-%d" );
	my $APR17 = Time::Piece->strptime( "2017-04-01", "%Y-%m-%d" );

	# checks based on date of acceptance (if set)
	if( $eprint->is_set( "hoa_date_acc" ) )
	{
		my $acc = Time::Piece->strptime( $eprint->value( "hoa_date_acc" ), "%Y-%m-%d" );
	
		# deposit is within 3  months of acceptance
		return 1 if $dep <= $acc->add_months(3); 

		#for pre-April '17, base calculation on pub date
		if( $acc < $APR17 && $eprint->is_set( "hoa_date_pub" ) )
		{
			my $pub = Time::Piece->strptime( $eprint->value( "hoa_date_pub" ), "%Y-%m-%d" );
			return 1 if $dep <= $pub->add_months(3);
		}
		
	}
	elsif( $eprint->is_set( "hoa_date_pub" ) )
	{
		my $pub = Time::Piece->strptime( $eprint->value( "hoa_date_pub" ), "%Y-%m-%d" );
		
		#if published date is before 2017-04-01, acceptance date must be too.
		# NB we may need to introduce a lag here - if it normally takes a month to get something published,
		# we may need to check for 'APR17 + 1 month'
		if( $pub < $APR17 )
		{
			return 1 if $dep <= $pub->add_months(3);
		}
	}

	return 0;
};

$c->{hefce_oa}->{run_test_DEP_COMPLIANT} = sub {
	my( $repo, $eprint, $flag ) = @_;

	return $eprint->is_set( "hoa_date_fcd" );
};

$c->{hefce_oa}->{run_test_DIS_DISCOVERABLE} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->value( "eprint_status" ) eq "archive";

    return 0;
};

$c->{hefce_oa}->{run_test_ACC_TIMING} = sub {
    my( $repo, $eprint, $flag ) = @_;

	my $len = $eprint->value( "hoa_emb_len" ) || 0;

	if( $len > 0  )
	{
		return 0 unless $eprint->is_set( "hoa_date_pub" ) && $eprint->is_set( "hoa_date_foa" );

		my $pub = Time::Piece->strptime( $eprint->value( "hoa_date_pub" ), "%Y-%m-%d" );
		my $end = $pub->add_months( $len ); # embargo end
		my $foa = Time::Piece->strptime( $eprint->value( "hoa_date_foa" ), "%Y-%m-%d" );

		# oa within one month of embargo end
		return 1 if $foa <= $end->add_months( 1 );
	}
	else # no embargo
	{
		return 0 unless $eprint->is_set( "hoa_date_fcd" ) && $eprint->is_set( "hoa_date_foa" );

		my $fcd = Time::Piece->strptime( $eprint->value( "hoa_date_fcd" ), "%Y-%m-%d" );
		my $foa = Time::Piece->strptime( $eprint->value( "hoa_date_foa" ), "%Y-%m-%d" );

		# oa with one month of deposit
		return 1 if $foa <= $fcd->add_months( 1 );
	}

	return 0;
};

$c->{hefce_oa}->{run_test_ACC_EMBARGO} = sub {
	my( $repo, $eprint, $flag ) = @_;

	my $len = $eprint->value( "hoa_emb_len" ) || 0;
	my $max = ( $eprint->value( "hoa_ref_pan" ) || "CD" ) eq "AB" ? 12 : 24;

	return 1 unless $len > $max;

	return 0;
};

$c->{hefce_oa}->{run_test_EX} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::EX_DEP ||
        $flag & HefceOA::Const::EX_ACC ||
        $flag & HefceOA::Const::EX_TEC ||
        $flag & HefceOA::Const::EX_OTH;

    return 0;
};
