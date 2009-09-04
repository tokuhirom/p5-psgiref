package PSGIRef::Request;
use Any::Moose;
use CGI::Simple;
use args;

has _cgi => (
    is => 'ro',
    isa => 'CGI::Simple',
    lazy => 1,
    default => sub {
        args my $self;
        local %ENV = %{$self->{env}};
        $ENV{CONTENT_LENGTH} = $ENV{HTTP_CONTENT_LENGTH} if exists $ENV{HTTP_CONTENT_LENGTH};
        $ENV{CONTENT_TYPE}   = $ENV{HTTP_CONTENT_TYPE}   if exists $ENV{HTTP_CONTENT_TYPE};
        CGI::Simple->new(\( $self->{env}->{'psgi.input'} ));
    },
    handles => [qw/param header/],
);

has env => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

sub BUILDARGS {
    my ($class, $env) = @_;
    return {
        env  => $env
    };
}

sub method    { $_[0]->{env}->{REQUEST_METHOD} }

__PACKAGE__->meta->make_immutable;
__END__

=head1 SYNOPSIS

    my $ss = PSGIRef::Interface::ServerSimple->new(port => 1978, address => '127.0.0.1');
    $ss->run(sub {
        my $env = shift;
        my $req = PSGIRef::Request->new($env);

        return [200, { 'Content-Type' => 'text/plain', 'Content-Length' => 13}, 'Hello, ' . $req->param('name')];
    });

=head1 METHODS

=over 4

=item method

This method returns HTTP request method auch as 'GET' or 'POST'.

=item $req->param(Str)

This method returns parameters from client.

=back

