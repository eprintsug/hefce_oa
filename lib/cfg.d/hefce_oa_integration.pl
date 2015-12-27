# attempt to set hoa_date_acc and hoa_date_pub from various sources
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $eprint->dataset->has_field( 'hoa_compliant' );

    # default
    if( $eprint->is_set( 'date' ) )
    {
        if( $eprint->is_set( 'date_type' ) && $eprint->value( 'date_type' ) eq 'published' )
        {
            $eprint->set_value( 'hoa_date_pub', $eprint->value( 'date' ) );
        }
    }

    # datesdatesdates
    if( $eprint->exists_and_set( 'dates' ) )
    {
        $dates = $eprint->value( 'dates' );
        if( ref($dates) eq 'ARRAY' ) # check for expected structure
        {
            for(@$dates)
            {
                next unless ref($_) eq 'HASH';
                next unless EPrints::Utils::is_set( $_->{date} ) && EPrints::Utils::is_set( defined $_->{date_type} );
                if( $_->{date_type} eq 'published' )
                {
                    $eprint->set_value( 'hoa_date_pub', $_->{date} );
                }
                if( $_->{date_type} eq 'accepted' )
                {
                    $eprint->set_value( 'hoa_date_acc', $_->{date} );
                }
            }
        }
    }

    # rioxx2
    if( $eprint->exists_and_set( 'rioxx2_dateAccepted' ) )
    {
        $eprint->set_value( 'hoa_date_acc', $eprint->value( 'rioxx2_dateAccepted' ) );
    }
    if( $eprint->exists_and_set( 'rioxx2_publication_date' ) )
    {
        $eprint->set_value( 'hoa_date_pub', $eprint->value( 'rioxx2_publication_date' ) );
    }

}, priority => 100 ); # needs to be called before the compliance flag is set
