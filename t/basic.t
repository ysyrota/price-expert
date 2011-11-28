use strict;
use warnings;

use Test::More tests => 2;

BEGIN { require FindBin; $ENV{MOJO_HOME} = "$FindBin::Bin/" }
require "$FindBin::Bin/../expert.pl";

use Test::Mojo;

#my $app = app();
#$app->log->level('debug');

my $t = Test::Mojo->new;

# Index page
$t->get_ok('/')->status_is(200);

