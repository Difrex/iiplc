package II::T;

use HTML::Template;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub head {
    my ( $self, $title ) = @_;
    my $t = HTML::Template->new( filename => 't/head.html' );

    $t->param( TITLE => $title );

    return $t->output;
}

sub echo {
    my ( $self, $echo ) = @_;

    my $e = HTML::Template->new( filename => 't/echo.html' );

    $e->param( ECHO => $echo );

    return $e->output();
}

sub index {
    my ( $self, $echoareas ) = @_;
    my $i = HTML::Template->new( filename => 't/index.html' );

    my $index = '<div class="echo">';
    while (<@$echoareas>) {
        $i->param( ECHO => $_ );
        $index .= $i->output();
    }
    $index .= '</div>';

    return $index;
}

sub tree {
    my ( $self, $data ) = @_;

    my $p = HTML::Template->new( filename => 't/tree.html' );

    my $time = localtime( $data->{time} );

    # my $post = II::T->pre( $data->{post} );
    my $link = $data->{subg};
    $link =~ s/\s/%20/g;

    $p->param( SUBG => "$data->{subg}" );
    $p->param( LINK => $link );
    $p->param( TIME => "$time" );
    $p->param( FROM => $data->{from} );

    # $p->param( TO   => $data->{to} );
    # $p->param( POST => $post );
    $p->param( ECHO => $data->{echo} );

    return $p->output();
}

sub out {
    my ( $self, $data ) = @_;

    my $p = HTML::Template->new( filename => 't/out.html' );

    my $post = II::T->pre( $data->{post} );

    $p->param( SUBG   => $data->{subg} );
    $p->param( TIME   => "$time" );
    $p->param( FROM   => $data->{from} );
    $p->param( TO     => $data->{to} );
    $p->param( POST   => $post );
    $p->param( ECHO   => $data->{echo} );
    $p->param( BASE64 => $data->{base64} );
    $p->param( HASH   => $data->{hash} );

    return $p->output();
}

sub post {
    my ( $self, $data ) = @_;

    my $p = HTML::Template->new( filename => 't/post.html' );

    my $time = localtime( $data->{time} );

    my $post = II::T->pre( $data->{post} );

    my $cut;
    if ( $data->{subg} =~ /Re:\s+(.+)/ ) {
        $cut = $1;
    }
    else {
        $cut = $data->{subg};
    }

    $p->param( SUBG => $data->{subg} );
    $p->param( CUT  => $cut );
    $p->param( TIME => "$time" );
    $p->param( FROM => $data->{from} );
    $p->param( TO   => $data->{to} );
    $p->param( POST => $post );
    $p->param( ECHO => $data->{echo} );
    $p->param( HASH => $data->{hash} );

    return $p->output();
}

sub new_mes {
    my ( $self, $echo ) = @_;

    my $n = HTML::Template->new( filename => 't/new.html' );
    $n->param( ECHO => $echo );

    return $n->output();
}

sub send {
    my ( $self, $data ) = @_;

    my $p = HTML::Template->new( filename => 't/send.html' );

    my $time = localtime( $data->{time} );

    my $post = II::T->pre( $data->{post} );

    $data->{subg} =~ s/Re:\s+(.+)/$1/g;

    $p->param( SUBG => $data->{subg} );
    $p->param( TIME => "$time" );
    $p->param( FROM => $data->{from} );
    $p->param( TO   => $data->{to} );
    $p->param( POST => $post );
    $p->param( ECHO => $data->{echo} );
    $p->param( HASH => $data->{hash} );

    return $p->output();
}

# Preparsing before input to SQL
sub in_pre {
    my ($self, $post) = @_;

    $post =~ s/'/\\'/g;
    $post =~ s/"/\\"/g;
    $post =~ s/'/\\'/g;
    $post =~ s/`/\\`/g;
    $post =~ s/\$/\\\$/g;

    return $post;
}

# Preparsing output
sub pre {
    my ( $self, $post ) = @_;

    $post =~ s/</&lt;/g;
    $post =~ s/>/&gt;/g;
    $post =~ s/&gt;(.+)/<font color='green'>>$1<\/font>/g;
    $post =~ s/--/&mdash;/g;
    $post =~ s/.?\*(.+)\*.?/<b>$1<\/b>/g;
    $post =~ s/^$/<br>\n/g;
    $post =~ s/(.?)\n/$1<br>\n/g;
    $post
        =~ s/(https?:\/\/.+\.(jpg|png|gif))/<a href="$1"><img src="$1" width="15%" height="15%" \/><\/a>/g;
    $post
        =~ s/(https?:\/\/.+\.(JPG|PNG|GIF))/<a href="$1"><img src="$1" width="15%" height="15%" \/><\/a>/g;
    # Not are regexp parsing
    my $pre = 0;
    my $txt;
    open my $fh, '<', \$post or die $!;
    while (<$fh>) {
        my $line = $_;
        if ( ( $line =~ /^====/ ) and ( $pre == 0 ) ) {
            # $txt .= $_;
            $line =~ s/====/<pre class="pre">/g;
            $pre = 1;
        }
        elsif ( ( $line =~ /^====/ ) and ( $pre == 1 ) ) {
            $line =~ s/====/<\/pre>\n/g;
            $pre = 0;
        }
        $txt .= $line;
    }
    close $fh;
    return $txt;
}

sub foot {
    my ($self) = @_;

    my $f = HTML::Template->new( filename => 't/foot.html' );

    return $f->output();
}

1;
