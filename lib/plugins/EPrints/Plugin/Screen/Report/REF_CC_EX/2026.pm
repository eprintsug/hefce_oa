package EPrints::Plugin::Screen::Report::REF_CC_EX::2026;

use EPrints::Plugin::Screen::Report::REF_CC_EX;
our @ISA = ( 'EPrints::Plugin::Screen::Report::REF_CC_EX' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'ref_cc-ex-2026';

	return $self;
}

sub filters
{
	my( $self ) = @_;

	my @filters = @{ $self->SUPER::filters || [] };

	push @filters, { meta_fields => [ "hoa_date_acc" ], value => '2026-04-2027-03', match => "IN" };

	return \@filters;
}

1;
