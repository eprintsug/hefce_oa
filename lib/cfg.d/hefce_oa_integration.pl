# attempt to set hoa_date_acc and hoa_date_pub from various sources as well as hoa_emb_len
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $eprint->dataset->has_field( 'hoa_compliant' );

	my( $acc_date, $pub_date, $pub_online_date );
		
	# default EPrints date field - only one of these will match
	if( $eprint->is_set( 'date' ) && $eprint->is_set( 'date_type' ) )
	{
		if( $eprint->value( 'date_type' ) eq 'published' )
		{
			$pub_date = $eprint->value( 'date' );
		}
		elsif( $eprint->value( 'date_type' ) eq 'published_online' )
		{
			$pub_online_date = $eprint->value( 'date' );
		}
		elsif( $eprint->value( 'date_type' ) eq 'accepted' ) {
			$acc_date = $eprint->value( 'date' );
		}
	}

	# datesdatesdates - v.1.0.5 with 'published_online' option
	if( $eprint->exists_and_set( 'dates' ) )
	{
		my $dates = $eprint->value( 'dates' );
		if( ref($dates) eq 'ARRAY' ) # check for expected structure
		{
			for(@$dates)
			{
				next unless ref($_) eq 'HASH';
				next unless EPrints::Utils::is_set( $_->{date} ) && EPrints::Utils::is_set( defined $_->{date_type} );
				if( $_->{date_type} eq 'published' )
				{
					$pub_date = $_->{date};
				}
				elsif( $_->{date_type} eq 'published_online' )
				{
					$pub_online_date = $_->{date};
				}
				elsif( $_->{date_type} eq 'accepted' )
				{
					$acc_date = $_->{date};
				}
			}
		}
	}

	# rioxx2 - will prefer 'published' to 'published_online' - REF_CC prefers it the other way round
	if( $eprint->exists_and_set( 'rioxx2_dateAccepted' ) )
	{
		$acc_date = $eprint->value( 'rioxx2_dateAccepted' );
	}
	if( $eprint->exists_and_set( 'rioxx2_publication_date' ) )
	{
		$pub_date = $eprint->value( 'rioxx2_publication_date' );
	}

	#initialise pub_time for later use when calculating hoa_emb_len
	my $pub_time;

	# now set the values - date of acceptance
	$eprint->set_value( 'hoa_date_acc', $acc_date ) if defined $acc_date;
	#prefer a published_online date
	if( defined $pub_online_date )
	{
		$eprint->set_value( 'hoa_date_pub', $pub_online_date );
		$pub_time = Time::Piece->strptime( $pub_online_date, "%Y-%m-%d" );
	}
	elsif( defined $pub_date ) #but use a published date if that's not available.
	{
		$eprint->set_value( 'hoa_date_pub', $pub_date );
		$pub_time = Time::Piece->strptime( $pub_date, "%Y-%m-%d" );
	}

	#now try and set hoa_emb_len
	my $doc = $repo->call( [qw( hefce_oa select_document )], $eprint );
	if( $doc && $doc->exists_and_set( 'date_embargo' ) && $pub_time )
	{
		#get embargo date
		my $emb_time = Time::Piece->strptime( $doc->value( 'date_embargo' ), "%Y-%m-%d" );
		if( $emb_time > $pub_time ) #embargo date must come after publication date
		{
			#get embargo length
			my $len = $emb_time-$pub_time;
			$eprint->set_value( 'hoa_emb_len', int($len->months) );
		}
	}
}, priority => 100 ); # needs to be called before the compliance flag is set

#copied from RIOXX2 plugin
$c->{hefce_oa}->{select_document} = sub {
        my( $eprint ) = @_;

        my @docs = $eprint->get_all_documents;

        # simple cases
        return unless scalar @docs;
        return $docs[0] if scalar @docs == 1;

        # prefer published, accepted and submitted versions over anything else
        my %pref = (
                published => 3,
                accepted => 2,
                submitted => 1,
        );

        my @ordered = sort {
                ($pref{$b->value( "content" )||""}||0) <=> ($pref{$a->value( "content" )||""}||0)
        } @docs;

        return $ordered[0] if $ordered[0]->is_set( "content" );

        # prefer text documents
        for( @docs )
        {
                return $_ if $_->value( "format" ) eq "text";
        }

        return $docs[0];
};

