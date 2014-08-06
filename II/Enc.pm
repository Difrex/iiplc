package II::Enc;

use II::DB;
use MIME::Base64;

sub new {
    my $class = shift;

    my $db = II::DB->new();

    my $self = {
        _config => shift,
        _data   => shift,
        _db     => $db,
    };

    bless $self, $class;
    return $self;
}

sub decrypt {
    my ( $self, $base64 ) = @_;

    return decode_base64($base64);
}

sub encode {
    my ($self) = @_;
    my $config = $self->{_config};
    my $data   = $self->{_data};
    my $db     = $self->{_db};
    my $hash   = II::Enc->new_hash();

    # Make base64 message
    my $message = $data->{echo} . "\n";
    $message .= $data->{to} . "\n";
    $message .= $data->{subg} . "\n\n";
    $message .= '@repto:' . $data->{hash} . "\n" if defined( $data->{hash} );
    $message .= $data->{post};

    # my $encoded = `echo "$message" | base64`;
    my $encoded = encode_base64($message);
    $encoded =~ s/\//_/g;
    $encoded =~ s/\+/-/g;

    # Preparsing
    my $post = II::T->in_pre($data->{post});

    # Make data
    my %out = (
        hash      => $hash,
        time      => $data->{time},
        echo      => $data->{echo},
        from_user => $data->{from},
        to_user   => $data->{to},
        subg      => $data->{subg},
        post      => $post,
        base64    => $encoded,
        send      => 0,
    );

    $db->write_out(%out);

    return 0;
}

sub new_hash {
    my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
    my $string;
    $string .= $chars[ rand @chars ] for 1 .. 21;

    return $string;
}

1;
