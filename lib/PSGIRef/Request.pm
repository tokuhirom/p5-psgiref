package PSGIRef::Request;
use Any::Moose;
use args;
use URI::Escape ();

our $VERSION = 0.01;

our $BUFFER_LEN = 4096;

sub _parse {
    my ( $self, $cgi ) = @_;
    my $handle = \( $self->{env}->{'psgi.input'} );

    my $data   = '';
    my $length = $self->env->{HTTP_CONTENT_LENGTH};
    my $type   = $self->env->{HTTP_CONTENT_TYPE};
    my $method = $self->env->{'REQUEST_METHOD'} || 'No REQUEST_METHOD received';

    if ( $length and $type =~ m|^multipart/form-data|i ) {
        my $got_length = $self->_parse_multipart($handle);    # XXX
        if ( $length != $got_length ) {
            die
"500 Bad read on multipart/form-data! wanted $length, got $got_length";
        }
        return;
    }
    elsif ( $method eq 'POST' or $method eq 'PUT' ) {
        if ($length) {
            read($handle, $data, $length);
            while ( length($data) < $length ) {
                last unless read($handle, my $buffer, $BUFFER_LEN);
                $data .= $buffer;
            }

            if ( $length != length $data ) {
                die "500 Bad read on POST! wanted $length, got " . length($data);
            }

            if ( $type !~ m|^application/x-www-form-urlencoded| ) {
                $self->_add_param( $method . "DATA", $data );
            }
            else {
                $self->_parse_params($data);
            }
        }
    }
    elsif ( $method eq 'GET' or $method eq 'HEAD' ) {
        $data = $self->env->{'QUERY_STRING'} || '';
        $self->_parse_params($data);
    }
    else {
        unless ($self->{'.globals'}->{'DEBUG'}
            and $data = $self->read_from_cmdline() )
        {
            die "400 Unknown method $method";
        }

        unless ($data) {
            die "400 No data received via method: $method, type: $type";
        }

        $self->_parse_params($data);
    }
}

sub _parse_params {
    my ( $self, $data ) = @_;
    return () unless defined $data;
    unless ( $data =~ /[&=;]/ ) {
        $self->{'keywords'} = [ $self->_parse_keywordlist($data) ];
        return;
    }
    my @pairs = split /[&;]/, $data;
    for my $pair (@pairs) {
        my ( $param, $value ) = split /=/, $pair, 2;
        next unless defined $param;
        $value = '' unless defined $value;
        $self->_add_param( URI::Escape::uri_unescape($param),
            URI::Escape::uri_unescape($value) );
    }
}

sub _parse_keywordlist {
    my ( $self, $data ) = @_;
    return () unless defined $data;
    $data = URI::Escape::uri_unescape($data);
    my @keywords = split /\s+/, $data;
    return @keywords;
}

sub _add_param {
    my ( $self, $param, $value, $overwrite ) = @_;
    return () unless defined $param and defined $value;
    @{ $self->{$param} } = () if $overwrite;
    @{ $self->{$param} } = () unless exists $self->{$param};
    my @values = ref $value ? @{$value} : ($value);
    for my $value (@values) {
        push @{ $self->{$param} }, $value;
        unless ( $self->{'.fieldnames'}->{$param} ) {
            push @{ $self->{'.parameters'} }, $param;
            $self->{'.fieldnames'}->{$param}++;
        }
    }
}

sub CRLF () { "\015\012" }

