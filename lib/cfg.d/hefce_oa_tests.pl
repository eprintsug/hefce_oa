my $hoa = $c->{hefce_oa};

use HefceOA::Const;

$hoa->{render_test_title} = sub {
    my( $repo, $test ) = @_;

    return $repo->html_phrase( "hefce_oa:test_title:$test" );
};

$hoa->{render_test_details} = sub {
    my( $repo, $test, $eprint ) = @_;

    if( $repo->can_call( qw( hefce_oa render_test_details ), $test ) )
    {
        return $repo->call( [qw( hefce_oa render_test_details $test )], $repo, $eprint );
    }

    return $repo->html_phrase( "hefce_oa:test_details:$test" );
};

$hoa->{render_test_policy} = sub {
    my( $repo, $test ) = @_;

    return $repo->html_phrase( "hefce_oa:test_policy:$test" );
};

$hoa->{run_test}{COMPLIANT} = sub {
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

$hoa->{run_test}{DEP} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::DEP_TIMING &&
        $flag & HefceOA::Const::DEP_AAM;

    return 0;
};

$hoa->{run_test}{DIS} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $flag & HefceOA::Const::DIS_DISCOVERABLE;

    return 0;
};

$hoa->{run_test}{ACC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if
        $flag & HefceOA::Const::ACC_TIMING &&
        $flag & HefceOA::Const::ACC_EMBARGO;

    return 0;
};

$hoa->{run_test}{EX_DEP} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_dep" );

    return 0;
};

$hoa->{run_test}{EX_ACC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_acc" );

    return 0;
};

$hoa->{run_test}{EX_TEC} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_tec" );

    return 0;
};

$hoa->{run_test}{EX_OTH} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->is_set( "hoa_ex_oth" );

    return 0;
};

$hoa->{run_test}{DEP_TIMING} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

    return 0;
};

$hoa->{run_test}{DEP_AAM} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

    return 0;
};

$hoa->{run_test}{DIS_DISCOVERABLE} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1 if $eprint->value( "eprint_status" ) eq "archive";

    return 0;
};

$hoa->{run_test}{ACC_TIMING} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

    return 0;
};

$hoa->{run_test}{ACC_EMBARGO} = sub {
    my( $repo, $eprint, $flag ) = @_;

    return 1;

    return 0;
};
