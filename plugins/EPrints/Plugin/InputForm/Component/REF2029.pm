=head1 NAME

EPrints::Plugin::InputForm::Component::REF2029

=cut

package EPrints::Plugin::InputForm::Component::REF2029;

use EPrints::Plugin::InputForm::Component;
@ISA = ( "EPrints::Plugin::InputForm::Component" );

use strict;

sub new
{
    my( $class, %opts ) = @_;

    my $self = $class->SUPER::new( %opts );

    $self->{name} = "REF2029";
    $self->{visible} = "all";
    $self->{surround} = "Default";

    return $self;
}

sub update_from_form
{
    my( $self, $processor ) = @_;

    my $session = $self->{session};
    my $eprint = $self->{workflow}->{item};

    # get the ID of the record we want to update
    my $ref2029id = $session->param( $self->{prefix} . "_update_ref2029" );

    # get the dataobj
    my $ref_ds = $self->{session}->get_dataset( "ref2029_cc" );
    my $ref2029 = $ref_ds->dataobj( $ref2029id );
    return if !defined $ref2029;

    my $ref_prefix = $self->{prefix}."_ref2029_".$ref2029id;

    # update the dataobj
    my @fields = $self->ref2029_fields;
    foreach my $field ( @fields )
    {
        my $value = $field->form_value(
           $session,
           $ref2029,
           $ref_prefix
        );
        $ref2029->set_value( $field->{name}, $value );
    }
    $ref2029->commit;

    return;
}

sub render_content
{
    my( $self, $surround ) = @_;

    my $session = $self->{session};
    my $eprint = $self->{workflow}->{item};

    my $ref2029 = $eprint->value( "ref2029_cc" );

    my $ref2029id = $ref2029->id;

    my $ref_prefix = $self->{prefix}."_ref2029_".$ref2029id;
    my $ref_div = $self->{session}->make_element( "div", class=>"ep_ref2029_cc", id=>$ref_prefix."_block" );

    # Hidden field for the REF2029 Dataobj ID
    $ref_div->appendChild( $session->render_hidden_field( $self->{prefix}."_update_ref2029", $ref2029id ) );

    my @fields = $self->ref2029_fields;

    my $table = $session->make_element( "div", class=>"ep_ref2029_fields" );
    $ref_div->appendChild( $table );

    foreach my $field ( @fields )
    {
        my $no_toggle = $self->{no_toggle},
        my $no_help = $self->{no_help};
        my $labeltext = $field->render_name($session);
        if( $field->{required} )
        {
                        my $required = $self->{session}->make_element( "img",
                                src => $self->{session}->html_phrase( "sys:ep_form_required_src" ),
                                class => "ep_required",
                                alt => $self->{session}->html_phrase( "sys:ep_form_required_alt" ));
                        $required->appendChild( $self->{session}->make_text( " " ) );
                        $required->appendChild( $labeltext );
                        $labeltext = $required;
        }
        if ( defined $field->{show_help} )
        {
            $no_toggle = 1 if $field->{show_help} eq "always";
            $no_toggle = 0 if $field->{show_help} eq "toggle";
            $no_help = 1 if $field->{show_help} eq "never";
        }

        $table->appendChild( $session->render_row_with_help(
            label=>$labeltext,
            field=>$field->render_input_field(
                                $session,
                                $ref2029->get_value( $field->get_name ),
                                undef,
                                0,
                                undef,
                                $ref2029,
                                $ref_prefix ),
            prefix=>$ref_prefix."_".$field->get_name,
            help=>$field->render_help($session),
            help_prefix=>$ref_prefix."_".$field->get_name."_help",
            no_toggle=>$no_toggle,
            no_help=>$no_help,
        ));
    }

    return $ref_div;
}

sub ref2029_fields
{
    my( $self ) = @_;

    return @{$self->{config}->{ref_fields}};
}

sub parse_config
{
    my( $self, $config_dom ) = @_;

    $self->{config}->{ref_fields} = [];

    my @fields = $config_dom->getElementsByTagName( "field" );

    my $ref_ds = $self->{session}->get_dataset( "ref2029_cc" );

    foreach my $field_tag ( @fields )
    {
        my $field = $self->xml_to_metafield( $field_tag, $ref_ds );
        return if !defined $field;
        push @{$self->{config}->{ref_fields}}, $field;
    }
}

