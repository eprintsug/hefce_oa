package EPrints::Plugin::Screen::Report::REF_CC::2022;

use EPrints::Plugin::Screen::Report::REF_CC;
our @ISA = ( 'EPrints::Plugin::Screen::Report::REF_CC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'ref_cc-2022';

	return $self;
}

sub filters
{
	my( $self ) = @_;

	my @filters = @{ $self->SUPER::filters || [] };

	push @filters, { meta_fields => [ "hoa_date_acc" ], value => '2022-04-2023-03', match => "IN" };

	return \@filters;
}

1;
