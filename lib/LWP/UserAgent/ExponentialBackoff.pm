use LWP::UserAgent;

package LWP::UserAgent::ExponentialBackoff;
$VERSION = '1.00';
@ISA = ("LWP::UserAgent");
my @FAILCODES = qw(302 500 503);

sub new {
	my ( $class, %cnf ) = @_;
	my $sum = delete $cnf{sum};
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
	$failCodes =  {map { $_ => $_ } @FAILCODES} unless defined $failCodes;
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
		failCodes    => $failCodes,
		retries      => []
	}, $class;
	$self->deltas($tolerance);
	$self->sum($sum) unless !defined $sum;
	return $self;
}

sub simple_request {
	my ( $self, $class ) = @_;
	my $total = 0;
	my $failCodes         = $self->{failCodes};
	my $currentRetryCount = 0;
	my $class             = shift;
	$response = $class->SUPER::simple_request(@_);
	my $code              = $response->code();
	while ( ( $retryInterval = $self->retry($currentRetryCount) )
		&& ${$failCodes}{$code} )
	{
		$self->{retries}[$currentRetryCount]=$retryInterval;
		$currentRetryCount++;
		#sleep $retryInterval;
		$response = $self->SUPER::simple_request(@_);
		$code     = $response->code();
	}
	return $response;
}

sub retry {
	my ( $self, $currentRetryCount ) = @_;
	my $retryCount = $self->{retryCount};
	my $minBackoff = $self->{minBackoff};
	my $maxBackoff = $self->{maxBackoff};
	my $deltaLow   = $self->{deltaLow};
	my $deltaHigh  = $self->{deltaHigh};
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

sub retryCount { shift->_elem( 'retryCount', @_ ); }
sub minBackoff { shift->_elem( 'minBackoff', @_ ); }
sub maxBackoff { shift->_elem( 'maxBackoff', @_ ); }

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
	# maxBackoff should be at least as big as the largest retry interval which is never bigger than the sum
	$self->{maxBackoff} = $sum;
}

sub log2 {
	my $n = shift;
	return log($n) / log(2);
}


