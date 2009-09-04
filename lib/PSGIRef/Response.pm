package PSGIRef::Response;
use Any::Moose;
use HTTP::Headers;
use args;
use overload '@{}'    => sub { $_[0]->as_arrayref },
             fallback => 1;

has status => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has headers => (
    is => 'rw',
    isa => 'HTTP::Headers',
    default => sub { HTTP::Headers->new() },
    handles => [qw/header/],
);

has body => (
    is => 'rw',
    isa => 'Str|IO::File|GLOB',
    required => 1,
);

sub as_arrayref {
    args my $self;
    if (!$self->header('Content-Length') && !ref $self->body) {
        $self->header('Content-Length' => length($self->body));
    }
    return [ $self->status, {%{$self->headers}}, $self->body ];
}

__PACKAGE__->meta->make_immutable;
__END__

=head1 SYNOPSIS

    my $ss = PSGIRef::Interface::ServerSimple->new(port => 1978, address => '127.0.0.1');
    $ss->run(sub {
        my $env = shift;

        return PSGIRef::Response->new(
            status => 200,
            body   => 'foo',
        )->as_arrayref();
    });

=head1 METHODS

=over 4

=item $self->as_arrayref()

convert response object to plain array reference for PSGI spec.

=back

