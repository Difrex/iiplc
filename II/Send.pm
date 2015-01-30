package II::Send;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use II::DB;
use Data::Dumper;

sub new {
    my $class = shift;

    my $db   = II::DB->new();
    my $self = {
        _config => shift,
        _echo   => shift,
        _base64 => shift,
        _db     => $db,
    };

    bless $self, $class;
    return $self;
}

sub send {
    my ( $self, $hash ) = @_;
    my $config = $self->{_config};
    my $echo   = $self->{_echo};
    my $base64 = $self->{_base64};
    my $db     = $self->{_db};

    # Push message to server
    my $host = $config->{host};
    my $auth = $config->{key};
    $host .= "u/point";
    my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.0');
    my $response
        = $ua->post( $host, { 'pauth' => $auth, 'tmsg' => $base64 } );

    if ( $response->{_rc} == 200 ) {
        $db->update_out($hash);
    }
}

1;
