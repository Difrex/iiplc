package II::Render;

use II::DB;
use II::T;

use Data::Dumper;

sub new {
    my $class = shift;

    my $db = II::DB->new();
    my $t  = II::T->new();

    my $self = {
        _db       => $db,
        _template => $t,
    };

    bless $self, $class;
    return $self;
}

sub thread {
    my ( $self, $subg, $echo ) = @_;
    my $db = $self->{_db};
    my $t  = $self->{_template};

    my @post = $db->thread( $subg, $echo );

    # Render header
    my $render = $t->head("ii :: $echo");
    my $count  = 0;
    while ( $count < @post ) {
        $render .= $t->post( @post[$count] );
        $count++;
    }
    $render .= $t->foot();

    return $render;

}

sub out {
    my ($self) = @_;
    my $db     = $self->{_db};
    my $t      = $self->{_template};

    my @post = $db->select_out();

    # Render header
    my $render
        = $t->head('ii :: неотправленные сообщения');

    my $count = 0;
    while ( $count < @post ) {

        # Render post
        $render .= $t->out( @post[$count] );

        $count++;
    }
    $render .= $t->foot();
}

sub echo_mes {
    my ( $self, $echo, $view ) = @_;
    my $db = $self->{_db};
    my $t  = $self->{_template};

    my @post = $db->echoes($echo);

    # Render header
    my $render = $t->head("ii :: $echo");
    $render .= $t->echo($echo);

    my $count = 0;
    if ( $view eq 'thread' ) {
        while ( $count < @post ) {

            # Render post
            if ( !( @post[$count]->{subg} =~ /Re.+/ ) ) {
                $render .= $t->tree( @post[$count] );
            }

            $count++;
        }
    }
    else {
        while ( $count < @post ) {
            $render .= $t->post( @post[$count] );
            $count++;
        }
    }
    $render .= $t->foot();

    return $render;

}

sub to_me {
    my ( $self, $config ) = @_;
    my $db = $self->{_db};
    my $t  = $self->{_template};

    my @post         = $db->to_me($config);
    my @post_from_me = $db->from_me($config);

    # Render header
    my $render = $t->head('ii :: Моя переписка');

    my $count = 0;
    while ( $count < @post ) {

        # Render post
        $render .= $t->post( @post[$count] );

        $count++;
    }
    $render .= $t->foot();

    return $render;
}

sub tree {
    my ( $self, $config ) = @_;
    my $db = $self->{_db};
}

# Render index page
sub index {
    my ( $self, $config ) = @_;
    my $db        = $self->{_db};
    my $echoareas = $config->{echoareas};
    my $t         = $self->{_template};

    my @hashes = $db->select_index(50);

    # Render header
    my $render = $t->head('ii :: Лента');
    $render .= $t->index($echoareas);

    while (<@hashes>) {
        my $message = $_;
        my $data    = $db->select_new($message);

        # Render post
        $render .= $t->post($data);
    }
    $render .= $t->foot();

    return $render;
}

# Messages from user
sub user {
    my ( $self, $user ) = @_;
    my $db = $self->{_db};
    my $t  = $self->{_template};

    # Render header
    my $render
        = $t->head("ii :: Сообщения пользователя $user");

    my @post = $db->select_user($user);

    my $count = 0;
    while ( $count < @post ) {

        # Render post
        $render .= $t->post( @post[$count] );
        $count++;
    }
    $render .= $t->foot();

}

# Render new message form
sub send_new {
    my ( $self, $echo ) = @_;
    my $t = $self->{_template};

    my $render = $t->head("ii :: Новое сообщение");

    $render .= $t->new_mes($echo);
    $render .= $t->foot();

    return $render;
}

# Render send form
sub send {
    my ( $self, $hash ) = @_;
    my $db = $self->{_db};
    my $t  = $self->{_template};

    my $render = $t->head("ii :: Ответ на $hash");

    # Render post
    my $data = $db->select_new($hash);

    $render .= $t->send($data);
    $render .= $t->foot();

    return $render;
}

# Render new messages
sub new_mes {
    my ( $self, $msgs ) = @_;
    my $db = $self->{_db};
    my $t  = $self->{_template};

    my $render = $t->head('ii :: Новые сообщения');

    # Render posts
    if ( defined($msgs) ) {
        my @msgs_list = split /\n/, $msgs;
        while (<@msgs_list>) {
            my $message = $_;
            my $data    = $db->select_new($message);

            # Render post
            $render .= $t->post($data);
        }
    }

    # else {
    #     $render .= "<p>Новых сообщений нет</p>";
    # }
    $render .= $t->foot();

    return $render;
}

1;
