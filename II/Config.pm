package II::Config;

use Config::Tiny;

sub new {
    my $class = shift;

    my $self = { _file => 'config.ini', };

    bless $self, $class;
    return $self;
}

# Load configuration
sub load {
    my ($self) = @_;
    my $file = $self->{_file};
    
    my $tiny = Config::Tiny->new();
    $config = $tiny->read($file);
    
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

# Reload configuration
sub reload {
    my ($self) = @_;

    my $c = II::Config->new();
    my $config = $c->load();

    return $config;
}

1;
