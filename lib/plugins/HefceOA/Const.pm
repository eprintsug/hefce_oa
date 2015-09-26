package EPrints::Plugin::HefceOA::Const.pm;

use Exporter;
@ISA = qw( Exporter );

use constant {
    COMPLIANT           = 1
    DEP                 = 2
    DEP_TIMING          = 4
    DEP_AAM             = 8
    DIS                 = 16
    DIS_DISCOVERABLE    = 32
    ACC                 = 64
    ACC_TIMING          = 128
    ACC_EMBARGO         = 256
    EX_DEP              = 512
    EX_ACC              = 1024
    EX_TEC              = 2048
    EX_OTH              = 4096
};
