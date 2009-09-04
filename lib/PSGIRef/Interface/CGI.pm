package PSGIRef::Interface::CGI;
use strict;
use warnings;

sub run {
    my $handler = shift;
    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|SCRIPT_NAME|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT|HTTP_)$/;
        $env{$k} = $v;
    }
    $env{'psgi.version'} = [1,0];
    $env{'psgi.url_scheme'} = $ENV{SSL} ? 1 : 0;
    $env{'psgi.input'} = *STDIN;
    $env{'psgi.errors'} = *STDERR;
    $handler->(%env);
}

1;
__END__

=head1 SYNOPSIS

    use PSGIRef::Interface::CGI;
    PSGIRef::Interface::CGI->run(sub {
        my $env = shift;
        return [
            200,
            { 'Content-Type' => 'text/plain', 'Content-Length' => 13 },
            'Hello, world!',
        ];
    });

