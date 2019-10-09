# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::RocketChat;

=head1 ADDON

RocketChat


=head1 NAME

var::packagesetup::RocketChat - AddOn Auto installer script


=head1 SYNOPSIS

Create a RocketChat default Web Service on OTRS

=head1 PUBLIC INTERFACE

=over 4

=cut

use strict;
use warnings;

use Kernel::Output::Template::Provider;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::Log',
    'Kernel::System::State',
    'Kernel::System::Stats',
    'Kernel::System::SysConfig',
    'Kernel::System::Type',
    'Kernel::System::Valid',
);

=item new()

Creates the Object

=cut
sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item new()

Call all subroutines needed to the package installation

=cut
sub CodeInstall {
    my ( $Self, %Param ) = @_;

    $Self->_CreateDynamicFields();
	#$Self->_UpdateConfig();
    $Self-> _CreateWebServices();
    return 1;
}

=item new()

Call all subroutines needed to the package Upgrade

=cut
sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    #$Self->_CreateDynamicFields();
    $Self->_CreateWebServices();
    #$Self->_UpdateConfig();
	
    return 1;
}

sub _UpdateConfig {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
#    my @Configs = (
#        {
#            ConfigItem => 'CustomerFrontend::CommonParam###Action',
#            Value 	   => 'CustomerServiceCatalog'
#        },
#    );

#    CONFIGITEM:
#    for my $Config (@Configs) {
#        # set new setting,
#        my $Success = $SysConfigObject->ConfigItemUpdate(
#            Valid => 1,
#            Key   => $Config->{ConfigItem},
#            Value => $Config->{Value},
#        );

#    }

    return 1;
}

sub _CreateDynamicFields {
    my ( $Self, %Param ) = @_;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    # get the list of order numbers (is already sorted).
    my @DynamicfieldOrderList;
    for my $Dynamicfield ( @{$DynamicFieldList} ) {
        push @DynamicfieldOrderList, $Dynamicfield->{FieldOrder};
    }

    # get the last element from the order list and add 1
    my $NextOrderNumber = 1;
    if (@DynamicfieldOrderList) {
        $NextOrderNumber = $DynamicfieldOrderList[-1] + 1;
    }

    # get the definition for all dynamic fields for ITSM
    my @DynamicFields = $Self->_GetITSMDynamicFieldsDefinition();

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;
    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {
        next DYNAMICFIELD if ref $DynamicField ne 'HASH';
        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # create or update dynamic fields
    DYNAMICFIELD:
    for my $DynamicField (@DynamicFields) {

        my $CreateDynamicField;

        if ( ref $DynamicFieldLookup{ $DynamicField->{Name} } eq 'HASH' ) {
            # Deletes DF
            my $DynamicFieldID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
                                       Name => $DynamicField->{Name},
                                    );
            if ($DynamicFieldID->{ID}){
                  my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldDelete(
                   ID      => $DynamicFieldID->{ID},
                   UserID  => 1,
                   Reorder => 1,               # or 0, to trigger reorder function, default 1
               );
            }
        }

        # check if new field has to be created
#        if ($CreateDynamicField) {


            # create a new field
            my $FieldID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldAdd(
                InternalField => 1,
                Name          => $DynamicField->{Name},
                Label         => $DynamicField->{Label},
                FieldOrder    => $NextOrderNumber,
                FieldType     => $DynamicField->{FieldType},
                ObjectType    => $DynamicField->{ObjectType},
                Config        => $DynamicField->{Config},
                ValidID       => $ValidID,
                UserID        => 1,
            );
            next DYNAMICFIELD if !$FieldID;

            # increase the order number
            $NextOrderNumber++;
#        }
    }

    return 1;
}

sub _GetITSMDynamicFieldsDefinition {
    my ( $Self, %Param ) = @_;

    # define all dynamic fields for ITSM
    my @DynamicFields = (
        {
            Name       => 'RocketChatLiveChatID',
            Label      => 'RocketChatLiveChatID',
            FieldType  => 'Text',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue   => '',
            },
        },
    );

    return @DynamicFields;
}

