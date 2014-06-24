package II::DB;

use SQL::Abstract;
use DBI;

use Data::Dumper;

sub new {
    my $class = shift;

    my $dbh = DBI->connect( "dbi:SQLite:dbname=ii.sql", "", "" );
    my $sql = SQL::Abstract->new();

    my $self = {
        _dbh => $dbh,
        _sql => $sql,
    };

    bless $self, $class;
    return $self;
}

sub check_hash {
    my ( $self, $hash, $echo ) = @_;
    my $dbh = $self->{_dbh};

    my $q   = "select hash from echo where hash='$hash' and echo='$echo'";
    my $sth = $dbh->prepare($q);
    $sth->execute();

    while ( my @h = $sth->fetchrow_array() ) {
        my ($base_hash) = @h;
        if ( $hash eq $base_hash ) {
            return 1;
        }
        else {
            return 0;
        }
    }
}

sub begin {
    my ($self) = @_;
    my $dbh = $self->{_dbh};

    # Begin transaction
    $dbh->do('BEGIN');
}

sub commit {
    my ($self) = @_;
    my $dbh = $self->{_dbh};

    # Commmit transaction
    $dbh->do('COMMIT');
}

sub write_echo {
    my ( $self, %data ) = @_;
    my $dbh = $self->{_dbh};
    my $sql = $self->{_sql};

    my ( $stmt, @bind ) = $sql->insert( 'echo', \%data );

    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);
    $sth->finish();
}

sub write_out {
    my ( $self, %data ) = @_;
    my $dbh = $self->{_dbh};
    my $sql = $self->{_sql};

    my ( $stmt, @bind ) = $sql->insert( 'output', \%data );

    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);

    print "Message writed to DB!\n";
}

sub update_out {
    my ( $self, $hash ) = @_;
    my $dbh = $self->{_dbh};

    my $q   = "update output set send=1 where hash='$hash'";
    my $sth = $dbh->prepare($q);
    $sth->execute();
}

sub write {
    my ( $self, %data ) = @_;
    my $dbh = $self->{_dbh};
    my $sql = $self->{_sql};

    my ( $stmt, @bind ) = $sql->insert( 'messages', \%data );

    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);
    $sth->finish();
}

sub select_out {
    my ($self) = @_;
    my $dbh = $self->{_dbh};

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash, base64 from output where send=0";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @posts;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ( $from, $to, $subg, $time, $echo, $post, $h, $base64 ) = @hash;
        my $data = {
            from   => "$from",
            to     => "$to",
            subg   => "$subg",
            time   => $time,
            echo   => "$echo",
            post   => "$post",
            hash   => $h,
            base64 => $base64,
        };
        push( @posts, $data );
    }

    return @posts;
}

sub select_index {
    my ( $self, $limit ) = @_;
    my $dbh = $self->{_dbh};

    my $q = "select hash from messages order by time desc limit $limit";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @hashes;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ($h) = @hash;
        push( @hashes, $h );
    }

    return @hashes;
}

sub select_subg {
    my ( $self, $echo ) = @_;

}

# Select user messages
sub select_user {
    my ( $self, $user ) = @_;
    my $dbh = $self->{_dbh};

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash from messages where from_user='$user' order by time desc";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @posts;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ( $from, $to, $subg, $time, $echo, $post, $h ) = @hash;
        my $data = {
            from => "$from",
            to   => "$to",
            subg => "$subg",
            time => $time,
            echo => "$echo",
            post => "$post",
            hash => $h,
        };
        push( @posts, $data );
    }

    return @posts;
}

sub from_me {
    my ( $self, $config ) = @_;
    my $dbh  = $self->{_dbh};
    my $nick = $config->{nick};

    # print Dumper($config);
    # print "NICK: $nick\n";

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash from messages where from_user='$nick'";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @posts;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ( $from, $to, $subg, $time, $echo, $post, $h ) = @hash;
        my $data = {
            from => "$from",
            to   => "$to",
            subg => "$subg",
            time => $time,
            echo => "$echo",
            post => "$post",
            hash => $h,
        };
        push( @posts, $data );
    }

    return @posts;
}

sub thread {
    my ( $self, $subg, $echo ) = @_;
    my $dbh = $self->{_dbh};

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash from messages where echo='$echo' and subg like '%$subg%' order by time";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @posts;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ( $from, $to, $subg, $time, $echo, $post, $h ) = @hash;
        my $data = {
            from => "$from",
            to   => "$to",
            subg => "$subg",
            time => $time,
            echo => "$echo",
            post => "$post",
            hash => $h,
        };
        push( @posts, $data );
    }

    return @posts;
}

sub echoes {
    my ( $self, $echo ) = @_;
    my $dbh = $self->{_dbh};

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash from messages where echo='$echo' order by time desc";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @posts;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ( $from, $to, $subg, $time, $echo, $post, $h ) = @hash;
        my $data = {
            from => "$from",
            to   => "$to",
            subg => "$subg",
            time => $time,
            echo => "$echo",
            post => "$post",
            h    => $h,
        };
        push( @posts, $data );
    }

    return @posts;
}

sub to_me {
    my ( $self, $config ) = @_;
    my $dbh  = $self->{_dbh};
    my $nick = $config->{nick};

    # print Dumper($config);
    # print "NICK: $nick\n";

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash from messages where to_user='$nick'";

    my $sth = $dbh->prepare($q);
    $sth->execute();

    my @posts;
    while ( my @hash = $sth->fetchrow_array() ) {
        my ( $from, $to, $subg, $time, $echo, $post, $h ) = @hash;
        my $data = {
            from => "$from",
            to   => "$to",
            subg => "$subg",
            time => $time,
            echo => "$echo",
            post => "$post",
            hash => "$h",
        };
        push( @posts, $data );
    }

    return @posts;
}

sub select_new {
    my ( $self, $msg ) = @_;
    my $dbh = $self->{_dbh};

    my $q
        = "select from_user, to_user, subg, time, echo, post, hash from messages where hash='$msg'";

    my $sth = $dbh->prepare($q);
    $sth->execute();
    my ( $from, $to, $subg, $time, $echo, $post );

    while ( my @hash = $sth->fetchrow_array() ) {
        ( $from, $to, $subg, $time, $echo, $post, $h ) = @hash;
    }

    my $data = {
        from => "$from",
        to   => "$to",
        subg => "$subg",
        time => $time,
        echo => "$echo",
        post => "$post",
        hash => "$h",
    };

    return $data;
}

1;
