package EPrints::Plugin::Screen::Report::REF_CC_EX;

use EPrints::Plugin::Screen::Report::REF_CC;
our @ISA = ( 'EPrints::Plugin::Screen::Report::REF_CC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'ref_cc-ex';

	return $self;
}

sub validate_dataobj
{
	my( $self, $eprint ) = @_;

	my $repo = $self->{repository};

	my @problems;

	#show wholly non-compliant records as not being compliant still
	my $flag = $eprint->value( "hoa_compliant" );
        if( !( $flag & HefceOA::Const::COMPLIANT ) )
        {
                push @problems, $repo->phrase( "Plugin/Screen/EPrint/HefceOA:non_compliant" );
        }

	for( qw( hoa_ex_dep hoa_ex_acc hoa_ex_tec hoa_ex_oth ) )
	{
		if( $eprint->is_set( $_ ) )
		{
			push @problems, EPrints::XML::to_string(
				$repo->html_phrase( "Plugin/Screen/EPrint/HefceOA:render_exception", 
					title => $repo->html_phrase( "eprint_fieldname_$_" ),
					exception => $eprint->render_value( $_ ),
					explanation => $eprint->render_value( "$_\_txt" ),
				)
			);
		}
	}
	
	return @problems;
}

1;
