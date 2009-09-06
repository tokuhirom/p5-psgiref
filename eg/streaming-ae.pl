use strict;
use warnings;
use PSGIRef::Impl::AnyEvent;

PSGIRef::Impl::AnyEvent->new(
    port => 9979,
    psgi_app => sub {
        my ($env, $start_response) = @_;
        my $writer = $start_response->(200, {'X-Foo' => 'bar'});
        my $w; $w = AnyEvent->timer(
            after => 0,
            interval => 1,
            cb => sub {
                scalar $w; # mention
                $writer->print(time() . "\n");
            },
        );

        my $close_w; $close_w = AnyEvent->timer(
            after => 5,
            cb => sub {
                scalar $close_w;
                $writer->print("DONE\n");
                $writer->close;
            },
        );

        return [];
    },
)->run;

warn "http://localhost:9979/\n";

AnyEvent->condvar->recv;
