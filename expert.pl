#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::JSON;

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

get '/prices' => sub {
  my $self = shift;
  $self->respond_to(
    json => sub { $self->render_json(['prices']) },
    html => sub { $self->render_data('<html><body>works') },
    xml  => sub { $self->render_data('<works/>') }
  );
};

post '/prices' => sub {
    my $self = shift;
    $self->rendered(501);
};

put '/prices' => sub {
    my $self = shift;
    my $id = $self->param('id');
    $self->rendered(501);
};

del '/prices' => sub {
    my $self = shift;
    my $id = $self->param('id');
    $self->rendered(501);
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to Price Expert!

@@ layouts/default.html.ep
<!doctype html><html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
