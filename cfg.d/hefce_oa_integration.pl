use Time::Piece; 

# attempt to set hoa_date_acc and hoa_date_pub from various sources
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
		my $rioxx_pub = $eprint->value( 'rioxx2_publication_date' );
		if( $rioxx_pub =~ /^\d{4}-\d{2}-\d{2}$/ ) #check rioxx override is valid date format
		{
			$pub_date = $eprint->value( 'rioxx2_publication_date' );
		}
	}

	# now set the values - date of acceptance
	my $acc_year = substr $acc_date, 0, 4 if defined $acc_date; #ensure year is post 1900 to prevent Time::Piece crash
	if( defined $acc_date && $acc_year >= 1900 )
	{
		$eprint->set_value( 'hoa_date_acc', $acc_date );
	}
	
	#prefer a published_online date
	if( defined $pub_online_date )
	{	
		my $pub_year = substr $pub_online_date, 0, 4;
		$eprint->set_value( 'hoa_date_pub', $pub_online_date ) if $pub_year >= 1900;
	}
	elsif( defined $pub_date ) #but use a published date if that's not available.
	{
		my $pub_year = substr $pub_date, 0, 4;
		$eprint->set_value( 'hoa_date_pub', $pub_date ) if $pub_year >= 1900;
	}
}, priority => 100 ); # needs to be called before the compliance flag is set

# attempt to set hoa_emb_len
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_; 
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	# trigger only applies to repos with hefce_oa plugin enabled
	return unless $eprint->dataset->has_field( 'hoa_compliant' );
 	
        my $doc = $repo->call( [qw( hefce_oa select_document )], $repo, $eprint );
	my $hoa_pub = $eprint->value( 'hoa_date_pub' );
        if( $doc && $hoa_pub && !$eprint->is_set( "hoa_date_foa" ) )
        {
		if( $doc->exists_and_set( 'date_embargo' ) )
                {
			my $pub_time;
			if( $repo->can_call( "hefce_oa", "handle_possibly_incomplete_date" ) )
			{
				$pub_time = $repo->call( [ "hefce_oa", "handle_possibly_incomplete_date" ], $hoa_pub );
			}
			if( !defined( $pub_time ) ) #above call can return undef - fallback to default
			{
				$pub_time = Time::Piece->strptime( $hoa_pub , "%Y-%m-%d" );
			}

			my $emb_time;
			if( $repo->can_call( "hefce_oa", "handle_possibly_incomplete_date" ) )
			{
				$emb_time = $repo->call( [ "hefce_oa", "handle_possibly_incomplete_date" ], $doc->value( 'date_embargo' ) );
			}
			if( !defined( $emb_time ) ) #above call can return undef - fallback to default
			{
				my $emb_date = $doc->value( 'date_embargo' );
				if( $emb_date =~ /^(\d{4})/ )
				{
					$emb_time = Time::Piece->strptime( $emb_date, "%Y-%m-%d" ) if $1 >= 1900;
				}
			}
                        if( $emb_time > $pub_time ) #embargo date must come after publication date
                        {
                                #get embargo length
                                my $len = $emb_time-$pub_time;
                                $eprint->set_value( 'hoa_emb_len', sprintf "%.0f", $len->months );
                        }
                }
                else
                {
                        $eprint->set_value( 'hoa_emb_len', undef );
                }

	}
}, priority => 250 ); 


