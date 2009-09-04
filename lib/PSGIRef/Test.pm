package PSGIRef::Test;
use strict;
use warnings;
use HTTP::Request;
use PSGIRef::Request;
use Test::More;
use HTTP::Request::Common;

# 0: test name
# 1: request generator coderef.
# 2: request handler
# 3: test case for response
my @TEST = (
    [
        'GET',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(GET => "http://127.0.0.1:$port/?name=miyagawa");
        },
        sub {
            my $req = PSGIRef::Request->new( $_[0] );
            return [
                200,
                { 'Content-Type' => 'text/plain', },
                'Hello, ' . $req->param('name'),
            ];
        },
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, miyagawa';
        }
    ],
    [
        'POST',
        sub {
            my $port = shift || 80;
            POST("http://127.0.0.1:$port/", [name => 'tatsuhiko']);
        },
        sub {
            my $req = PSGIRef::Request->new( $_[0] );
            return [
                200,
                { 'Content-Type' => 'text/plain', },
                'Hello, ' . $req->param('name'),
            ];
        },
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, tatsuhiko';
        }
    ],
    [
        'psgi.url_scheme',
        sub {
            my $port = shift || 80;
            POST("http://127.0.0.1:$port/");
        },
        sub {
            my $env = $_[0];
            return [
                200,
                { 'Content-Type' => 'text/plain', },
                $env->{'psgi.url_scheme'},
            ];
        },
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'http';
        }
    ],
);

sub count { scalar @TEST }

sub get_test {
    my ($class, $number) = @_;
    return @{ $TEST[$number] };
}

1;
__END__

=head1 SYNOPSIS

    my ($name, $handler, $response) = PSGIRef::Test->get_test(0);

=head1 DESCRIPTION

Test suite for the PSGI spec. This will rename to the PSGI::TestSuite or something.

