use strict;
use warnings;
use Test::More;
use HTTP::Request::AsCGI;
use_ok('PSGIRef');
use_ok('PSGIRef::Impl::CGI');
use PSGIRef::Test;
use PSGIRef::Middleware::Lint;

PSGIRef::Test->runtests(sub {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    my $c = HTTP::Request::AsCGI->new($reqgen->())->setup;
    PSGIRef::Impl::CGI->run(PSGIRef::Middleware::Lint->new(code => $handler));
    $test->($c->response);
});

done_testing;
