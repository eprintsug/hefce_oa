package EPrints::Plugin::Screen::Report::REF_CC::Pre2026;

use EPrints::Plugin::Screen::Report::REF_CC;
our @ISA = ( 'EPrints::Plugin::Screen::Report::REF_CC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'ref_cc-pre-2026';

	return $self;
}

sub filters
{
	my( $self ) = @_;

	my @filters = @{ $self->SUPER::filters || [] };

    # for outputs published between 1 January 2021 and 31 December 2025
	push @filters, { meta_fields => [ "hoa_date_pub" ], value => '2021-01-01-2025-12-31', match => "IN" };

	return \@filters;
}

1;
