#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::JSON;

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

get '/price' => sub {
  my $self = shift;
  $self->respond_to(
    json => sub { $self->render_json(['prices']) },
    html => sub { $self->render_data('<html><body>works') },
    xml  => sub { $self->render_data('<works/>') }
  );
};

post '/price' => sub {
    my $self = shift;
};

put '/price' => sub {
    my $self = shift;
    my $id = $self->param('id');
};

del '/price' => sub {
    my $self = shift;
    my $id = $self->param('id');
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