sub _parse_multipart {
    my $self = shift;
    my $handle = shift or die "NEED A HANDLE!?";

    my ($boundary) = $self->env->{'HTTP_CONTENT_TYPE'} =~ /boundary=\"?([^\";,]+)\"?/;

    $boundary = $self->_massage_boundary($boundary) if $boundary;

    my $got_data = 0;
    my $data     = '';
    my $length   = $self->env->{'HTTP_CONTENT_LENGTH'} || 0;
    my $CRLF     = CRLF;

  READ:

    while ( $got_data < $length ) {
        last READ unless read( $handle, my $buffer, $BUFFER_LEN );
        $data .= $buffer;
        $got_data += length $buffer;

        unless ($boundary) {

            # If we're going to guess the boundary we need a complete line.
            next READ unless $data =~ /^(.*)$CRLF/o;
            $boundary = $1;

            # Still no boundary? Give up...
            unless ($boundary) {
                die '400 No boundary supplied for multipart/form-data';
            }
            $boundary = $self->_massage_boundary($boundary);
        }

      BOUNDARY:

        while ( $data =~ m/^$boundary$CRLF/ ) {
            ## TAB and high ascii chars are definitivelly allowed in headers.
            ## Not accepting them in the following regex prevents the upload of
            ## files with filenames like "Espa.txt".
            # next READ unless $data =~ m/^([\040-\176$CRLF]+?$CRLF$CRLF)/o;
            next READ
              unless $data =~ m/^([\x20-\x7E\x80-\xFF\x09$CRLF]+?$CRLF$CRLF)/o;
            my $header = $1;
            ( my $unfold = $1 ) =~ s/$CRLF\s+/ /og;
            my ($param) = $unfold =~ m/form-data;\s+name="?([^\";]*)"?/;
            my ($filename) =
              $unfold =~ m/name="?\Q$param\E"?;\s+filename="?([^\"]*)"?/;

            if ( defined $filename ) {
                my ($mime) = $unfold =~ m/Content-Type:\s+([-\w\/]+)/io;
                $data =~ s/^\Q$header\E//;
                ( $got_data, $data, my $fh, my $size ) =
                  $self->_save_tmpfile( $handle, $boundary, $filename,
                    $got_data, $data );
                $self->_add_param( $param, $filename );
                $self->{'.upload_fields'}->{$param} = $filename;
                $self->{'.filehandles'}->{$filename} = $fh if $fh;
                $self->{'.tmpfiles'}->{$filename} =
                  { 'size' => $size, 'mime' => $mime }
                  if $size;
                next BOUNDARY;
            }
            next READ
              unless $data =~ s/^\Q$header\E(.*?)$CRLF(?=$boundary)//s;
            $self->_add_param( $param, $1 );
        }
        unless ( $data =~ m/^$boundary/ ) {
            ## In a perfect world, $data should always begin with $boundary.
            ## But sometimes, IE5 prepends garbage boundaries into POST(ed) data.
            ## Then, $data does not start with $boundary and the previous block
            ## never gets executed. The following fix attempts to remove those
            ## extra boundaries from readed $data and restart boundary parsing.
            ## Note about performance: with well formed data, previous check is
            ## executed (generally) only once, when $data value is "$boundary--"
            ## at end of parsing.
            goto BOUNDARY if ( $data =~ s/.*?$CRLF(?=$boundary$CRLF)//s );
        }
    }
    return $got_data;
}

sub _save_tmpfile {
    my ( $self, $handle, $boundary, $filename, $got_data, $data ) = @_;
    my $fh;
    my $CRLF      = CRLF;
    my $length    = $self->env->{'HTTP_CONTENT_LENGTH'} || 0;
    my $file_size = 0;
    if ($filename) {
        eval { require IO::File };
        die "500 IO::File is not available $@" if $@;
        $fh = IO::File->new_tmpfile;
        die "500 IO::File can't create new temp_file" unless $fh;
    }

    # read in data until closing boundary found. buffer to catch split boundary
    # we do this regardless of whether we save the file or not to read the file
    # data from STDIN. if either uploads are disabled or no file has been sent
    # $fh will be undef so only do file stuff if $fh is true using $fh && syntax
    $fh && binmode $fh;
    while ( $got_data < $length ) {

        my $buffer = $data;
        last unless read( \( $self->{env}->{'psgi.input'} ), $data, $BUFFER_LEN );

        # fixed hanging bug if browser terminates upload part way through
        # thanks to Brandon Black
        unless ($data) {
            die '400 Malformed multipart, no terminating boundary';
            undef $fh;
            return $got_data;
        }

        $got_data += length $data;
        if ( "$buffer$data" =~ m/$boundary/ ) {
            $data = $buffer . $data;
            last;
        }

        # we do not have partial boundary so print to file if valid $fh
        $fh && print $fh $buffer;
        $file_size += length $buffer;
    }
    $data =~ s/^(.*?)$CRLF(?=$boundary)//s;
    $fh && print $fh $1;    # print remainder of file if valid $fh
    $file_size += length $1;
    return $got_data, $data, $fh, $file_size;
}

sub _massage_boundary {
    my ( $self, $boundary ) = @_;

    # BUG: IE 3.01 on the Macintosh uses just the boundary,
    # forgetting the --
    $boundary = '--' . $boundary
      unless exists $ENV{'HTTP_USER_AGENT'}
          && $ENV{'HTTP_USER_AGENT'} =~ m/MSIE\s+3\.0[12];\s*Mac/i;

    return quotemeta $boundary;
}

sub param {
    my ( $self, $param, @p ) = @_;
    unless ( defined $param ) {    # return list of all params
        my @params = $self->{'.parameters'} ? @{ $self->{'.parameters'} } : ();
        return @params;
    }
    unless (@p) {                  # return values for $param
        return () unless exists $self->{$param};
        return wantarray ? @{ $self->{$param} } : $self->{$param}->[0];
    }
    if ( $param =~ m/^-name$/i and @p == 1 ) {
        return () unless exists $self->{ $p[0] };
        return wantarray ? @{ $self->{ $p[0] } } : $self->{ $p[0] }->[0];
    }

    # set values using -name=>'foo',-value=>'bar' syntax.
    # also allows for $q->param( 'foo', 'some', 'new', 'values' ) syntax
    ( $param, undef, @p ) = @p
      if $param =~ m/^-name$/i;    # undef represents -value token
    $self->_add_param( $param, ( ref $p[0] eq 'ARRAY' ? $p[0] : [@p] ),
        'overwrite' );
    return wantarray ? @{ $self->{$param} } : $self->{$param}->[0];
}

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

sub BUILD {
    my $self = shift;
    $self->_parse();
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

=head1 PRIVATE METHODS

=over 4

=item CRLF

=back

=head1 THANKS TO

Andy Armstrong, the author of CGI::Simple. This modules takes some code from CGI::Simple. thanks!

=head1 SEE ALSO

L<CGI::Simple>

