use strict;
use warnings;
use PSGIRef::Impl::AnyEvent;

# Note: timer works forever!

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
                $writer->(time() . "\n");
            },
        );
        return [];
    },
)->run;

AnyEvent->condvar->recv;
