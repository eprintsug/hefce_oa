# To automatically use panels based on divisions, set the following hash to
# your academic structure. You only need to define the nodes that are different
# to their parents. If everything in Faculty X is an 'AB', you can just set the
# faculty to 'AB'. If e.g. one department within an 'AB' faculty is 'CD', define
# that.
#
# The panel test defaults to a 'CD' panel. If you set the top-level divisions to
# 'AB', this will be the default where other divisions are not defined.
#
# EPrint fieldname to deduce the panels from
$c->{hefce_oa}->{panel_deduction_field} = 'divisions';
#
# mapping from the above fieldname to panels
$c->{hefce_oa}->{panel_deduction_map} = {
	#'divisions' => 'AB', # e.g. anything under 'divisions' should be 'AB'
	'fac_eng' => 'AB',
	'sch_geo' => 'CD', # e.g. an outlier in the above faculty
	'fac_law' => 'CD',
	'fac_med' => 'AB',
	'sch_psy' => 'CD',
};


$c->{hefce_oa}->{deduce_panel} = sub
{
	my( $eprint ) = @_;

	my $debug = 0;
	print STDERR "Deducing panels\n" if $debug;

	my $repo = $eprint->repository;
	my $field = $repo->get_conf( 'hefce_oa', 'panel_deduction_field' );
	return unless defined $field && $eprint->exists_and_set( $field );

	my $panel_map = $repo->get_conf( 'hefce_oa', 'panel_deduction_map' );
	return unless defined $panel_map;

	my %panels;

	foreach my $subj ( @{$eprint->get_value( $field )} )
	{
		# check if we are defined in the panels map
		if( defined $panel_map->{$subj} )
		{
			$panels{$subj} = $panel_map->{$subj};
			next;
		}

		my $subject = EPrints::DataObj::Subject->new( $repo, $subj );

		if( defined $subject )
		{
			# step through ancestors to see if any are defined
			foreach ( $subject->_get_ancestors )
			{
				# stop once we find something
				if( defined $panel_map->{$_} )
				{
					$panels{$_} = $panel_map->{$_};
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

