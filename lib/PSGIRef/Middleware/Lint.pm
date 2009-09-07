package PSGIRef::Middleware::Lint;
use Moose;
use Carp;
use PSGIRef::Lint;
use overload '&{}' => sub {
    my $self = $_[0];
    sub {
        PSGIRef::Lint->validate_env($_[0]);
        my $res = $self->code->( @_ );
        PSGIRef::Lint->validate_res($res);
        $res;
    }
  },
  fallback => 1;

has code => (
    is => 'ro',
    isa => 'CodeRef',
);

__PACKAGE__->meta->make_immutable;
