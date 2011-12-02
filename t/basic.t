use strict;
use warnings;

use Test::More tests => 18;

BEGIN { require FindBin; $ENV{MOJO_HOME} = "$FindBin::Bin/" }
require "$FindBin::Bin/../expert.pl";

use Test::Mojo;

#my $app = app();
#$app->log->level('debug');

my $t = Test::Mojo->new;

# Index page
$t->get_ok('/')->status_is(200);

# Add record with incoplete arguments
$t->post_form_ok('/prices' => {seller => 'test_seller1'})
  ->status_is(400);

# Add record
$t->post_form_ok('/prices' => {seller => 'test_seller1', buyer => 'test_buyer1', article => 'test article', date => 'September 2001', price => 'too high', comment => 'test comment'})
  ->status_is(201);

my $record = $t->tx->res->json;
ok(defined $record->{id}, "id returned");
like($record->{id}, qr/^\d+$/, "id is a number");

# Get record
$t->get_ok("/prices?id=".$record->{id})
  ->status_is(200)
  ->json_content_is({id => $record->{id}, seller => 'test_seller1', buyer => 'test_buyer1', article => 'test article', date => 'September 2001', price => 'too high', comment => 'test comment'});

# Update record
my $params = Mojo::Parameters->new(id => $record->{id}, comment => "fixed comment");
$t->put_ok("/prices?" . $params->to_string)
  ->status_is(200)
  ->json_content_is({id => $record->{id}, seller => 'test_seller1', buyer => 'test_buyer1', article => 'test article', date => 'September 2001', price => 'too high', comment => 'fixed comment'});

# Delete record
$t->delete_ok("/prices", {id => $record->{id}})
  ->status_is(200);

# Delete the same record again
$t->delete_ok("/prices", {id => $record->{id}})
  ->status_is(404);

# Check deleted record
$t->get_ok("/prices?id=".$record->{id})
  ->status_is(404);

