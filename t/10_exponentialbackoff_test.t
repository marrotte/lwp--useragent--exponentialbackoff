
# Time-stamp: "0";
use strict;
use Test;
BEGIN { plan tests => 14 }

#use LWP::Debug ('+');

use LWP::UserAgent::ExponentialBackoff;
my $browser = LWP::UserAgent::ExponentialBackoff->new;

ok 1;
print "# Hello from ", __FILE__, "\n";
print "# LWP::UserAgent::ExponentialBackoff v$LWP::UserAgent::ExponentialBackoff::VERSION\n";
print "# LWP::UserAgent v$LWP::UserAgent::VERSION\n";
print "# LWP v$LWP::VERSION\n" if $LWP::VERSION;

my @error_codes = qw(408 500 502 503 504);
ok( @error_codes == keys %{$browser->failCodes} );
ok( @error_codes == grep { $browser->failCodes->{$_} } @error_codes );

ok( $browser->sum(21) );

my $url = 'http://www.livejournal.com/~torgo_x/rss';
my $before_count = 0;
my  $after_count = 0;

$browser->before_request( sub {
  my $junk = $_;
  print "#  /Trying ", $_[1][0]->uri, " at ", scalar(localtime), "...\n";
  ++$before_count;
});
$browser->after_request( sub {
  print "#  \\Just tried ", $_[1][0]->uri, " at ", scalar(localtime), ".\n";
  ++$after_count;
});

my $resp = $browser->get( $url );
ok 1;

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
ok( $before_count > 1 );
print "# After_count: $after_count\n";
ok(  $after_count > 1 );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$url = "http://www.aoeaoeaoeaoe.int:9876/sntstn";
$before_count = 0;
 $after_count = 0;

print "# Trying a nonexistent address, $url\n";

$resp = $browser->get( $url );
ok 1;

$browser->sum(10);
print "# Sum: ", $browser->{sum}, "\n";

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
ok $before_count, 4;
print "# After_count: $after_count\n";
ok $after_count,  4;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$url = "http://www.interglacial.com/always404alicious/";
$before_count = 0;
 $after_count = 0;

print "# Trying a nonexistent address, $url\n";

$resp = $browser->get( $url );
ok 1;

$browser->sum(120);
print "# Sum: ", $browser->{sum}, "\n";

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
ok $before_count, 1;
print "# After_count: $after_count\n";
ok $after_count,  1;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
print "# Okay, bye from ", __FILE__, "\n";
ok 1;

