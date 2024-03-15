package EPrints::Plugin::Export::Report::CSV::REF_CC;
use HefceOA::Const;

use EPrints::Plugin::Export::Report::CSV;
our @ISA = ( "EPrints::Plugin::Export::Report::CSV" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "CSV";
	$self->{accept} = [ 'report/ref_cc-*', ];
	$self->{advertise} = 1;
	return $self;
}

sub output_list
{
        my( $plugin, %opts ) = @_;

	
	my @fields = ();
	push @fields, $plugin->{repository}->dataset( "eprint" )->field( "eprintid" );
	push @fields, grep { $_->type =~ /^RIOXX2$/ } $plugin->{repository}->dataset( "eprint" )->get_fields;
	$plugin->{ref_cc_fields} = [ map { $_->name } @fields ];

	push @fields, $plugin->{repository}->dataset( "eprint" )->field( "hoa_compliant" );

	
	print join( ",", map { $plugin->escape_value( EPrints::Utils::tree_to_utf8( $_->render_name ) ) } @fields );
	print "\n";
       
	$opts{list}->map( sub {
		my( undef, undef, $dataobj ) = @_;
		my $output = $plugin->output_dataobj( $dataobj );
		return unless( defined $output );
		print "$output\n";
	} );
}

sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;
	my @row;
	for( @{ $plugin->{ref_cc_fields} } )
	{		
		push @row, $plugin->escape_value( EPrints::Utils::tree_to_utf8( $dataobj->render_value( $_ ) ) );
	}

	my $repo = $plugin->{repository};
	my $flag = $dataobj->value( "hoa_compliant" );

	#print compliance
	my $compliance = "N";
#        if( $dataobj->value( "hoa_compliant" ) >= 511 )
        if ( $flag & HefceOA::Const::COMPLIANT )
        {
                $compliance = "Y";
        }elsif( $flag & HefceOA::Const::DEP &&
				$flag & HefceOA::Const::DIS &&
				$flag & HefceOA::Const::ACC_EMBARGO &&
				$repo->call( ["hefce_oa", "could_become_ACC_TIMING_compliant"], $repo, $dataobj ) ){
	    #handle future compliance with an "F"
		$compliance = "F";             
    	}
	push @row, $compliance;

	return join( ",", @row );
}

1;
