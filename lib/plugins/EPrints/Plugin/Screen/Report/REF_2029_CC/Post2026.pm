package EPrints::Plugin::Screen::Report::REF_2029_CC::Post2026;

use EPrints::Plugin::Screen::Report::REF_2029_CC;
our @ISA = ( 'EPrints::Plugin::Screen::Report::REF_2029_CC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'ref_2029_cc-post-2026';

	return $self;
}

sub filters
{
	my( $self ) = @_;

	my @filters = @{ $self->SUPER::filters || [] };

    # for outputs published between 1 January 2026 and 31 December 2028
	push @filters, { meta_fields => [ "hoa_date_pub" ], value => '2026-01-01-2028-12-31', match => "IN" };

	return \@filters;
}

1;
