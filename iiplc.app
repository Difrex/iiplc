#!/usr/bin/perl
# Copyright © 2014 Difrex <difrex.punk@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file for more details.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
use Plack::Response;

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

my $GET    = II::Get->new($config);
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
    my $msgs    = $GET->get_echo();
    my $new_mes = $render->new_mes($msgs);
    return [ 200, [ 'Content-type' => 'text/html' ], ["$new_mes"], ];
};

my $root = sub {
    my $index = $render->index($config);
    return [ 200, [ 'Content-type' => 'text/html' ], [$index], ];
};

my $me = sub {
    my $messages = $render->to_me($config);
    return [ 200, [ 'Content-type' => 'text/html' ], [$messages], ];
};

my $tree = sub {
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

    print Dumper($config);
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

builder {
    mount '/'     => $root;
    mount '/e'    => $echo;
    mount '/s'    => $thread;
    mount '/u'    => $user;
    mount '/me'   => $me;
    mount '/tree' => $tree;
    mount '/get/' => $get;
    mount '/send' => $send;
    mount '/enc'  => $enc;
    mount '/out'  => $out;
    mount '/push' => $push;
    mount '/new'  => $new;
};
