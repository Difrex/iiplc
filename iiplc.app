#!/usr/bin/perl
# Copyright © 2014 Difrex <difrex.punk@gmail.com>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
use Plack::Response;

# Static files
use Plack::App::File;

use II::Config;
use II::Get;
use II::Send;
use II::Render;
use II::DB;
use II::Enc;

# Debug
use Data::Dumper;

my $c      = II::Config->new();
my $config = $c->load();

my $render = II::Render->new();

my $echo = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);

    my $echo = $req->param('echo');
    my $view = $req->param('view');

    my $echo_messages = $render->echo_mes( $echo, $view );

    return [ 200, [ 'Content-type' => 'text/html' ], ["$echo_messages"], ];
};

my $thread = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);

    my $subg = $req->param('subg');
    my $echo = $req->param('echo');

    my $thread = $render->thread( $subg, $echo );

    return [ 200, [ 'Content-type' => 'text/html' ], ["$thread"], ];
};

my $get = sub {
    $config = $c->reload();
    my $GET     = II::Get->new($config);
    my $msgs    = $GET->get_echo();
    my $new_mes = $render->new_mes($msgs);
    return [ 200, [ 'Content-type' => 'text/html' ], ["$new_mes"], ];
};

my $root = sub {
    $config = $c->reload();
    my $index = $render->index($config);
    return [ 200, [ 'Content-type' => 'text/html' ], [$index], ];
};

my $me = sub {
    $config = $c->reload();
    my $messages = $render->to_me($config);
    return [ 200, [ 'Content-type' => 'text/html' ], [$messages], ];
};

my $tree = sub {
    $config = $c->reload();
    my $subges = $render->tree($config);
    return [ 200, [ 'Content-type' => 'text/html' ], ['Дерево'], ];
};

my $new = sub {
    my $env = shift;

    my $req  = Plack::Request->new($env);
    my $echo = $req->param('echo');

    my $send = $render->send_new($echo);
    return [ 200, [ 'Content-type' => 'text/html' ], [$send], ];
};

my $send = sub {
    my $env = shift;

    my $req  = Plack::Request->new($env);
    my $hash = $req->param('hash');
    my $send = $render->send($hash);

    return [ 200, [ 'Content-type' => 'text/html' ], [$send], ];
};

my $enc = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);

    # Get parameters
    my $echo = $req->param('echo');
    my $to   = $req->param('to');
    my $post = $req->param('post');
    my $subg = $req->param('subg');
    my $hash = $req->param('hash');
    my $time = time();

    $config = $c->reload();
    my $data = {
        echo => $echo,
        to   => $to,
        from => $config->{nick},
        subg => $subg,
        post => $post,
        time => $time,
        hash => $hash,
    };

    my $enc = II::Enc->new( $config, $data );
    $enc->encode() == 0 or die "$!\n";

    return [ 302, [ 'Location' => '/out' ], [], ];
};

my $out = sub {
    my $out = $render->out();

    return [ 200, [ 'Content-type' => 'text/html' ], [$out], ];
};

# Push message to server
my $push = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);

    my $echo   = $req->param('echo');
    my $base64 = $req->param('base64');
    my $hash   = $req->param('hash');

    $config = $c->reload();
    my $s = II::Send->new( $config, $echo, $base64 );
    $s->send($hash);

    my $db = II::DB->new();
    $db->update_out($hash);

    return [ 302, [ 'Location' => "/e?echo=$echo" ], [], ];
};

# Messages from user
my $user = sub {
    my $env = shift;

    my $req      = Plack::Request->new($env);
    my $user     = $req->param('user');
    my $mes_from = $render->user($user);

    return [ 200, [ 'Content-type' => 'text/html' ], [$mes_from], ];
};

# Search
########
my $search = sub {
    my $env = shift;

    my $req   = Plack::Request->new($env);
    my $query = $req->param('q');

    my $db     = II::DB->new();
    my @post = $db->do_search($query);

    my $result = $render->search(@post);

    return [ 200, [ 'Content-type' => 'text/html' ], [$result], ];
};

# Mountpoints
builder {
    mount "/static" => Plack::App::File->new( root => './s/' )->to_app;
    mount "/search" => $search;
    mount '/'       => $root;
    mount '/e'      => $echo;
    mount '/s'      => $thread;
    mount '/u'      => $user;
    mount '/me'     => $me;
    mount '/tree'   => $tree;
    mount '/get'    => $get;
    mount '/send'   => $send;
    mount '/enc'    => $enc;
    mount '/out'    => $out;
    mount '/push'   => $push;
    mount '/new'    => $new;
};
