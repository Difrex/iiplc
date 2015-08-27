package II::T;

use HTML::Template;
use HTML::FromText ();
use Encode;
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
    my ( $self, $post ) = @_;

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

    my $t2h = HTML::FromText->new(
        {   paras     => 1,
            bullets   => 1,
            lines     => 1,
            blockcode => 1,
            tables    => 0,
            numbers   => 0,
            urls      => 0,
            email     => 1,
            bold      => 1,
            underline => 1,
        }
    );

    $post = $t2h->parse( decode_utf8($post) );
    $post =~ s/&gt;(.+)/<font color='green'>>$1<\/font>/g;
    $post =~ s/--/&mdash;/g;

    # Lists
    $post =~ s/\*(.+)/<li>$1<\/li>/g;

    # Images
    $post
        =~ s/\[img (.+)\]/<a href="$1"><img src="$1" width="15%" height="15%" \/><\/a>/g;

    # ii uri
    $post =~ s/ii:\/\/(\w+(\.)?\w+\.\d{2,4})/<a href="\/e?echo=$1&view=thread">$1<\/a>/g;
    $post =~ s/ii:\/\/(\w{20})/<a href="\/send?hash=$1">$1<\/a>/g;

    # Users
    $post =~ s/.+? \@(\w+)(.?.+)/<a href="\/u?user=$1">$1<\/a>$2/g;

    # Not are regexp parsing
    my $pre = 0;
    my $txt;
    open my $fh, '<', \$post or die $!;
    while (<$fh>) {
        my $line = $_;
        if ( ( $line =~ /^====/ ) and ( $pre == 0 ) ) {

            $line =~ s/====/<pre class="pre">/g;
            $pre = 1;
        }
        elsif ( ( $line =~ /^====/ ) and ( $pre == 1 ) ) {
            $line =~ s/====/<\/pre>\n/g;
            $pre = 0;
        }
        $txt .= $line;
        $txt =~ s/<br \/>//g if $pre == 1;
        $txt =~ s/<li>//g if $pre == 1;
        $txt =~ s/<\/li>//g if $pre == 1;
        $txt =~ s/<font.+>(>.+)<\/font>/$1/g if $pre == 1;
    }
    close $fh;

    return $txt;
}

# All messages footer
sub all {
    my ( $self, $echo ) = @_;

    my $a = HTML::Template->new( filename => 't/all.html' );
    $a->param( ECHO => $echo );

    return $a->output();
}

# Footer
sub foot {
    my ($self) = @_;

    my $f = HTML::Template->new( filename => 't/foot.html' );

    return $f->output();
}

1;
