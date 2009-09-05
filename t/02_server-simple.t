use strict;
use warnings;
use Test::More;
use PSGIRef;
use PSGIRef::Impl::ServerSimple;
use Test::TCP;
use LWP::UserAgent;
use PSGIRef::Test;

PSGIRef::Test->runtests(\&run_one);
done_testing();

sub run_one {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;

    test_tcp(
        client => sub {
            my $port = shift;

            my $ua = LWP::UserAgent->new();
            my $res = $ua->request($reqgen->($port));
            $test->($res, $port);
        },
        server => sub {
            my $port = shift;

            my $server = PSGIRef::Impl::ServerSimple->new(port => $port, address => '127.0.0.1');
            $server->run($handler);
        },
    );
}


