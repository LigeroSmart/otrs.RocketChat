# --
# Copyright (C) 2001-2018 Complemento, http://complemento.net.br/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::NotificationEvent::Transport::RocketChat;
## nofilter(TidyAll::Plugin::OTRS::Perl::LayoutObject)
## nofilter(TidyAll::Plugin::OTRS::Perl::ParamObject)

use strict;
use warnings;
use JSON::PP;

use LWP;
use HTTP::Request;
use XML::Simple;
use Encode qw(decode encode);
use MIME::Base64;
use Data::Dumper;
use utf8;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

use base qw(Kernel::System::Ticket::Event::NotificationEvent::Transport::Email);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::CustomerUser',
    'Kernel::System::Email',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Queue',
    'Kernel::System::SystemAddress',
    'Kernel::System::Ticket',
    'Kernel::System::User',
    'Kernel::System::Web::Request',
    'Kernel::System::Crypt::PGP',
    'Kernel::System::Crypt::SMIME',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
);

=head1 NAME

Kernel::System::Ticket::Event::NotificationEvent::Transport::SmsNotify - sms transport layer

=head1 SYNOPSIS

Notification event transport layer.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create a notification transport object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new('');
    my $TransportObject = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent::Transport::SmsNotify');

=cut

#sub new {
    #my ( $Type, %Param ) = @_;

    ## allocate new hash for object
    #my $Self = {};
    #bless( $Self, $Type );

    #return $Self;
#}

sub SendNotification {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID Notification Recipient)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need $Needed!',
            );
            return;
        }
    }

    # cleanup event data
    $Self->{EventData} = undef;

    # get needed objects
    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');


    my %Notification = %{ $Param{Notification} };

    return if !$Param{Notification}->{Data}->{RecipientWebhookURL};

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # send notification
    my $Sent = $Self->_ScheduleMessage(
                    Subject             => $Notification{Subject},
                    Body                => $Notification{Body},
                    RecipientWebhookURL => $Param{Notification}->{Data}->{RecipientWebhookURL}
                    );

    if ( !$Sent ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "'$Notification{Name}' notification could not be sent to Rocket.Chat",
        );
        return;
    }

    # log event
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'info',
        Message  => "Sent agent '$Notification{Name}' notification to Rocket.Chat.",
    );

    return 1;
}

sub GetTransportRecipients {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Notification)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed",
            );
        }
    }

    my @Recipients;

    my %Recipient;
    $Recipient{Type}        = 'Agent';
    $Recipient{WebhookURL}  = $Param{Notification}->{Data}->{RecipientWebhookURL};

    push @Recipients, \%Recipient;
    return @Recipients;
}

sub TransportSettingsDisplayGet {
    my ( $Self, %Param ) = @_;

    KEY:
    for my $Key (qw(RecipientWebhookURL)) {
        next KEY if !$Param{Data}->{$Key};
        next KEY if !defined $Param{Data}->{$Key}->[0];
        $Param{$Key} = $Param{Data}->{$Key}->[0];
    }

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    
    # generate HTML
    my $Output = $LayoutObject->Output(
        TemplateFile => 'AdminNotificationEventTransportRocketChat',
        Data         => \%Param,
    );

    return $Output;
}

sub TransportParamSettingsGet {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(GetParam)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed",
            );
        }
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    PARAMETER:
    for my $Parameter (
        qw(RecipientWebhookURL)
        )
    {
        my @Data = $ParamObject->GetArray( Param => $Parameter );
        next PARAMETER if !@Data;
        $Param{GetParam}->{Data}->{$Parameter} = \@Data;
    }

    # Note: Example how to set errors and use them
    # on the normal AdminNotificationEvent screen
    # # set error
    # $Param{GetParam}->{$Parameter.'ServerError'} = 'ServerError';

    return 1;
}

sub _ScheduleMessage {
    my ( $Self, %Param ) = @_;

	# For Asynchronous sending
	my $TaskName = substr "Recipient".rand().$Param{RecipientWebhookURL}, 0, 255;
	
	# create a new task
	my $TaskID = $Kernel::OM->Get('Kernel::System::Scheduler')->TaskAdd(
		Type                     => 'AsynchronousExecutor',
		Name                     => $TaskName,
		Attempts                 =>  1,
		MaximumParallelInstances =>  0,
		Data                     => {
			Object   => 'Kernel::System::Ticket::Event::NotificationEvent::Transport::RocketChat',
			Function => 'SendMessageRocketChat',
			Params   => {
						RecipientWebhookURL => $Param{RecipientWebhookURL},
						Subject             => $Param{Subject},
						Body                => $Param{Body},
					},
		},
	);
}

sub SendMessageRocketChat {
	my ( $Self, %Param ) = @_;

	# Convert Body to pure text
	$Param{Body} = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii( String => $Param{Body} );
	$Param{Body} = encode("utf8", $Param{Body});

	my $ua   = LWP::UserAgent->new;

	my %Data;
	$Data{text} = $Param{Subject} ."\n\n".$Param{Body};
	
	my $jsonData = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
        Data => \%Data,
    );

	$ua->default_header("Content-Type" => "application/json");
	$ua->default_header("Accept" => "application/json");

	my $response = $ua->post($Param{RecipientWebhookURL}->[0], Content_Type => 'application/json', Content => $jsonData);

	my $ResponseData = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => $response->decoded_content,
    );

	if(!$ResponseData->{success}){
		$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "Error on sending message to Rocket.Chat",
		);
		return 0;
	} else {
		return 1;
	}

}
1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
