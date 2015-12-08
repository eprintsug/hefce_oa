package EPrints::Plugin::Screen::Report::REF_CC::EX_2015;

use EPrints::Plugin::Screen::Report::REF_CC;
our @ISA = ( 'EPrints::Plugin::Screen::Report::REF_CC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'ref_cc-ex-2015';

	return $self;
}

sub filters
{
	my( $self ) = @_;

	my @filters = @{ $self->SUPER::filters || [] };

	push @filters, { meta_fields => [ "hoa_date_acc" ], value => '2015-', match => "IN" };

	return \@filters;
}

sub validate_dataobj
{
	my( $self, $eprint ) = @_;

	my $repo = $self->{repository};

	my @problems;

	for( qw( hoa_ex_dep hoa_ex_acc hoa_ex_tec hoa_ex_oth ) )
	{
		if( $eprint->is_set( $_ ) )
		{
			push @problems, $repo->phrase( "Plugin/Screen/EPrint/HefceOA:render_exception", 
				title => "<b>" . $repo->phrase( "eprint_fieldname_$_" ) . "</b>",
				exception => EPrints::Utils::tree_to_utf8( $eprint->render_value( $_ ) ),
				explanation => EPrints::Utils::tree_to_utf8( $eprint->render_value( "$_\_txt" ) ),
			);
		}
	}
	
	return @problems;
}

1;
