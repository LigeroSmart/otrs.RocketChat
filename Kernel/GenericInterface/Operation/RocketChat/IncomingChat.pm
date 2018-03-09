package Kernel::GenericInterface::Operation::RocketChat::IncomingChat;

use strict;
use warnings;

use Data::Dumper;

use Digest::MD5 qw(md5_hex);

use Date::Parse;

use Kernel::System::VariableCheck qw(:all);
use utf8;
use base qw(
    Kernel::GenericInterface::Operation::Common
);

our $ObjectManagerDisabled = 1;

=head1 ADDON

RocketChat


=head1 NAME

Kernel::GenericInterface::Operation::RocketChat::IncomingChat - GenericInterface RocketChat Integration.


=head1 SYNOPSIS

This is a web service operation for treating incoming messages of RocketChat on OTRS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw( DebuggerObject WebserviceID )) {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=item Run()

Receive data from RocketChat webservice after livechat is closed and create a new ticket or
a new article on an existent ticket if the ticket number is informed as TAG.

Note that it's essential to have a well customized xslt mapping in order to correctly
create a new ticket, according to your system queues, states and so on.

Returns a hash like this:

    {
        Success => 1,
        Data    => {
            Success => 1
        },
    }

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    
    if (
        !$Param{Data}->{UserLogin}
        && !$Param{Data}->{CustomerUserLogin}
        && !$Param{Data}->{SessionID}
        )
    {
        return $Self->ReturnError(
            ErrorCode    => 'TicketCreate.MissingParameter',
            ErrorMessage => "TicketCreate: UserLogin, CustomerUserLogin or SessionID is required!",
        );
    }

    if ( $Param{Data}->{UserLogin} || $Param{Data}->{CustomerUserLogin} ) {

        if ( !$Param{Data}->{Password} )
        {
            return $Self->ReturnError(
                ErrorCode    => 'TicketCreate.MissingParameter',
                ErrorMessage => "TicketCreate: Password or SessionID is required!",
            );
        }
    }
	
    my ( $UserID, $UserType ) = $Self->Auth(
        %Param,
    );

    if ( !$UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'TicketCreate.AuthFail',
            ErrorMessage => "TicketCreate: User could not be authenticated!",
        );
    }
    
    my %Data;
    $Data{UserLogin}         = $Param{Data}->{agent}->{username} || '';
    $Data{CustomerUserLogin} = $Param{Data}->{visitor}->{customFields}->{username} || '';
    $Data{CustomerUserName}  = $Param{Data}->{visitor}->{name} || '';
    $Data{CustomerUserEmail} = $Param{Data}->{visitor}->{email} || '';
    $Data{Queue}  = $Param{Data}->{visitor}->{department} || '';
    
    # Verifica nas tags se houve algum número de chamado informado com "#"
    my @Tags = ();
    if($Param{Data}->{tags}){
        # Quando há apenas uma tag, ela vem como string e não como array, então temos que converter
        if(IsString($Param{Data}->{tags})){
            push @Tags,$Param{Data}->{tags};
        } else {
            (@Tags) = @{$Param{Data}->{tags}};            
        }
    }

    my @Tickets;

    # Para cada tag, verifica se possui o padrão #999999. Se sim, procura por um ticketid
    TAG:
    for my $Tag (@Tags){
        next TAG if $Tag !~ m/^#/;
        my $TicketID;
        $Tag =~ s/(#)//;
        $TicketID = $TicketObject->TicketIDLookup(
            TicketNumber => $Tag,
            UserID       => 1,
        );
        push @Tickets, $TicketID if $TicketID;
    }

    my $Topic = $Param{Data}->{topic} || 
        $LayoutObject->{LanguageObject}->Translate('Chat Ticket');


    # Se não houver, cria um ticket na fila relativa ao departamento
    if (!scalar @Tickets){
        my $CustomerUser = $Param{Data}->{visitor}->{customFields}->{username} || 'rocketchat';
        my @CustomerIDs = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerIDs(
           User => $CustomerUser,
        );
        my $CustomerCompany = $CustomerIDs[0] || $CustomerUser;
        my $TicketID = $TicketObject->TicketCreate(
           Title        => $Topic,
           CustomerUser => $CustomerUser,
           CustomerID   => $CustomerCompany,
           %{$Param{Data}->{NewTicket}}
       );
       push @Tickets, $TicketID;
   }
    # Prepara html a ser criado com base nos "messages"
    my @Messages = ();
    if($Param{Data}->{messages}){
        (@Messages) = @{$Param{Data}->{messages}};
    }
    
    my $LastDate;
    my $LastAuthor;

    my $AgentGravatar = md5_hex($Param{Data}->{agent}->{email}) ||'00000000000000000000000000000000';
    my $CustomerGravatar = md5_hex($Param{Data}->{visitor}->{email}) ||'00000000000000000000000000000000';
    
    my $AgentName = $Param{Data}->{agent}->{name} || $Param{Data}->{agent}->{username} || $LayoutObject->{LanguageObject}->Translate('Agent');
    my $CustomerName = $Param{Data}->{visitor}->{name} || $Param{Data}->{visitor}->{username} || $LayoutObject->{LanguageObject}->Translate('Customer');
    
    for my $message (@Messages){
        # Obs: the time of the message is always send in UTC
        my $time = int(str2time($message->{ts}));
        # the following field is set by javascript as a customfield on RocketChat. We need that to calculate
        # customer time of the message
        my $tz = $Param{Data}->{visitor}->{customFields}->{timezone} || 0; 
        $time += int($tz*60);
        my $dtLong = $Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(
            SystemTime => $time,
            Type       => 'Long',
        );
        my $dtShort = $Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(
            SystemTime => $time,
            Type       => 'Short',
        );
        my $Date = $LayoutObject->{LanguageObject}->FormatTimeString( $dtLong, 'DateFormatShort' );

        ### Left Widget (Avatar maybe)
        # Verifies if need to print author
        if($message->{username} ne $LastAuthor){
            $LastAuthor = $message->{username};
            my $Avatar;
            my $Name;
            if ($message->{username} =~ m/^guest/){
                $Name   = $CustomerName;
                $Avatar = $CustomerGravatar;
            } else {
                $Name   = $AgentName;
                $Avatar = $AgentGravatar;            
            }
            ### Print Author
            $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Block(
                Name => 'Author',
                Data => {
                    Left   => "<img src=\"https://www.gravatar.com/avatar/$Avatar?s=36\" class=\"RocketChatAvatar\"/>",
                    Author => $Name,
                    Time   => $dtShort,
                },
            );
        }
        
        $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Block(
            Name => 'Message',
            Data => {
                Content => $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
                    String => $message->{msg},
                )
            },
        );

    }
   
    my $ChatHTML = $LayoutObject->Output(
        TemplateFile => 'RocketChat/ChatTemplate'
    );
    
    for my $TicketID(@Tickets){

        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Phone' );

        
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            #NoAgentNotify  => $Article->{NoAgentNotify}  || 0,
            TicketID       => $TicketID,
            ArticleType    => 'webrequest',
            SenderType     => 'customer',
            From           => $Param{Data}->{visitor}->{name} || 'Chat Guest',
            To             => $Param{Data}->{agent}->{name} || 'Agent',
            Subject        => $Topic,
            Body           => $ChatHTML,
            MimeType       => 'text/html',
            Charset        => 'utf-8',
            UserID         => '1',
            HistoryType    => 'AddNote',
            HistoryComment => '%%ChatAdded%%',
            IsVisibleForCustomer => 1
        );
    }
    
    my $LogError = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
        Type => 'error', # error|info|notice
        What => 'Message', # Message|Traceback
    );
    
    if($LogError){
        $Data{Error}=$LogError;
    }

    # return result
    return {
        Success => 1,
        Data    => {
            Success => 1
        },
    };
}


1;

=back
