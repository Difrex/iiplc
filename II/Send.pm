package II::Send;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use II::DB;
use Data::Dumper;

sub new {
    my $class = shift;

    my $self = {
        _config => shift,
        _echo   => shift,
        _base64 => shift,
    };

    bless $self, $class;
    return $self;
}

sub send {
    my ($self, $hash) = @_;
    my $config = $self->{_config};
    my $echo   = $self->{_echo};
    my $base64 = $self->{_base64};

    # Push message to server
    my $host = $config->{host};
    my $auth = $config->{key};
    $host .= "u/point";
    my $ua = LWP::UserAgent->new();
    my $response = $ua->post( $host, { 'pauth' => $auth, 'tmsg' => $base64 } );
    print Dumper($response);

    my $db = II::DB->new();
    if ($response->{_rc} == 200) {
    	$db->update_out($hash);
	}
}

1;
