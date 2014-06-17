package II::Get;
use LWP::UserAgent;
use HTTP::Request;

use II::DB;
use II::Enc;

use Data::Dumper;

sub new {
    my $class = shift;

    my $ua = LWP::UserAgent->new();
    $ua->agent("iiplc/0.1rc1");
    my $db   = II::DB->new();
    my $self = {
        _config => shift,
        _ua     => $ua,
        _db     => $db,
    };

    bless $self, $class;
    return $self;
}

sub get_echo {
    my ($self)    = @_;
    my $config    = $self->{_config};
    my $echoareas = $config->{echoareas};
    my $host      = $config->{host};
    my $ua        = $self->{_ua};
    my $db        = $self->{_db};

    my $echo_url = 'u/e/';
    my $msg_url  = 'u/m/';

    my $msgs;
    my $base64;
    my @messages_hash;
    foreach my $echo (@$echoareas) {

        # Get echo message hashes
        my $req_echo = HTTP::Request->new( GET => "$host$echo_url$echo" );
        my $res_echo = $ua->request($req_echo);

        my @new;
        $db->begin();
        if ( $res_echo->is_success ) {
            my @mes = split /\n/, $res_echo->content();
            while (<@mes>) {
                if ( $_ =~ /.{20}/ ) {
                    if ( $db->check_hash( $_, $echo ) == 0 ) {
                        my $echo_hash = {
                            echo => $echo,
                            hash => $_,
                        };
                        my %e_write = (
                            echo => $echo,
                            hash => $_,
                        );

                        # Write new echo message
                        $db->write_echo(%e_write);
                        $msgs .= $_ . "\n";
                        push( @new, $echo_hash );
                    }
                }
            }
        }
        else {
            print $res->status_line, "\n";
        }
        $db->commit();

        # Get messages
        my @msg_con;
        my $count = 0;
        while ( $count < @new ) {
            my $new_messages_url = "$host$msg_url" . $new[$count]->{hash};
            my $req_msg = HTTP::Request->new( GET => $new_messages_url );
            my $res_msg = $ua->request($req_msg);
            if ( $res_msg->is_success() ) {
                push( @msg_con, $res_msg->content() );
            }
            else {
                print $res->status_line, "\n";
            }
            $count++;
        }

        # Populate hash
        while (<@msg_con>) {
            my @message = split /:/, $_;
            if ( defined( $message[1] ) ) {
                my $h = {
                    hash   => $message[0],
                    base64 => $message[1],
                };
                push( @messages_hash, $h );
            }
        }
    }

    my $new_messages
        = "<!DOCTYPE html><meta charset=utf8><body><h1>Новые сообщения</h1>\n";
    if ( defined($msgs) ) {

        # Begin transaction
        print localtime() . ": writing messages\n";
        $db->begin();

        my $c = 0;
        while ( $c < @messages_hash ) {
            my $mes_hash = $messages_hash[$c]->{hash};
            my $text = II::Enc->decrypt( $messages_hash[$c]->{base64} );

            open my $m, "<", \$text
                or die "Cannot open message: $!\n";

            my @mes;
            while (<$m>) {
                push( @mes, $_ );
            }
            close $m;

            my $count = 7;
            my $post;
            while ( $count < @mes ) {
                $post .= $mes[$count];
                $count++;
            }

            chomp( $mes[2] );
            chomp( $mes[1] );
            chomp( $mes[3] );
            chomp( $mes[5] );
            chomp( $mes[6] );

            # Make data
            my %data = (
                hash      => $mes_hash,
                time      => $mes[2],
                echo      => $mes[1],
                from_user => $mes[3],
                to_user   => $mes[5],
                subg      => $mes[6],
                post      => "$post",
                read      => 0,
            );

            # Write message to DB
            $db->write(%data);
            $c++;
        }

        # Commit transaction
        $db->commit();
        print localtime() . ": messages writed to DB!\n";
    }
    return $msgs;
}

1;
