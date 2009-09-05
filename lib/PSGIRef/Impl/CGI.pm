package PSGIRef::Impl::CGI;
use strict;
use warnings;
use IO::Handle;
use PSGI::Util;

sub run {
    my ($class, $handler) = @_;
    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|SCRIPT_NAME|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT)$|^HTTP_/;
        $env{$k} = $v;
    }
    $env{'HTTP_CONTENT_LENGTH'} = $ENV{CONTENT_LENGTH};
    $env{'HTTP_CONTENT_TYPE'}   = $ENV{CONTENT_TYPE};
    $env{'HTTP_COOKIE'}       ||= $ENV{COOKIE};
    $env{'psgi.version'} = [ 1, 0 ];
    $env{'psgi.url_scheme'} = ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http';
    $env{'psgi.input'}      = *STDIN;
    $env{'psgi.errors'}     = *STDERR;
    my $res = $handler->(\%env);
    print "Status: $res->[0]\n";
    my $headers = $res->[1];
    while (my ($k, $v) = each %$headers) {
        print "$k: $v\n";
    }
    print "\n";

    my $body = $res->[2];
    my $cb = sub { print STDOUT $_[0] };

    PSGI::Util::foreach($body, $cb);
}

1;
__END__

=head1 SYNOPSIS

    use PSGIRef::Impl::CGI;
    PSGIRef::Impl::CGI->run(sub {
        my $env = shift;
        return [
            200,
            { 'Content-Type' => 'text/plain', 'Content-Length' => 13 },
            'Hello, world!',
        ];
    });

=head1 METHODS

=over 4

=item PSGIRef::Impl::CGI->run($code)

Run the handler for CGI with PSGI spec.

=back

