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


push @{ $c->{user_roles}->{editor} }, qw{ +eprint/hefce_oa };
push @{ $c->{user_roles}->{admin} }, qw{ +eprint/hefce_oa };
push @{ $c->{user_roles}->{admin} }, qw{ +report/hefce_oa };
