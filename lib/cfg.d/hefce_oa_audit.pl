
$c->{hefce_oa}->{get_unpaywall} = sub {

    my ($repo, $eprint) = @_;

    use LWP::Simple;
    use LWP::UserAgent;
    use URI;



    #start with an assumption
    my $doi_field = "id_number";
    if(EPrints::Utils::is_set($repo->get_conf("hefce_oa","eprintdoifield"))){
        #a) have we defined the doi_field within the hefce_oa conf?
        $doi_field = $repo->get_conf("hefce_oa","eprintdoifield");
    }elsif(EPrints::Utils::is_set($repo->get_conf("datacitedoi","eprintdoifield"))){
        #b) have we already defined the doi_field within the dataitedoi plugin?
        $doi_field = $repo->get_conf("datacitedoi","eprintdoifield");
    }

    return("ERROR", "There is no DOI ($doi_field) set ") if (!$eprint->exists_and_set($doi_field));

    my $doi = $eprint->value($doi_field);

    if($doi = $repo->call(["hefce_oa", "format_doi"], $doi)){

        my $up_email = $repo->get_conf("hefce_oa", "unpaywall_email") || $repo->get_conf("adminemail");
        
        my $api_request_uri = URI->new($repo->get_conf("hefce_oa","unpaywall_api_base")."$doi?email=".$up_email);

        my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
        my @headers = (
            'Accept' => 'application/json',
    #		'Authorization' => 'Bearer' . $user->value( "orcid_access_token" ),
        );
        print $api_request_uri."\n";
        my $response = $ua->get( $api_request_uri, @headers );
        return("SUCCESS", $response);

    }else{
        return("ERROR", "No suitable DOI set in $doi_field (".$eprint->value($doi_field).")");
    }
};

$c->{hefce_oa}->{get_core} = sub {

    my ($repo, $eprint) = @_;

    use LWP::Simple;
    use LWP::UserAgent;
    use URI;


    #start with an assumption
    my $doi_field = "id_number";
    if(EPrints::Utils::is_set($repo->get_conf("hefce_oa","eprintdoifield"))){
        #a) have we defined the doi_field within the hefce_oa conf?
        $doi_field = $repo->get_conf("hefce_oa","eprintdoifield");
    }elsif(EPrints::Utils::is_set($repo->get_conf("datacitedoi","eprintdoifield"))){
        #b) have we already defined the doi_field within the dataitedoi plugin?
        $doi_field = $repo->get_conf("datacitedoi","eprintdoifield");
    }

    return("ERROR", "There is no DOI ($doi_field) set ") if (!$eprint->exists_and_set($doi_field));

    my $doi = $eprint->value($doi_field);

    if($doi = $repo->call(["hefce_oa", "format_doi"], $doi)){
        
        # core requires that the doi is not encoded but that it 
        # is wrapped in double quotes that are encoded and 
        # proceeded by a colon that is also encoded... go figure!
        my $api_request_uri = URI->new($repo->get_conf("hefce_oa","core_api_base")."/search/doi%3A%22".$doi."%22?page=1&pageSize=100&apiKey=".$repo->get_conf("hefce_oa","core_api_key"));

        my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
        my @headers = (
            'Accept' => 'application/json',
    #		'Authorization' => 'Bearer' . $user->value( "orcid_access_token" ),
        );

        my $response = $ua->get( $api_request_uri, @headers );
        return("SUCCESS", $response);

    }else{
        return("ERROR", "No suitable DOI set in $doi_field (".$eprint->value($doi_field).")");
    }
};

# lifted straight from UKETD plugin, which is based on render_possible_doi
# if only a a non-redering version of this was in the core... :/
$c->{hefce_oa}->{format_doi} = sub {

    my( $doi ) = @_;

    # advice received is that just DOI is preferred to a URL
    # logic taken from EPrints::Extras::render_possible_doi
    if( $doi =~ m!^
         (?:https?://(?:dx\.)?doi\.org/)?  # add this again later anyway
         (?:doi:?\s*)?                   # don't need any namespace stuff
         (10(\.[^./]+)+/.+)              # the actual DOI => $1
     !ix )
     {
         # just use the last part - the actual DOI.
         return $1;
     }
     return 0;
};


