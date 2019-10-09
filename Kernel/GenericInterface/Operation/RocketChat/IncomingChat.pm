package Kernel::GenericInterface::Operation::RocketChat::IncomingChat;

use strict;
use warnings;

use Data::Dumper;

use Digest::MD5 qw(md5_hex);

use Date::Parse;

use Kernel::System::VariableCheck qw(:all);
use utf8;
use Encode qw(decode encode);

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
            Success => 1,
            Tickets => [123, 323] # ID of Tickets that were created or modified
        },
    }

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');

    if (
        !$Param{Data}->{UserLogin}
        && !$Param{Data}->{CustomerUserLogin}
        && !$Param{Data}->{SessionID}
        )
    {
        return $Self->ReturnError(
            ErrorCode    => 'RocketChat.MissingParameter',
            ErrorMessage => "RocketChat: UserLogin, CustomerUserLogin or SessionID is required!",
        );
    }

    if ( $Param{Data}->{UserLogin} || $Param{Data}->{CustomerUserLogin} ) {

        if ( !$Param{Data}->{Password} )
        {
            return $Self->ReturnError(
                ErrorCode    => 'RocketChat.MissingParameter',
                ErrorMessage => "RocketChat: Password or SessionID is required!",
            );
        }
    }
	
    my ( $UserID, $UserType ) = $Self->Auth(
        %Param,
    );

    if ( !$UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'RocketChat.AuthFail',
            ErrorMessage => "RocketChat: User could not be authenticated!",
        );
    }
    
    my %Data;
    $Data{UserLogin}         = $Param{Data}->{agent}->{username} || '';
    $Data{CustomerUserLogin} = $Param{Data}->{visitor}->{customFields}->{username} || '';
    $Data{CustomerUserName}  = $Param{Data}->{visitor}->{name} || '';
    $Data{CustomerUserEmail} = $Param{Data}->{visitor}->{email} || '';
    $Data{Queue}  = $Param{Data}->{visitor}->{department} || '';

    # Se nova, Verifica se existe chamado associado a este chat
    my @TicketIDs;
    my $MainTicket;
    if($Param{Data}->{"_id"}){

        $Self->{CacheType} = 'RocketChatTicketRoom';
        $Self->{CacheTTL}  = 60 * 60 * 24 * 20;
        $Self->{CacheKey} = 'RocketChatTicketRoom::' . $Param{Data}->{"_id"};

        my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type => $Self->{CacheType},
            Key  => $Self->{CacheKey},
        );

        if($Cache){
            push @TicketIDs, $Cache;
        } else {
            @TicketIDs = $TicketObject->TicketSearch(
                UserID => 1,
                Result => 'ARRAY',
                "DynamicField_RocketChatLiveChatID" => {
                    Equals => $Param{Data}->{"_id"}
                }
            );
            # set cache
            $Kernel::OM->Get('Kernel::System::Cache')->Set(
                Type  => $Self->{CacheType},
                TTL   => $Self->{CacheTTL},
                Key   => $Self->{CacheKey},
                Value => $TicketIDs[0],
            ) if $TicketIDs[0]; # Caso o Cache tenha sido apagado, reaplicamos aqui
        }
    }

    if (@TicketIDs){
        $MainTicket = $TicketIDs[0];
    }

    my $Topic = $Param{Data}->{topic} || 
        $LayoutObject->{LanguageObject}->Translate('Chat Ticket');

    # Verifica se é Mensagem nova ou encerramento do Chat
    if($Param{Data}->{type} eq 'Message'){
        if (@TicketIDs){
            # return result
            return {
                Success => 1,
                Data    => {
                    Success => 1,
                    ReturnMessage => "Nothing updated. Ticket for this chat was already created",
                    Tickets => \@TicketIDs
                },
            };
        }
        # Se não encontrou chamado associado, significa que é a primeira mensagem do Chat
        # Cria então um chamado
        my $CustomerUser = $Param{Data}->{visitor}->{customFields}->{username} || 'rocketchat';
        my @CustomerIDs = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerIDs(
            User => $CustomerUser,
        );
        my $CustomerCompany = $CustomerIDs[0] || $CustomerUser;
        my $TicketID = $TicketObject->TicketCreate(
            Title        => $Topic,
            CustomerUser => $CustomerUser,
            CustomerID   => $CustomerCompany,
            %{$Param{Data}->{NewChat}}
        );
        # set cache
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $Self->{CacheKey},
            Value => $TicketID,
        ) if $TicketID;

        $MainTicket = $TicketID;

        # Notifies Rocket.Chat session
        if($Param{Data}->{NewTicketNotification}
            && $Param{Data}->{NewTicketNotification}->{RocketChatAPIUrl}
            && $Param{Data}->{NewTicketNotification}->{Message}
            && $Param{Data}->{_id}
            && $Param{Data}->{visitor}
            && $Param{Data}->{visitor}->{token}
            )
        {
            use LWP;
            use HTTP::Request;
            use Encode;
            my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

            my %Ticket = $TicketObject->TicketGet(TicketID => $TicketID, UserID => 1);
            my $TN = $Ticket{TicketNumber};

            my $json;

            {
                no warnings 'redundant';
                $json='{
                    "token": "'.$Param{Data}->{visitor}->{token}.'", 
                    "rid": "'.$Param{Data}->{_id}.'", 
                    "msg": "'.sprintf(encode('UTF-8',$Param{Data}->{NewTicketNotification}->{Message}),$TN,$TN,$TN,$TN,$TN).'"
                }';
            }
            my $url = $Param{Data}->{NewTicketNotification}->{RocketChatAPIUrl};
            my $req = HTTP::Request->new(POST => $url);
            $req->content_type('application/json');
            $req->content($json);
            my $ua = LWP::UserAgent->new; # You might want some options here
            # Disable Certificate verification
            $ua->ssl_opts(verify_hostname => 0);
            $ua->ssl_opts(SSL_verify_mode => 0x00);
            
            my $res = $ua->request($req);
            my $Result = $JSONObject->Decode(Data=>$res->decoded_content);
            my $Success = $Result->{success};
        }

        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
    		Name => "RocketChatLiveChatID",
	    );
        my $Success = $DynamicFieldValueObject->ValueSet(
            FieldID => $DynamicField->{ID},
            ObjectID => $TicketID,
            Value => [
                {
                    ValueText => $Param{Data}->{"_id"}
                }
            ],
            UserID => 1
        );
        push @TicketIDs, $TicketID;

        # Enviar mensagem para o usuario

        # Sair do fluxo
        # return result
        return {
            Success => 1,
            Data    => {
                Success => 1,
                ReturnMessage => "Ticket Created!",
                Tickets => \@TicketIDs
            },
        };

    } elsif($Param{Data}->{type} eq 'LivechatSession'){
        # Se é encerramento do Chat
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
            push @TicketIDs, $TicketID if $TicketID;
        }

        # Prepara html a ser criado com base nos "messages"
        my @Messages = ();
        if($Param{Data}->{messages} && IsArrayRefWithData($Param{Data}->{messages})){
            (@Messages) = @{$Param{Data}->{messages}};
        } elsif ($Param{Data}->{messages}) {
            push @Messages, $Param{Data}->{messages};
        }
        
        my $LastDate=   '';
        my $LastAuthor='';

        my $AgentGravatar = md5_hex($Param{Data}->{agent}->{email}) ||'00000000000000000000000000000000';
        my $CustomerGravatar = md5_hex($Param{Data}->{visitor}->{email}) ||'00000000000000000000000000000000';
        
        my $AgentName = $Param{Data}->{agent}->{name} || $Param{Data}->{agent}->{username} || $LayoutObject->{LanguageObject}->Translate('Agent');
        my $CustomerName = $Param{Data}->{visitor}->{name} || $Param{Data}->{visitor}->{username} || $LayoutObject->{LanguageObject}->Translate('Customer');
        
        for my $message (@Messages){
            # Obs: the time of the message is always send in UTF
            my $time = str2time($message->{ts});
            # the following field is set by javascript as a customfield on RocketChat. We need that to calculate
            # customer time of the message
            my $tz = $Param{Data}->{visitor}->{customFields}->{timezone} || 0; 
            $time += ($tz*60);
            # Clean Time string Epoch
            $time =~ s/\..*//;
            my $DateObj = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    Epoch => $time,
                },
            );

            $DateObj->ToTimeZone(
                TimeZone => $DateObj->UserDefaultTimeZoneGet()
            );


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
                        Time   => $DateObj->Format(
                            Format => "%H:%M"
                        ) . " (".$DateObj->UserDefaultTimeZoneGet().")",
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

        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Phone' );
        
        for my $TicketID(@TicketIDs){
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
                IsVisibleForCustomer => 1,
            );
        }

        # Update the ticket that was created by Rocket.Chat
        my ( $UserID, $UserType ) = $Self->Auth(%Param);
        my $Update = $Param{Data}->{ChatClosed};
        $Self->_TicketUpdate(
			TicketID         => $MainTicket,
			Ticket           => $Update,
			UserID           => $UserID,
			UserType         => $UserType,
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
            Success => 1,
            ReturnMessage => "Chat closed. Tickets updated!",
            Tickets => \@TicketIDs
        },
    };
}



