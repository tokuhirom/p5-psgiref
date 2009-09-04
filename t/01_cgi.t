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
use PSGIRef::Test;

for my $i (0..PSGIRef::Test->count()-1) {
    my ($name, $reqgen, $handler, $test) = PSGIRef::Test->get_test($i);
    note $name;
    my $c = HTTP::Request::AsCGI->new($reqgen->())->setup;
    PSGIRef::Interface::CGI->run($handler);
    $test->($c->response);
}

done_testing;
