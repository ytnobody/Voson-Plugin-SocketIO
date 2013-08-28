use strict;
use Test::More;
use Plack::Test;
use Voson::Core;
use HTTP::Request::Common;
use Digest::SHA1 qw(sha1_hex);

my $v = Voson::Core->new(
    plugins => ['SocketIO'],
    app => sub { [200, [], ['Hello!']] },
);

my $app = $v->run;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is $res->content, 'Hello!';

    $res = $cb->(GET '/socket.io.js');
    is sha1_hex($res->content), 'f1dbe9d3ad24237ac28dbc05634673efc587f55a';
};

done_testing;
