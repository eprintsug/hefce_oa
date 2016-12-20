# If your repository has additional fields that can be used to work out if something should be considered
# as in-scope or out-of-scope, you can override the default $c->{hefce_oa}->{in_scope} function
# (defined in ~/lib/cfg.d/hefce_oa-triggers.pl) by adding it to a file e.g.
# ~/archives/ARCHIVEID/cfg/cfg.d/zz_hefce_oa_local.pl


# Enable screens / reports
$c->{plugins}{"Screen::EPrint::HefceOA"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::REF_CC"}{params}{disable} = 0;
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

# Admin roles
push @{ $c->{user_roles}->{admin} }, qw{ +eprint/hefce_oa };
push @{ $c->{user_roles}->{admin} }, qw{ +report/hefce_oa };

# Editor roles.
# By default they can't see the reports. Uncomment the last line to allow access.
push @{ $c->{user_roles}->{editor} }, qw{ +eprint/hefce_oa };
# push @{ $c->{user_roles}->{editor} }, qw{ +report/hefce_oa };