=item _CheckUpdatePermissions()
check if user has permissions to update ticket attributes.
    my $Response = $OperationObject->_CheckUpdatePermissions(
        TicketID     => 123
        Ticket       => $Ticket,                  # all ticket parameters
        Article      => $Ticket,                  # all attachment parameters
        DynamicField => $Ticket,                  # all dynamic field parameters
        Attachment   => $Ticket,                  # all attachment parameters
        UserID       => 123,
    );
    returns:
    $Response = {
        Success => 1,                               # if everything is OK
    }
    $Response = {
        Success      => 0,
        ErrorCode    => "function.error",           # if error
        ErrorMessage => "Error description"
    }
=cut

sub _CheckUpdatePermissions {
    my ( $Self, %Param ) = @_;

    my $TicketID         = $Param{TicketID};
    my $Ticket           = $Param{Ticket};
    my $Article          = $Param{Article};
    my $DynamicFieldList = $Param{DynamicFieldList};
    my $AttachmentList   = $Param{AttachmentList};

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # check Article permissions
    if ( IsHashRefWithData($Article) ) {
        my $Access = $TicketObject->TicketPermission(
            Type     => 'note',
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to create new articles!",
            };
        }
    }

    # check dynamic field permissions
    if ( IsArrayRefWithData($DynamicFieldList) ) {
        my $Access = $TicketObject->TicketPermission(
            Type     => 'rw',
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to update dynamic fields!",
            };
        }
    }

    # check queue permissions
    if ( $Ticket->{Queue} || $Ticket->{QueueID} ) {
        my $Access = $TicketObject->TicketPermission(
            Type     => 'move',
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to update queue!",
            };
        }
    }

    # check owner permissions
    if ( $Ticket->{Owner} || $Ticket->{OwnerID} ) {
        my $Access = $TicketObject->TicketPermission(
            Type     => 'owner',
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to update owner!",
            };
        }
    }

    # check responsible permissions
    if ( $Ticket->{Responsible} || $Ticket->{ResponsibleID} ) {
        my $Access = $TicketObject->TicketPermission(
            Type     => 'responsible',
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to update responsibe!",
            };
        }
    }

    # check priority permissions
    if ( $Ticket->{Priority} || $Ticket->{PriorityID} ) {
        my $Access = $TicketObject->TicketPermission(
            Type     => 'priority',
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to update priority!",
            };
        }
    }

    # check state permissions
    if ( $Ticket->{State} || $Ticket->{StateID} ) {

        # get State Data
        my %StateData;
        my $StateID;

        # get state object
        my $StateObject = $Kernel::OM->Get('Kernel::System::State');

        if ( $Ticket->{StateID} ) {
            $StateID = $Ticket->{StateID};
        }
        else {
            $StateID = $StateObject->StateLookup(
                State => $Ticket->{State},
            );
        }

        %StateData = $StateObject->StateGet(
            ID => $StateID,
        );

        my $Access = 1;

        if ( $StateData{TypeName} =~ /^close/i ) {
            $Access = $TicketObject->TicketPermission(
                Type     => 'close',
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }

        # set pending time
        elsif ( $StateData{TypeName} =~ /^pending/i ) {
            $Access = $TicketObject->TicketPermission(
                Type     => 'close',
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        if ( !$Access ) {
            return {
                ErrorCode    => 'TicketUpdateOrCreate.AccessDenied',
                ErrorMessage => "TicketUpdateOrCreate: Does not have permissions to update state!",
            };
        }
    }

    return {
        Success => 1,
        }
}


=item _TicketUpdate()
updates a ticket and creates an article and sets dynamic fields and attachments if specified.
    my $Response = $OperationObject->_TicketUpdate(
        TicketID     => 123
        Ticket       => $Ticket,                  # all ticket parameters
        Article      => $Article,                 # all attachment parameters
        DynamicField => $DynamicField,            # all dynamic field parameters
        Attachment   => $Attachment,              # all attachment parameters
        UserID       => 123,
        UserType     => 'Agent'                   # || 'Customer
    );
    returns:
    $Response = {
        Success => 1,                               # if everything is OK
        Data => {
            TicketID     => 123,
            TicketNumber => 'TN3422332',
            ArticleID    => 123,                    # if new article was created
        }
    }
    $Response = {
        Success      => 0,                         # if unexpected error
        ErrorMessage => "$Param{ErrorCode}: $Param{ErrorMessage}",
    }
=cut

sub _TicketUpdate {
    my ( $Self, %Param ) = @_;

    my $TicketID         = $Param{TicketID};
    my $Ticket           = $Param{Ticket};
    my $Article          = $Param{Article};
    my $DynamicFieldList = $Param{DynamicFieldList};
    my $AttachmentList   = $Param{AttachmentList};

    my $Access = $Self->_CheckUpdatePermissions(%Param);

    # if no permissions return error
    if ( !$Access->{Success} ) {
        return $Self->ReturnError( %{$Access} );
    }

    my %CustomerUserData;

    # get customer information
    if ( $Ticket->{CustomerUser} ) {
        %CustomerUserData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Ticket->{CustomerUser},
        );
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get current ticket data
    my %TicketData = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 0,
        UserID        => $Param{UserID},
    );

    # update ticket parameters
    # update Ticket->Title
    if (
        defined $Ticket->{Title}
        && $Ticket->{Title} ne ''
        && $Ticket->{Title} ne $TicketData{Title}
        )
    {
        my $Success = $TicketObject->TicketTitleUpdate(
            Title    => $Ticket->{Title},
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket title could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->Queue
    if ( $Ticket->{Queue} || $Ticket->{QueueID} ) {
        my $Success;
        if ( defined $Ticket->{Queue} && $Ticket->{Queue} ne $TicketData{Queue} ) {
            $Success = $TicketObject->TicketQueueSet(
                Queue    => $Ticket->{Queue},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{QueueID} && $Ticket->{QueueID} ne $TicketData{QueueID} ) {
            $Success = $TicketObject->TicketQueueSet(
                QueueID  => $Ticket->{QueueID},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                ErrorMessage =>
                    'Ticket queue could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->Lock
    if ( $Ticket->{Lock} || $Ticket->{LockID} ) {
        my $Success;
        if ( defined $Ticket->{Lock} && $Ticket->{Lock} ne $TicketData{Lock} ) {
            $Success = $TicketObject->TicketLockSet(
                Lock     => $Ticket->{Lock},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{LockID} && $Ticket->{LockID} ne $TicketData{LockID} ) {
            $Success = $TicketObject->TicketLockSet(
                LockID   => $Ticket->{LockID},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket lock could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->Type
    if ( $Ticket->{Type} || $Ticket->{TypeID} ) {
        my $Success;
        if ( defined $Ticket->{Type} && $Ticket->{Type} ne $TicketData{Type} ) {
            $Success = $TicketObject->TicketTypeSet(
                Type     => $Ticket->{Type},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{TypeID} && $Ticket->{TypeID} ne $TicketData{TypeID} )
        {
            $Success = $TicketObject->TicketTypeSet(
                TypeID   => $Ticket->{TypeID},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket type could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket>State
    # depending on the state, might require to unlock ticket or enables pending time set
    if ( $Ticket->{State} || $Ticket->{StateID} ) {

        # get State Data
        my %StateData;
        my $StateID;

        # get state object
        my $StateObject = $Kernel::OM->Get('Kernel::System::State');

        if ( $Ticket->{StateID} ) {
            $StateID = $Ticket->{StateID};
        }
        else {
            $StateID = $StateObject->StateLookup(
                State => $Ticket->{State},
            );
        }

        %StateData = $StateObject->StateGet(
            ID => $StateID,
        );

        # force unlock if state type is close
        if ( $StateData{TypeName} =~ /^close/i ) {

            # set lock
            $TicketObject->TicketLockSet(
                TicketID => $TicketID,
                Lock     => 'unlock',
                UserID   => $Param{UserID},
            );
        }

        # set pending time
        elsif ( $StateData{TypeName} =~ /^pending/i ) {

            # set pending time
            if ( defined $Ticket->{PendingTime} ) {
                my $Success = $TicketObject->TicketPendingTimeSet(
                    UserID   => $Param{UserID},
                    TicketID => $TicketID,
                    %{ $Ticket->{PendingTime} },
                );

                if ( !$Success ) {
                    return {
                        Success => 0,
                        Errormessage =>
                            'Ticket pendig time could not be updated, please contact system'
                            . ' administrator!',
                        }
                }
            }
            else {
                return $Self->ReturnError(
                    ErrorCode    => 'TicketUpdateOrCreate.MissingParameter',
                    ErrorMessage => 'Can\'t set a ticket on a pending state without pendig time!'
                    )
            }
        }

        my $Success;
        if ( defined $Ticket->{State} && $Ticket->{State} ne $TicketData{State} ) {
            $Success = $TicketObject->TicketStateSet(
                State    => $Ticket->{State},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{StateID} && $Ticket->{StateID} ne $TicketData{StateID} )
        {
            $Success = $TicketObject->TicketStateSet(
                StateID  => $Ticket->{StateID},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket state could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->Service
    # this might reset SLA if current SLA is not available for the new service
    if ( $Ticket->{Service} || $Ticket->{ServiceID} ) {

        # check if ticket has a SLA assigned
        if ( $TicketData{SLAID} ) {

            # check if old SLA is still valid
            if (
                !$Self->ValidateSLA(
                    SLAID     => $TicketData{SLAID},
                    Service   => $Ticket->{Service} || '',
                    ServiceID => $Ticket->{ServiceID} || '',
                )
                )
            {

                # remove current SLA if is not compatible with new service
                my $Success = $TicketObject->TicketSLASet(
                    SLAID    => '',
                    TicketID => $TicketID,
                    UserID   => $Param{UserID},
                );
            }
        }

        my $Success;

        # prevent comparison errors on undefined values
        if ( !defined $TicketData{Service} ) {
            $TicketData{Service} = '';
        }
        if ( !defined $TicketData{ServiceID} ) {
            $TicketData{ServiceID} = '';
        }

        if ( defined $Ticket->{Service} && $Ticket->{Service} ne $TicketData{Service} ) {
            $Success = $TicketObject->TicketServiceSet(
                Service  => $Ticket->{Service},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{ServiceID} && $Ticket->{ServiceID} ne $TicketData{ServiceID} )
        {
            $Success = $TicketObject->TicketServiceSet(
                ServiceID => $Ticket->{ServiceID},
                TicketID  => $TicketID,
                UserID    => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket service could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->SLA
    if ( $Ticket->{SLA} || $Ticket->{SLAID} ) {
        my $Success;

        # prevent comparison errors on undefined values
        if ( !defined $TicketData{SLA} ) {
            $TicketData{SLA} = '';
        }
        if ( !defined $TicketData{SLAID} ) {
            $TicketData{SLAID} = '';
        }

        if ( defined $Ticket->{SLA} && $Ticket->{SLA} ne $TicketData{SLA} ) {
            $Success = $TicketObject->TicketSLASet(
                SLA      => $Ticket->{SLA},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{SLAID} && $Ticket->{SLAID} ne $TicketData{SLAID} )
        {
            $Success = $TicketObject->TicketSLASet(
                SLAID    => $Ticket->{SLAID},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket SLA could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->CustomerUser && Ticket->CustomerID
    if ( $Ticket->{CustomerUser} || $Ticket->{CustomerID} ) {

        # set values to empty if they are not defined
        $TicketData{CustomerUserID} = $TicketData{CustomerUserID} || '';
        $TicketData{CustomerID}     = $TicketData{CustomerID}     || '';
        $Ticket->{CustomerUser}     = $Ticket->{CustomerUser}     || '';
        $Ticket->{CustomerID}       = $Ticket->{CustomerID}       || '';

        my $Success;
        if (
            $Ticket->{CustomerUser} ne $TicketData{CustomerUserID}
            || $Ticket->{CustomerID} ne $TicketData{CustomerID}
            )
        {
            my $CustomerID = $CustomerUserData{UserCustomerID} || '';

            # use user defined CustomerID if defined
            if ( defined $Ticket->{CustomerID} && $Ticket->{CustomerID} ne '' ) {
                $CustomerID = $Ticket->{CustomerID};
            }

            $Success = $TicketObject->TicketCustomerSet(
                No       => $CustomerID,
                User     => $Ticket->{CustomerUser},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket customer user could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->Priority
    if ( $Ticket->{Priority} || $Ticket->{PriorityID} ) {
        my $Success;
        if ( defined $Ticket->{Priority} && $Ticket->{Priority} ne $TicketData{Priority} ) {
            $Success = $TicketObject->TicketPrioritySet(
                Priority => $Ticket->{Priority},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif ( defined $Ticket->{PriorityID} && $Ticket->{PriorityID} ne $TicketData{PriorityID} )
        {
            $Success = $TicketObject->TicketPrioritySet(
                PriorityID => $Ticket->{PriorityID},
                TicketID   => $TicketID,
                UserID     => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket priority could not be updated, please contact system administrator!',
                }
        }
    }

    my $UnlockOnAway = 1;

    # update Ticket->Owner
    if ( $Ticket->{Owner} || $Ticket->{OwnerID} ) {
        my $Success;
        if ( defined $Ticket->{Owner} && $Ticket->{Owner} ne $TicketData{Owner} ) {
            $Success = $TicketObject->TicketOwnerSet(
                NewUser  => $Ticket->{Owner},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
            $UnlockOnAway = 0;
        }
        elsif ( defined $Ticket->{OwnerID} && $Ticket->{OwnerID} ne $TicketData{OwnerID} )
        {
            $Success = $TicketObject->TicketOwnerSet(
                NewUserID => $Ticket->{OwnerID},
                TicketID  => $TicketID,
                UserID    => $Param{UserID},
            );
            $UnlockOnAway = 0;
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket owner could not be updated, please contact system administrator!',
                }
        }
    }

    # update Ticket->Responsible
    if ( $Ticket->{Responsible} || $Ticket->{ResponsibleID} ) {
        my $Success;
        if (
            defined $Ticket->{Responsible}
            && $Ticket->{Responsible} ne $TicketData{Responsible}
            )
        {
            $Success = $TicketObject->TicketResponsibleSet(
                NewUser  => $Ticket->{Responsible},
                TicketID => $TicketID,
                UserID   => $Param{UserID},
            );
        }
        elsif (
            defined $Ticket->{ResponsibleID}
            && $Ticket->{ResponsibleID} ne $TicketData{ResponsibleID}
            )
        {
            $Success = $TicketObject->TicketResponsibleSet(
                NewUserID => $Ticket->{ResponsibleID},
                TicketID  => $TicketID,
                UserID    => $Param{UserID},
            );
        }
        else {

            # data is the same as in ticket nothing to do
            $Success = 1;
        }

        if ( !$Success ) {
            return {
                Success => 0,
                Errormessage =>
                    'Ticket responsible could not be updated, please contact system administrator!',
                }
        }
    }

    my $ArticleID;
    if ( IsHashRefWithData($Article) ) {

        # set Article From
        my $From;
        if ( $Article->{From} ) {
            $From = $Article->{From};
        }
        elsif ( $Param{UserType} eq 'Customer' ) {

            # use data from customer user (if customer user is in database)
            if ( IsHashRefWithData( \%CustomerUserData ) ) {
                $From = '"'
                    . $CustomerUserData{UserFirstname} . ' '
                    . $CustomerUserData{UserLastname} . '"'
                    . ' <' . $CustomerUserData{UserEmail} . '>';
            }

            # otherwise use customer user as sent from the request (it should be an email)
            else {
                $From = $Ticket->{CustomerUser};
            }
        }
        else {
            my %UserData = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
                UserID => $Param{UserID},
            );
            $From = $UserData{UserFirstname} . ' ' . $UserData{UserLastname};
        }

        # set Article To
        my $To = '';

        # create article
        $ArticleID = $TicketObject->ArticleCreate(
            NoAgentNotify  => $Article->{NoAgentNotify}  || 0,
            TicketID       => $TicketID,
            ArticleTypeID  => $Article->{ArticleTypeID}  || '',
            ArticleType    => $Article->{ArticleType}    || '',
            SenderTypeID   => $Article->{SenderTypeID}   || '',
            SenderType     => $Article->{SenderType}     || '',
            From           => $From,
            To             => $To,
            Subject        => $Article->{Subject},
            Body           => $Article->{Body},
            MimeType       => $Article->{MimeType}       || '',
            Charset        => $Article->{Charset}        || '',
            ContentType    => $Article->{ContentType}    || '',
            UserID         => $Param{UserID},
            HistoryType    => $Article->{HistoryType},
            HistoryComment => $Article->{HistoryComment} || '%%',
            AutoResponseType => $Article->{AutoResponseType},
            UnlockOnAway     => $UnlockOnAway,
            OrigHeader       => {
                From    => $From,
                To      => $To,
                Subject => $Article->{Subject},
                Body    => $Article->{Body},

            },
        );

        if ( !$ArticleID ) {
            return {
                Success => 0,
                ErrorMessage =>
                    'Article could not be created, please contact the system administrator'
                }
        }

        # time accounting
        if ( $Article->{TimeUnit} ) {
            $TicketObject->TicketAccountTime(
                TicketID  => $TicketID,
                ArticleID => $ArticleID,
                TimeUnit  => $Article->{TimeUnit},
                UserID    => $Param{UserID},
            );
        }
    }

    # set dynamic fields
    for my $DynamicField ( @{$DynamicFieldList} ) {
        my $Result = $Self->SetDynamicFieldValue(
            %{$DynamicField},
            TicketID  => $TicketID,
            ArticleID => $ArticleID || '',
            UserID    => $Param{UserID},
        );

        if ( !$Result->{Success} ) {
            my $ErrorMessage =
                $Result->{ErrorMessage} || "Dynamic Field $DynamicField->{Name} could not be set,"
                . " please contact the system administrator";

            return {
                Success      => 0,
                ErrorMessage => $ErrorMessage,
            };
        }
    }

    # set attachments

    for my $Attachment ( @{$AttachmentList} ) {
        my $Result = $Self->CreateAttachment(
            Attachment => $Attachment,
            ArticleID  => $ArticleID || '',
            UserID     => $Param{UserID}
        );

        if ( !$Result->{Success} ) {
            my $ErrorMessage =
                $Result->{ErrorMessage} || "Attachment could not be created, please contact the "
                . " system administrator";

            return {
                Success      => 0,
                ErrorMessage => $ErrorMessage,
            };
        }
    }

    if ($ArticleID) {
        return {
            Success => 1,
            Data    => {
                TicketID     => $TicketID,
                TicketNumber => $TicketData{TicketNumber},
                ArticleID    => $ArticleID,
            },
        };
    }
    return {
        Success => 1,
        Data    => {
            TicketID     => $TicketID,
            TicketNumber => $TicketData{TicketNumber},
        },
    };
}

1;

=back
