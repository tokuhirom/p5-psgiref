use strict;
use warnings;
use Test::More;
use HTTP::Request::AsCGI;
use HTTP::Request;
use HTTP::Headers::Fast;
use_ok('PSGIRef');
use_ok('PSGIRef::Request');
use_ok('PSGIRef::Response');
use_ok('PSGIRef::Interface::CGI');

my $req = HTTP::Request->new(GET => '/?name=miyagawa');
my $c = HTTP::Request::AsCGI->new($req)->setup;
PSGIRef::Interface::CGI->run(
    sub {
        my $req = PSGIRef::Request->new($_[0]);
        return PSGIRef::Response->new(
            status  => 200,
            headers => HTTP::Headers->new( content_type => 'text/plain', ),
            body    => 'Hello, ' . $req->param('name'),
        );
    },
);
my $res = $c->response;
is $res->code, 200;
is $res->header('content_type'), 'text/plain';
is $res->content, 'Hello, miyagawa';

done_testing;
