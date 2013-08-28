use strict;
use Test::More;
use Plack::Test;
use Voson::Core;
use HTTP::Request::Common;
use Digest::SHA1 qw(sha1_hex);

my $v = Voson::Core->new(
    plugins => ['SocketIO'],
    app => sub { [200, [], ['<html><body>Hello!</body></html>']] },
);

my $app = $v->run;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is $res->content, '<html><body>Hello!</body>'."\n".'<script type="text/javascript" src="/socket.io.js"></script></html>';
};

done_testing;
