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

1;