#adapted from RIOXX2 plugin
$c->{hefce_oa}->{select_document} = sub {
        my( $repo, $eprint ) = @_;

        my @docs = $eprint->get_all_documents;

        # no docs?
        return unless scalar @docs;

	# @possible_docs meet 'content' selection criteria - by default accepted or published, but can now be 
	# overridden in config. See triggers file.
	my $good_content = $repo->config( "hefce_oa", "document_content" ) || [ qw/ accepted published / ];
	my @possible_docs = grep {
		my $doc = $_;
		$doc->is_set( "content" ) && 
			grep {
				my $content = $doc->value( "content" );
				/^$content$/; 
			} @$good_content;
	} @docs;

	return unless scalar @possible_docs;

	# if there's only one possible doc, it's the best (by default)
	return $possible_docs[0] if scalar @possible_docs == 1;

        # prefer published over accepted when other tests are equal
        my %pref = (
                published => 1,
                accepted => 2,               
        );
	# the final 'spaceship sort'  below will prefer an undef value over a set one - which might 
	# not be expected (I realise this will be a very niche case)
	foreach( @$good_content ){
		next if defined $pref{$_};
		$pref{$_} = 10; # less preferred than standard options
	}

	# this sort statement might be slow when dealing with lots of documents.
	# we've already pared the array down to only accepted/published versions.
	# If necessary, some of the methods for pre-calculation on http://www.sysarch.com/Perl/sort_paper.html
	# may be useful
        @possible_docs = sort {
		#pre-calculate embargo dates
		my( $ade, $bde );
		$ade = $bde = localtime; #same date if both embargoes are undefined.

		if( $repo->can_call( "hefce_oa", "handle_possibly_incomplete_date" ) ){
			$ade = $repo->call( [ "hefce_oa", "handle_possibly_incomplete_date" ], $a->value( 'date_embargo' ) ) if $a->is_set( 'date_embargo'); 
			$bde = $repo->call( [ "hefce_oa", "handle_possibly_incomplete_date" ], $b->value( 'date_embargo' ) ) if $b->is_set( 'date_embargo'); 
		}


			# public is best. NB Can't use $doc->is_public here, is it checks EPrint is in 'archive' too.
		($b->is_set( "security" ) && $b->value( "security" ) eq "public" ) 
			<=> ($a->is_set( "security" ) && $a->value( "security" ) eq "public" ) or
			# something not public, but with an embargo set is better than a permanently embargoed item
			# again, with $a and $b swapped as is_set returns 1 or 0.
		$b->is_set( "date_embargo" ) <=> $a->is_set( "date_embargo" )  or
			# The embargo date will both be set, or both be undef here.
			# If both are undef, $ade and $bde will be equal 
			# What has the shortest embargo?
		$ade <=> $bde or
                $pref{$a->value( "content" )} <=> $pref{$b->value( "content" )} 
		
        } @possible_docs;

	return $possible_docs[0];
};

$c->{hefce_oa}->{handle_possibly_incomplete_date} = sub {
	# returns a Time::Piece object or undef.
	#
	# $epdate is value from EPrints DataObj field. 
	# setting $default_to_start_of_period = 1 will return the 1st of the month/year for incomplete dates rather than the end.
	my( $epdate, $default_to_start_of_period ) = @_;
	return undef if !defined $epdate;

	$default_to_start_of_period ||= 0;
	# complete date - return Time::Piece object
	if( $epdate =~ /^0*(\d{2}|\d{4})\-(\d{2})\-(\d{2})/ )
        {
                if( length($1) == 2)
                {
                        return Time::Piece->strptime( "$1-$2-$3", "%y-%m-%d" );
                }
                elsif( length($1) == 4 && $1 >= 1900 )
                {
                        return Time::Piece->strptime( "$1-$2-$3", "%Y-%m-%d" );
                }
        }

	if( $epdate =~ /^(\d{4})\-\d{2}$/ )
	{
		if( $1 >= 1900 )
		{
			my $tp = Time::Piece->strptime( $epdate, "%Y-%m" ); #defaults to start of month
			return $tp if $default_to_start_of_period;

			# looks like there's no way to $tp->set_day( $tp->month_last-day ). 
			# I think this is the least-silly option.!?
			return Time::Piece->strptime( "$epdate-".$tp->month_last_day, "%Y-%m-%d" );
		}
	}
	# only year supplied - default to start or end of year as flagged
	return Time::Piece->strptime( "$epdate-01-01", "%Y-%m-%d" ) if $epdate =~ /^\d{4}$/ && $default_to_start_of_period && $epdate >= 1900;
	return Time::Piece->strptime( "$epdate-12-31", "%Y-%m-%d" ) if $epdate =~ /^\d{4}$/ && $epdate >= 1900;
	return undef;

};

$c->{hefce_oa}->{calculate_last_compliant_foa_date} = sub {
    my( $repo, $eprint ) = @_;

    my $len = $eprint->value( "hoa_emb_len" ) || 0;

    # $len will be tested to see whether it is a compliant number of months in ACC_EMBARGO
    if( $len > 0  )
    {
        #need pub date to calculate embargo release date
        return undef unless $eprint->is_set( "hoa_date_pub" );

        my $pub = $repo->call(["hefce_oa", "handle_possibly_incomplete_date"], $eprint->value( "hoa_date_pub" ), "Y-%m-%d" );
        my $end = $pub->add_months( $len ); # embargo end
        $end = $end->add_months( 1 ); #1-month grace period
        return $end;
    }
    else # no embargo
    {
        return undef unless $eprint->is_set( "hoa_date_fcd" );

        my $fcd = Time::Piece->strptime( $eprint->value( "hoa_date_fcd" ), "%Y-%m-%d" );

        # oa with one month of deposit
        my $end = $fcd->add_months( 1 );
        return $end;
    }

    #returns if no last foa date can be calculated
};
