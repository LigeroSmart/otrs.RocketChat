# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Operation::RocketChat::IncomingChat;

use strict;
use warnings;

use Data::Dumper;

use Kernel::System::VariableCheck qw(:all);
use utf8;
use base qw(
    Kernel::GenericInterface::Operation::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::RocketChat::IncomingChat - GenericInterface RocketChat Integration

=head1 SYNOPSIS

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

perform RocketChat chat store at new or already existent ticket

Returns nothing

=cut

sub Run {
    my ( $Self, %Param ) = @_;


    #Check auth Params 
    # check needed stuff
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
	
    # authenticate user
    my ( $UserID, $UserType ) = $Self->Auth(
        %Param,
    );

    if ( !$UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'TicketCreate.AuthFail',
            ErrorMessage => "TicketCreate: User could not be authenticated!",
        );
    }
    
    
    $Kernel::OM->Get('Kernel::System::Log')->Log( Priority => 'error', Message => "aaaaaaaaaaaa ".Dumper(%Param));
    
    # Pega dados do Atendente
    
    # Pega dados do Cliente
    
    # Pega o departamento
    
    # Pega tickets que devem ser atualizados
    
    # Se não houver, cria um ticket na fila relativa ao departamento
    
    # Prepara html a ser criado com base nos messages
    
    # Para cada ticket envolvido, cria um artigo com o conteúdo do chat
    
    

    #my $HasAccess = 0;
 
    ##Get All Permission Groups that Has Access to API
    #my @ConfigPermissionGroups = @{$Kernel::OM->Get('Kernel::Config')->Get('GenericInterface::Operation::Groups')};
    ##---------------------------------------------------------------------------------------------------------#

    ##objecto do grupo
    #my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
    
    ##Pega a lista de todos os grupos do Usuário
    #my %GroupList = $GroupObject->PermissionUserGroupGet(
        #UserID => $UserID,
        #Type   => 'move_into',  # ro|move_into|priority|create|rw
    #);
   
    ##Verifica se o usuário esta em um grupo que permite o acesso as informações dessa API
	#my $teste = "";
	#my $a = "";
   	#foreach my $keys (keys %GroupList){
	#if ($a =  grep { $_ eq $GroupList{$keys} } @ConfigPermissionGroups ){
		#$HasAccess = 1;
	#}
    #}
    #if( $HasAccess == 0) {
	#return {
                #Success      => 0,
                #ErrorMessage => "You don't have permission to $teste access data"
            #};

    #}
    # get languages list
    # set UserID to root because in public interface there is no user
    # check needed objects
    for my $Needed (qw( Object Method )) {
        if ( !$Param{Data}->{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "You should inform $Needed parameter!"
            };
        }
    }
    
    # check data - only accept undef or hash ref
    if ( defined $Param{Data} && ref $Param{Data} ne 'HASH' ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got Data but it is not a hash ref in Operation Test backend)!'
        );
    }

    #my $Object=$Param{Data}->{Object};
    #my $Method=$Param{Data}->{Method};
    
    #my %Data;

    #if($Param{Data}->{ReturnType} eq 'ARRAY'){
        ## RETURN IS ARRAY
        #$Data{Result}=[ $Kernel::OM->Get("Kernel::System::$Object")->$Method(
                           #%{$Param{Data}->{Params}}
                         #) ];
    #} elsif($Param{Data}->{ReturnType} eq 'HASH') {
        ## RETURN IS HASH
        #$Data{Result}={ $Kernel::OM->Get("Kernel::System::$Object")->$Method(
                           #%{$Param{Data}->{Params}}
                         #) };
    #} else {
        ## RETURN IS SCALAR (ID, NUMBER, TEXT);
        #$Data{Result}= $Kernel::OM->Get("Kernel::System::$Object")->$Method(
                           #%{$Param{Data}->{Params}}
                         #);
    #}
                     
    my $LogError = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
        Type => 'error', # error|info|notice
        What => 'Message', # Message|Traceback
    );
    
    #if($LogError){
        #$Data{Error}=$LogError;
    #}

    # return result
    return {
        Success => 1,
        Data    => {
            #%Data
        },
    };
}


1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
