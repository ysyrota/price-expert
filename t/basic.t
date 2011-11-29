use strict;
use warnings;

use Test::More tests => 7;

BEGIN { require FindBin; $ENV{MOJO_HOME} = "$FindBin::Bin/" }
require "$FindBin::Bin/../expert.pl";

use Test::Mojo;

#my $app = app();
#$app->log->level('debug');

my $t = Test::Mojo->new;

# Index page
$t->get_ok('/')->status_is(200);

# Add record
$t->post_form_ok('/prices' => {seller => 'test_seller1', buyer => 'sest_buyer1', date => 'September 2001', price => 'too high', comment => 'test comment'})
  ->status_is(200);

my $id = $t->tx->res->json;
like($id, /\d+/);

# Get record
$t->get_ok("/price/$id")
  ->status_is(200)
  ->json_content_is({id => $id, seller => 'test_seller1', buyer => 'sest_buyer1', date => 'September 2001', price => 'too high', comment => 'test comment'};
  
# Update record
$t->put_ok("/price/$id");

# Check updated record

# Delete record
$t->delete_ok("/price/$id");

# Check deleted record
$t->get_ok("/price/$id")
  ->status_is(401);
