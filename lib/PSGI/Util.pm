package PSGI::Util;

# Is it safe to use Scalar::Util everywhere?
sub _blessed {
    ref $_[0] && ref($_[0]) !~ /^(?:SCALAR|ARRAY|HASH|CODE|GLOB|Regexp)$/;
}

sub foreach {
    my($body, $cb) = @_;

    if (ref $body eq 'ARRAY') {
        for my $line (@$body) {
            $cb->($line);
        }
    } elsif (ref $body eq 'GLOB' || (_blessed($body) && $body->can('getline'))) {
        while (defined(my $line = $body->getline)) {
            $cb->($line);
        }
        $body->close if $body->can('close');
    } elsif (ref $body eq 'CODE') {
        while (defined(my $line = $body->())) {
            $cb->($line);
        }
    } else {
        $body->foreach($cb);
        $body->close if $body->can('close');
    }
}

sub response_handle {
    my %methods = @_;
    PSGI::Util::ResponseHandle->new(%methods);
}

package PSGI::Util::ResponseHandle;
use Carp ();

sub new {
    my($class, %methods) = @_;

    my $self = bless [ ], $class;
    $self->[0] = $methods{print} or Carp::croak "print() should be implemented.";
    $self->[1] = $methods{close} || sub {};

    return $self;
}

sub print { $_[0]->[0]->(@_[1..$#_]) }
sub close { $_[0]->[1]->(@_[1..$#_]) }

1;
