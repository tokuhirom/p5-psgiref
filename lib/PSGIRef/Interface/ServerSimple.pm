package PSGIRef::Interface::ServerSimple;
use Any::Moose;
use HTTP::Server::Simple;
use PSGIRef::Interface::CGI;

{
    package # hide from pause
        PSGIRef::Interface::ServerSimple::Impl;
    use base qw/HTTP::Server::Simple::CGI/;

    sub print_banner { }

    sub handler {
        my ($self) = @_;
        my %env;
        while (my ($k, $v) = each %ENV) {
            next unless $k =~ qr/^(?:REQUEST_METHOD|SCRIPT_NAME|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT|HTTP_)$/;
            $env{$k} = $v;
        }
        $env{'HTTP_CONTENT_LENGTH'} = $ENV{CONTENT_LENGTH};
        $env{'HTTP_CONTENT_TYPE'}   = $ENV{CONTENT_TYPE};
        $env{'HTTP_COOKIE'}         = $ENV{COOKIE};
        $env{'psgi.version'} = [1,0];
        $env{'psgi.url_scheme'} = 'http';
        $env{'psgi.input'} = *STDIN;
        $env{'psgi.errors'} = *STDERR;
        my $res = $self->{__psgiref_code}->(\%env);
        print "HTTP/1.0 $res->[0]\r\n";
        my $headers = $res->[1];
        while (my ($k, $v) = each %$headers) {
            print "$k: $v\r\n";
        }
        print "\r\n";
        if (ref $res->[2] eq 'GLOB') {
            my $fh = $res->[2];
            print $_ while <$fh>;
        } else {
            print $res->[2];
        }
    }
}

has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has address => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
);

sub run {
    my ($self, $handler) = @_;

    my $server = PSGIRef::Interface::ServerSimple::Impl->new($self->port);
    $server->{__psgiref_code} = $handler;
    $server->host($self->address);
    $server->run();
}

__PACKAGE__->meta->make_immutable;
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

=head1 METHODS

=over 4

=item PSGIRef::Interface::CGI->run($code)

Run the handler for CGI with PSGI spec.

=back

