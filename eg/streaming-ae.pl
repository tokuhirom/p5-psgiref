use strict;
use warnings;
use PSGIRef::Impl::AnyEvent;

# Note: timer works forever!

my @timers;
PSGIRef::Impl::AnyEvent->new(
    port => 9979,
    psgi_app => sub {
        my ($env, $start_response) = @_;
        my $writer = $start_response->(200, {'X-Foo' => 'bar'});
        my $w; $w = AnyEvent->timer(
            after => 0,
            interval => 1,
            cb => sub {
                $writer->(time() . "\n");
            },
        );
        push @timers, $w;
        return [];
    },
)->run;

AnyEvent->condvar->recv;
