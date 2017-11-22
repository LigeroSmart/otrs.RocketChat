package Kernel::Output::HTML::FilterElementPost::RocketChat;

use strict;
use warnings;

use Data::Dumper;


our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
);

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