sub _CreateWebServices {
    my ( $Self, %Param ) = @_;

    #Verify if it already exists
    my $List             = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    my %WebServiceLookup = reverse %{$List};
    my $Name = 'RocketChat';
    if ( $WebServiceLookup{$Name} ) {
        return 1;
    }

    # if doesn't exists
    my $YAML = <<"_END_";
---
Debugger:
  DebugThreshold: debug
  TestMode: '0'
Description: ''
FrameworkVersion: 6.0.x
Provider:
  Operation:
    Chat:
      Description: ''
      MappingInbound:
        Config:
          Template: "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>\\r\\n<xsl:stylesheet
            version=\\"1.0\\" xmlns:xsl=\\"http://www.w3.org/1999/XSL/Transform\\">\\r\\n
            \\ <!--\\r\\n       Department field mapping to queue for new ticket creation\\r\\n
            \\ -->\\r\\n  <xsl:variable name=\\"depto\\">\\r\\n    <xsl:value-of select=\\"//visitor/department\\"
            />\\r\\n  </xsl:variable>\\r\\n  <xsl:variable name=\\"deptotrans\\">\\r\\n    <xsl:choose>\\r\\n
            \\     <xsl:when test=\\"\$depto=''\\">Raw</xsl:when>\\r\\n      <xsl:when test=\\"\$depto='4FSjR5HdGzzyckKtE'\\">Raw</xsl:when>\\r\\n
            \\     <xsl:when test=\\"\$depto='E7S7a5ysKaxKeEZ7Y'\\">Raw</xsl:when>\\r\\n
            \\     <xsl:when test=\\"\$depto='E7S7a5ysKaxKeEZ7Y'\\">Raw</xsl:when>\\r\\n
            \\     <xsl:otherwise>Raw</xsl:otherwise>\\r\\n    </xsl:choose>\\r\\n  </xsl:variable>\\r\\n<!--\\r\\n
            \\ Copy all the elements\\r\\n-->\\r\\n  <xsl:template match=\\"node() | @*\\">\\r\\n
            \\   <xsl:copy>\\r\\n      <xsl:apply-templates select=\\"node() | @*\\" />\\r\\n
            \\   </xsl:copy>\\r\\n  </xsl:template>\\r\\n<!--\\r\\n  Add \\"Queue\\",\\"Priority\\",\\"State\\"...
            nodes for new ticket creation\\r\\n  You can/have to make your adjustment
            here\\r\\n-->\\r\\n    <xsl:template match=\\"RootElement\\">\\r\\n        <xsl:copy>\\r\\n
            \\           <NewTicketNotification>\\r\\n                <RocketChatAPIUrl>http://172.17.0.1:3000/api/v1/livechat/message</RocketChatAPIUrl>\\r\\n
            \\               <Message>The following ticket was created for this chat:\\\\n\%s</Message>\\r\\n
            \\           </NewTicketNotification>\\r\\n            <NewChat>\\r\\n               <Queue>\\r\\n
            \\                  <xsl:value-of select=\\"\$deptotrans\\" />\\r\\n               </Queue>\\r\\n
            \\              <State>new</State>\\r\\n               <Lock>unlock</Lock>\\r\\n
            \\              <Priority>3 normal</Priority>\\r\\n               <OwnerID>1</OwnerID>\\r\\n
            \\              <UserID>1</UserID>\\r\\n            </NewChat>\\r\\n            <ChatClosed>\\r\\n
            \\              <State>closed successful</State>\\r\\n               <Lock>unlock</Lock>\\r\\n
            \\           </ChatClosed>\\r\\n           <xsl:apply-templates select=\\"@*|node()\\"/>\\r\\n
            \\       </xsl:copy>\\r\\n    </xsl:template>\\r\\n    <xsl:template match=\\"content\\"
            />\\r\\n</xsl:stylesheet>"
        Type: XSLT
      MappingOutbound: {}
      Type: RocketChat::IncomingChat
  Transport:
    Config:
      KeepAlive: ''
      MaxLength: '999999999'
      RouteOperationMapping:
        Chat:
          RequestMethod:
          - GET
          - POST
          Route: /
    Type: HTTP::REST
RemoteSystem: ''
Requester:
  Transport:
    Type: ''

_END_

    my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => $YAML );

    # add new web service
    my $ID = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceAdd(
        Name    => $Name,
        Config  => $Config,
        ValidID => 1,
        UserID  => 1,
    );

    return 1;   
}
=back
1
