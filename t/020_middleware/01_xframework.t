use strict;
use warnings;
use PSGIRef::Impl::CGI;
use PSGIRef::Middleware::XFramework;
use Test::More;

my $handler = PSGIRef::Middleware::XFramework->new(
    framework => 'Dog',
    code => sub {
        [200, [], ['ok']]
    }
);
my $res = $handler->(+{});
is_deeply $res, [200, ['X-Framework' => 'Dog'], ['ok']];

done_testing;

