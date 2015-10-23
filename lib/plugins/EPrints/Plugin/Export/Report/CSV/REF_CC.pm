package EPrints::Plugin::Export::Report::CSV::REF_CC;

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

	my @fields = grep { $_->type =~ /^RIOXX2$/ } $plugin->{repository}->dataset( "eprint" )->get_fields;
	$plugin->{ref_cc_fields} = [ map { $_->name } @fields ];

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
	return join( ",", @row );
}

1;
