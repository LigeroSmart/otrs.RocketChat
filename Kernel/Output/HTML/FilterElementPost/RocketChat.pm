package Kernel::Output::HTML::FilterElementPost::RocketChat;

use strict;
use warnings;

use Data::Dumper;


our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
);

=head1 ADDON

RocketChat


=head1 NAME

Kernel::Output::HTML::FilterElementPost::RocketChat


=head1 SYNOPSIS

Output element filter that includes rocket.chat script
on OTRS's Customer interface

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

Creates the object. Also takes user information and sets into Self element

=cut
sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );
    
    $Self->{UserLogin} = $Param{UserLogin};
    $Self->{UserFirstname} = $Param{UserFirstname} || 'Guest';
    $Self->{UserLastname} = $Param{UserLastname} || '';
    $Self->{UserEmail} = $Param{UserEmail};
    
    return $Self;
}

=item Run()

Execute output filter element for includin Rocket.Chat livechat script on 
OTRS's Customer Interface

=cut
sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %Data = (
        UserLogin            => $Self->{UserLogin},
        UserFirstname        => $Self->{UserFirstname},
        UserLastname         => $Self->{UserLastname},
        UserEmail            => $Self->{UserEmail},
        RocketChatJavascript => $Kernel::OM->Get('Kernel::Config')->Get('RocketChat::Code')
    );

    my $Content = $LayoutObject->Output(
        TemplateFile => 'RocketChat',
        Data         => {
            %Data
        },
    );
    ## Add Rocket Chat script
    ${ $Param{Data} } .= $Content;

    return 1;
}

1;
