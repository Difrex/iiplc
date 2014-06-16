package II::Get;
use LWP::Simple;

use II::DB;
use II::Enc;

use Data::Dumper;

sub new {
    my $class = shift;

    my $self = { _config => shift, };

    bless $self, $class;
    return $self;
}

sub get_echo {
    my ($self)    = @_;
    my $config    = $self->{_config};
    my $echoareas = $config->{echoareas};
    my $host      = $config->{host};

    my $db = II::DB->new();

    my $echo_url = 'u/e/';
    my $msg_url  = 'u/m/';

    my $msgs;
    foreach my $echo (@$echoareas) {
        # my @content = get( "$host" . "$echo_url" . "$echo" );
        my @content = `curl $host$echo_url$echo`;

        # if ( is_success( getprint( "$host" . "$echo_url" . "$echo" ) ) ) {

        # Write echoes file
        open my $echo_fh, ">", "./echo/$echo"
            or die "Cannot open file: $!\n";
        print $echo_fh @content;
        close $echo_fh;

        # Get messages
        open my $echo_fh, "<", "./echo/$echo"
            or die "Cannot open file: $!\n";
        while (<$echo_fh>) {
            chomp($_);
            if ($_ =~ /.{20}/) { 
                if ( !( -e "./msg/$_" ) ) {
                    $msgs .= $_ . "\n";
                    # @w_cmd = ( 'wget', '-O',
                    #     "./msg/$_", "$host" . "$msg_url" . "$_" );
                    `curl $host$msg_url$_ > ./msg/$_`;
                    # system(@w_cmd) == 0 or die "Cannot download file: $!\n";
                }
            }
        }
        close $echo_fh;

        # }
    }

    my $new_messages
        = "<!DOCTYPE html><meta charset=utf8><body><h1>Новые сообщения</h1>\n";
    if ( defined($msgs) ) {
        my @msg_list = split /\n/, $msgs;

        # Begin transaction
        print "Writing messages\n";
        $db->begin();
        while (<@msg_list>) {
            my $mes_hash = $_;

            my $text = II::Enc->decrypt("./msg/$mes_hash");

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
        }
        # Commit transaction
        $db->commit();
        print "Messages writed to DB!\n";
    }
    return $msgs;
}

1;
