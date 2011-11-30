use strict;
use warnings;

use Test::More tests => 15;

BEGIN { require FindBin; $ENV{MOJO_HOME} = "$FindBin::Bin/" }
require "$FindBin::Bin/../expert.pl";

use Test::Mojo;

#my $app = app();
#$app->log->level('debug');

my $t = Test::Mojo->new;

# Index page
$t->get_ok('/')->status_is(200);

# Add record
$t->post_form_ok('/prices' => {seller => 'test_seller1', buyer => 'test_buyer1', article => 'test article', date => 'September 2001', price => 'too high', comment => 'test comment'})
  ->status_is(201);

my $id = $t->tx->res->json;
like($id, /\d+/);

# Get record
$t->get_ok("/prices?id=$id")
  ->status_is(200)
  ->json_content_is({id => $id, seller => 'test_seller1', buyer => 'test_buyer1', article => 'test article', date => 'September 2001', price => 'too high', comment => 'test comment'});

# Update record
$t->put_ok("/prices", {id => $id, comment => 'fixed comment'})
  ->status_is(200)
  ->json_content_is({id => $id, seller => 'test_seller1', buyer => 'test_buyer1', article => 'test article', date => 'September 2001', price => 'too high', comment => 'fixed comment'});

# Delete record
$t->delete_ok("/prices", {id => $id})
  ->status_is(200);

# Check deleted record
$t->get_ok("/prices?id=$id")
  ->status_is(404);

