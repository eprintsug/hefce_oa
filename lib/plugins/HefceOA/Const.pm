package HefceOA::Const;

use Exporter;
@ISA = qw( Exporter );

use constant {
    COMPLIANT           => 1,
    DEP                 => 2,
    DEP_TIMING          => 4,
    DEP_AAM             => 8,
    DIS                 => 16,
    DIS_DISCOVERABLE    => 32,
    ACC                 => 64,
    ACC_TIMING          => 128,
    ACC_EMBARGO         => 256,
    EX_DEP              => 512,
    EX_ACC              => 1024,
    EX_TEC              => 2048,
    EX_OTH              => 4096,
};

@EXPORT = qw(
    COMPLIANT
    DEP
    DEP_TIMING
    DEP_AAM
    DIS
    DIS_DISCOVERABLE
    ACC
    ACC_TIMING
    ACC_EMBARGO
    EX_DEP
    EX_ACC
    EX_TEC
    EX_OTH
);

1;
