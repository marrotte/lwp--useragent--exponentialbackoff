use LWP::UserAgent;

package LWP::UserAgent::ExponentialBackoff;
$VERSION = '0.02';
@ISA     = ("LWP::UserAgent");
my @FAILCODES = qw(408 500 502 503 504);

sub new {
	my ( $class, %cnf ) = @_;
	my $sum        = delete $cnf{sum};
	my $retryCount = delete $cnf{retryCount};
	$retryCount = 3 unless defined $retryCount;
	my $minBackoff = delete $cnf{minBackoff};
	$minBackoff = 3 unless defined $minBackoff;
	my $maxBackoff = delete $cnf{maxBackoff};
	$maxBackoff = 90 unless defined $maxBackoff;
	my $deltaBackoff = delete $cnf{deltaBackoff};
	$deltaBackoff = 3 unless defined $deltaBackoff;
	my $tolerance = delete $cnf{tolerance};
	$tolerance = .20 unless defined $tolerance;
	my $failCodes = delete $cnf{failCodes};
	$failCodes = { map { $_ => $_ } @FAILCODES } unless defined $failCodes;
	my $self = $class->SUPER::new(@_);
	$self = bless {
		%{$self},
		sum          => $sum,
		retryCount   => $retryCount,
		minBackoff   => $minBackoff,
		maxBackoff   => $maxBackoff,
		tolerance    => $tolerance,
		deltaBackoff => $deltaBackoff,
		deltaLow     => $deltaLow,
		deltaHigh    => $deltaHigh,
		failCodes    => $failCodes
	}, $class;
	$self->deltas($tolerance);
	$self->sum($sum) unless !defined $sum;
	return $self;
}

sub simple_request {
	my ( $self, @args ) = @_;
	my $total             = 0;
	my $failCodes         = $self->{failCodes};
	my $currentRetryCount = 0;
	my $before_c          = $self->before_request;
	my $after_c           = $self->after_request;
	my $retryInterval     = 0;
	
	do {
		sleep $retryInterval;
		$before_c->( $self, \@args );
		$response = $self->SUPER::simple_request(@args);
		$after_c and $after_c->( $self, \@args, $response );
		$code = $response->code();
		$currentRetryCount++;
	}while ( ( $retryInterval = $self->retry($currentRetryCount-1) )
		&& ${$failCodes}{$code} );
		
	return $response;
}

sub retry {
	my ( $self, $currentRetryCount ) = @_;
	my $retryCount   = $self->{retryCount};
	my $minBackoff   = $self->{minBackoff};
	my $maxBackoff   = $self->{maxBackoff};
	my $deltaLow     = $self->{deltaLow};
	my $deltaHigh    = $self->{deltaHigh};
	my $deltaBackoff = $self->{deltaBackoff};

	if ( $currentRetryCount < $retryCount ) {

		#Calculate Exponential backoff with tolerance (deltaLow & deltaHigh)
		my $r = $deltaBackoff;
		if ( $deltaHigh - $deltaLow != 0 ) {
			$r = rand( $deltaHigh - $deltaLow ) + $deltaLow;
		}
		$increment = ( 2**$currentRetryCount - 1 ) * $r + $minBackoff;
		$retryInterval = $increment <= $maxBackoff ? $increment : $maxBackoff;
	}
	else {
		$retryInterval = 0;
	}
	return $retryInterval;
}

sub retryCount            { shift->_elem( 'retryCount',            @_ ); }
sub minBackoff            { shift->_elem( 'minBackoff',            @_ ); }
sub maxBackoff            { shift->_elem( 'maxBackoff',            @_ ); }
sub failCodes             { shift->_elem( 'failCodes',             @_ ) }
sub before_request { shift->_elem( 'before_request', @_ ) }
sub after_request  { shift->_elem( 'after_request',  @_ ) }

sub tolerance {
	my ( $self, $tolerance ) = @_;
	$self->{tolerance} = $tolerance;
	$self->deltas($tolerance);
}

sub deltas {
	my ( $self, $tolerance ) = @_;
	if ( $tolerance == 0 ) {
		$self->{deltaLow}  = 0;
		$self->{deltaHigh} = 0;
	}
	else {
		$self->{deltaLow}  = $self->{deltaBackoff} * ( 1 - $tolerance );
		$self->{deltaHigh} = $self->{deltaBackoff} * ( 1 + $tolerance );
	}
}

sub deltaBackoff { shift->_elem( 'deltaBackoff', @_ ); }

sub addFailCodes {
	my ( $self, $code ) = @_;
	$self->{failCodes}->{$code} = $code;
}

sub delFailCodes {
	my ( $self, $code ) = @_;
	delete $self->{failCodes}->{$code};
}

# Given sum and deltaBackoff, compute retryCount and maxBackoff such that total retryIntervals will always be equal to or "slightly" greater than sum.
sub sum {
	my ( $self, $sum ) = @_;
	$self->{retryCount} = log2( $sum / $self->{deltaBackoff} - 1 );

# maxBackoff should be at least as big as the largest retry interval which is never bigger than the sum, so just make it equal the sum
	$self->{maxBackoff} = $sum;
	$self->{sum} = $sum;
}

sub log2 {
	my $n = shift;
	return log($n) / log(2);
}
1;
__END__

=head1 NAME

LWP::UserAgent::ExponentialBackoff - LWP::UserAgent extension that retries errors with exponential backoff

=head1 SYNOPSIS

  my @failCodes    = qw(500 503);
  my %failCodesMap = map { $_ => $_ } @failCodes;

  %options = (
  	  tolerance    => .20,
	  retryCount   => 5,
	  minBackoff   => 3,
	  maxBackoff   => 120,
	  deltaBackoff => 3,
	  failCodes    => \%failCodesMap
  );

  my $ua = LWP::UserAgent::ExponentialBackoff->new(%options);
  my $request   = HTTP::Request->new( 'GET', $uri );
  my $response  = $ua->request($request);

=head1 DESCRIPTION

LWP::UserAgent::ExponentialBackoff is a LWP::UserAgent extention.
It retries requests on error using an exponential backoff algorthim. 

=head1 CONSTRUCTOR METHODS

The following constructor methods are available:

=over 4

=item $ua = LWP::UserAgent::ExponentialBackoff->new( %options )

This method constructs a new C<LWP::UserAgent::ExponentialBackoff> object and returns it.
Key/value pair arguments may be provided to set up the initial state.

   KEY                     DEFAULT
   -----------             --------------------
   sum                     undef
   retryCount              3
   minBackoff              3
   maxBackoff              90
   tolerance               .20
   deltaBackoff            3
   failCodes               { map { $_ => $_ } qw(408 500 502 503 504) }	
   

See L<LWP::UserAgent> for additional key/value pair arguments that may be provided.

=head1 METHODS

This module inherits all of L<LWP::UserAgent>'s methods,
and adds the following.

=over

TBD

=head1 IMPLEMENTATION

This class works by overriding LWP::UserAgent's Csimple_request method 
with an exponential backoff algortihm.


=head1 SEE ALSO

L<LWP>, L<LWP::UserAgent>, L<LWP::UserAgent::Determined>

=head1 AUTHOR

Michael Marrotte <lt>marrotte at cpan dot org<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
