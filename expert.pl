#!/usr/bin/env perl

package Model;
use ORLite {
    file => 'prices.db',
    create => sub {
        my $dbh = shift;
        $dbh->do(
            'CREATE TABLE prices (
              id INTEGER PRIMARY KEY,
              seller TEXT NOT NULL,
              buyer TEXT NOT NULL,
              article TEXT NOT NULL,
              date TEXT NOT NULL,
              price TEXT NOT NULL,
              comment TEXT NULL)'
        );
    }
};

package main;

use Mojolicious::Lite;
use Mojo::JSON;
get '/' => sub {
  my $self = shift;
  $self->render('index');
};

get '/prices' => sub {
  my $self = shift;
  $self->rendered(501);
};

# insertion
post '/prices' => sub {
    my $self = shift;
    my $seller = $self->param('seller');
    my $buyer = $self->param('buyer');
    my $article = $self->param('article');
    my $date = $self->param('date');
    my $price = $self->param('price');
    my $comment = $self->param('comment');
    unless (defined($seller) and defined($buyer) and defined($article) and defined($date) and defined($price)) {
        $self->render_json({message => 'seller, buyer, article, date and price are obligatory parameters'}, status => 400);
    } else {
        my $record = Model::Prices->create(seller => $seller, buyer => $buyer, article => $article, date => $date, price => $price, comment => $comment);
        $self->render_json(
            {
                id  => $record->id,
                seller => $record->seller,
                buyer => $record->buyer,
                article => $record->article,
                date => $record->date,
                price => $record->price,
                comment => $record->comment
            }, status => 201);
    }
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
