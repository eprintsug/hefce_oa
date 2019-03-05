# To automatically use panels based on divisions, set the following hash to
# your academic structure. You only need to define the nodes that are different
# to their parents. If everything in Faculty X is an 'AB', you can just set the
# faculty to 'AB'. If e.g. one department within an 'AB' faculty is 'CD', define
# that.
#
# The panel test defaults to a 'CD' panel. If you set the top-level divisions to
# 'AB', this will be the default where other divisions are not defined.

my %divisions_panels = (
	#'divisions' => 'AB', # by default anything under 'divisions'
	'fac_eng' => 'AB',
	'sch_geo' => 'CD', # an outlier
	'fac_law' => 'CD',
	'fac_med' => 'AB',
	'sch_psy' => 'CD',
);

$c->{hefce_oa}->{divisions_panels} = \%divisions_panels;

$c->{hefce_oa}->{deduce_panel} = sub {
	my( $eprint ) = @_;

	my $debug = 0;

	print STDERR "Deducing panels\n" if $debug;

	my $repo = $eprint->repository;
	my $div_panels = $repo->get_conf( 'hefce_oa', 'divisions_panels' );

	my %panels;

	foreach my $subj ( @{$eprint->get_value( 'divisions' )} )
	{
# check if we are defined in the panels hash
		if( defined $div_panels->{$subj} ){
			$panels{$subj} = $div_panels->{$subj};
			next;
		}

		my $subject = EPrints::DataObj::Subject->new( $repo, $subj );

		if( defined $subject ){
# step through ancestors to see if any are defined
			foreach ( $subject->_get_ancestors ){
# stop once we find something
				if( defined $div_panels->{$_} ){
					$panels{$_} = $div_panels->{$_};
					last;
				}
			}
		}

	}
	use Data::Dumper;
	print STDERR "Panels: ", Dumper( %panels ) if $debug;

# return shortest panel if it exsits
	return "AB" if ( grep{ $panels{$_} eq "AB" } keys %panels );
	return "CD" if ( grep{ $panels{$_} eq "CD" } keys %panels );

#definite return otherwise we return the value of the last grep (which would be 0).
# an 'undef' value returned here indicates no deduction has taken place.
	return;
}

