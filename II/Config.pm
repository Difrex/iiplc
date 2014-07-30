package II::Config;

use Config::Tiny;

sub new {
    my $class = shift;

    my $c = Config::Tiny->new();
    $c = Config::Tiny->read('config.ini');

    my $self = { _config => $c, };

    bless $self, $class;
    return $self;
}

sub load {
    my ($self) = @_;
    my $config = $self->{_config};

    my $key       = $config->{auth}->{key};
    my $nick      = $config->{auth}->{nick};
    my $host      = $config->{node}->{host};
    my @echoareas = split /,/, $config->{node}->{echoareas};
    my $name      = $config->{node}->{name};

    $c = {
        nick      => $nick,
        key       => $key,
        host      => $host,
        echoareas => [@echoareas],
        name      => $name,
    };

    return $c;
}

1;
