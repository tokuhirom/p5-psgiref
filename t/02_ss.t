use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Headers::Fast;
use HTTP::Request::Common;
use PSGIRef;
use PSGIRef::Request;
use PSGIRef::Response;
use PSGIRef::Interface::ServerSimple;
use Test::TCP;
use LWP::UserAgent;

test_tcp(
    client => sub {
        my $port = shift;

        my $ua = LWP::UserAgent->new();
        my $res = $ua->request(POST "http://127.0.0.1:$port/", [name => 'tatsuhiko']);
        is $res->code, 200;
        is $res->header('content_type'), 'text/plain';
        is $res->content, 'Hello, tatsuhiko';
        done_testing;
    },
    server => sub {
        my $port = shift;

        my $server = PSGIRef::Interface::ServerSimple->new(port => $port, address => '127.0.0.1');
        $server->run(
            sub {
                my $req = PSGIRef::Request->new($_[0]);
                return PSGIRef::Response->new(
                    status  => 200,
                    headers => HTTP::Headers->new( content_type => 'text/plain', ),
                    body    => 'Hello, ' . $req->param('name'),
                );
            },
        );
    },
);

