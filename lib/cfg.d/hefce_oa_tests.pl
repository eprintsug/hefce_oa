my $hoa = $c->{hefce_oa};

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

    return 1;

    return 0;
};

$hoa->{run_test_DEP_AAM} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

    return 0;
};

$hoa->{run_test_DIS_DISCOVERABLE} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->value( "eprint_status" ) eq "archive";

    return 0;
};

$hoa->{run_test_ACC_TIMING} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

    return 0;
};

$hoa->{run_test_ACC_EMBARGO} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

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
