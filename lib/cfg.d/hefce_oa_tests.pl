my $hoa = $c->{hefce_oa};

use Date::Parse;
use HefceOA::Const;

$hoa->{run_test} = sub {
    my( $repo, $test, $eprint, $flag ) = @_;

    if( $repo->can_call( "hefce_oa", "run_test_$test" ) )
    {
        return $repo->call( [ "hefce_oa", "run_test_$test" ], $repo, $eprint, $flag );
    }

    return 0;
};

$hoa->{run_test_COMPLIANT} = sub {
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

$hoa->{run_test_DEP} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::DEP_TIMING &&
        $flag & HefceOA::Const::DEP_AAM;

    return 0;
};

$hoa->{run_test_DIS} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $flag & HefceOA::Const::DIS_DISCOVERABLE;

    return 0;
};

$hoa->{run_test_ACC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::ACC_TIMING &&
        $flag & HefceOA::Const::ACC_EMBARGO;

    return 0;
};

$hoa->{run_test_EX_DEP} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_dep" );

    return 0;
};

$hoa->{run_test_EX_ACC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_acc" );

    return 0;
};

$hoa->{run_test_EX_TEC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_tec" );

    return 0;
};

$hoa->{run_test_EX_OTH} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_oth" );

    return 0;
};

$hoa->{run_test_DEP_TIMING} = sub {
	my( $repo, $eprint, $flag ) = @_;

	# can't do anything without an acceptance date
	return 0 unless $eprint->is_set( "hoa_date_acc" );
	
	# TODO check YYYY-MM-DD
	my $acc = str2time( $eprint->get_value( "hoa_date_acc" ) );

	my $APR17 = str2time( "2017-04-01" );
	my $WINDOW = 3 * 30 * 24 * 60 * 60; # 3 months

	if( $eprint->is_set( "hoa_date_fcd" ) )
	{
		# TODO check YYYY-MM-DD
		my $dep = str2time( $eprint->get_value( "hoa_date_fcd" ) );
		# deposited after accepted: $dep > $acc, check difference is <= $WINDOW
		# deposited before accepted: $dep < $acc, difference will be < 0 
		return 1 if ( $dep - $acc ) <= $WINDOW;

		if( $acc < $APR17 && $eprint->is_set( "hoa_date_pub" ) )
		{
			# TODO check YYYY-MM-DD
			my $pub = str2time( $eprint->get_value( "hoa_date_pub" ) );
			# deposited after published: $dep > $pub, check differene is <= $WINDOW
			# deposited before published: $dep < $pub, difference will be < 0
			return 1 if ( $dep - $pub ) <= $WINDOW;
		}
	}

	return 0;
};

$hoa->{run_test_DEP_AAM} = sub {
	my( $repo, $eprint, $flag ) = @_;

	return $eprint->is_set( "hoa_date_fcd" );
};

$hoa->{run_test_DIS_DISCOVERABLE} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->value( "eprint_status" ) eq "archive";

    return 0;
};

$hoa->{run_test_ACC_TIMING} = sub {
    my( $repo, $eprint, $flag ) = @_;

    # TODO
    return 1;

    return 0;
};

$hoa->{run_test_ACC_EMBARGO} = sub {
	my( $repo, $eprint, $flag ) = @_;

	my $len = $eprint->value( "hoa_emb_len" ) || 0;
	my $max = ( $eprint->value( "hoa_ref_pan" ) || "CD" ) eq "AB" ? 12 : 24;

	return 1 unless $len > $max;

	return 0;
};

$hoa->{run_test_EX} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::EX_DEP ||
        $flag & HefceOA::Const::EX_ACC ||
        $flag & HefceOA::Const::EX_TEC ||
        $flag & HefceOA::Const::EX_OTH;

    return 0;
};
