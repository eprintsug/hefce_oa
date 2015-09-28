$c->{plugins}{"Screen::EPrint::HefceOA"}{params}{disable} = 0;

push @{ $c->{user_roles}->{editor} }, qw{ +eprint/hefce_oa };
push @{ $c->{user_roles}->{admin} }, qw{ +eprint/hefce_oa };
