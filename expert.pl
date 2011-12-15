#!/usr/bin/env perl

use utf8;

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
    my @keys = $self->param;
    my @result = ();
    my $functor = sub {
            push @result, {
                id => $_->id,
                seller => $_->seller,
                buyer => $_->buyer,
                article => $_->article,
                date => $_->date,
                price => $_->price,
                comment => $_->comment};
        };
    if ('like' ~~ @keys) {
        my $val = Model->dbh->quote('%'.$self->param('like').'%');
        Model::Prices->iterate(
            "WHERE seller LIKE $val OR buyer LIKE $val" ,
            $functor);
    } elsif (scalar @keys) {
        my %vals;
        for my $key (qw(id seller buyer article date price comment)) {
            $vals{$key} = $self->param($key) if $key ~~ @keys;
        }
        Model::Prices->iterate(
            'WHERE ' . join(', ', map { "$_ = ?" } keys %vals),
            values %vals, $functor);
    } else {
        Model::Prices->iterate($functor);
    }
    $self->render_json(\@result);
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

    if (defined $id) {
        my $record = Model::Prices->load($id);
        my @keys = $self->param;
        my %new_vals;
        for my $key (qw(seller buyer article date price comment)) {
            $new_vals{$key} = $self->param($key) if $key ~~ @keys;
        }
#        Model::Prices->update(\%new_vals);
        Model->do(
            'UPDATE prices SET '
            . join(', ', map { "$_ = ?" } keys %new_vals)
            . ' WHERE id=?',
           {},
           values %new_vals, $id);
        $self->render_json(
            {
                id     => $id,
                seller => $new_vals{seller} || $record->seller,
                buyer  => $new_vals{buyer}  || $record->buyer,
                article=> $new_vals{article}|| $record->article,
                date   => $new_vals{date}   || $record->date,
                price  => $new_vals{price}  || $record->price,
                comment=> $new_vals{comment}|| $record->comment
            }, status => 200);
    } else {
        $self->render_json({message => 'id is an obligatory parameter'},
            status => 400);
    }
};

del '/prices' => sub {
    my $self = shift;
    my $id = $self->param('id');
    if (defined $id) {
        my $rows_affected = Model::Prices->delete('where id=?', $id);
        if ($rows_affected == 0) {
            $self->rendered(404);
        } else {
            $self->rendered(200);
        }
    } else {
        $self->render_json({message => 'id is an obligatory parameter'},
            status => 400);
    }
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<div id="sidebar">
  <div id="logo"><a href="/"><img alt="Price Expert" src="style/images/logo.png"></a></div>
  <div id="menu">
    <ul>
      <li><a href="">Додати</a></li>
      <li><a href="">Видалити</a></li>
    </ul>
  </div>
</div>
<div id="content">
  <form id="searchform">
    <input id="search-field" type="text" value=""/>
  </form>
  <table>
    <tr>
      <th>Покупець</th>
      <th>Продавець</th>
      <th>Продукт</th>
      <th>Об’єм</th>
      <th>Ціна</td>
      <th>Дата</th></tr>
    <tr>
      <td>ВАТ "Рівень"</td>
      <td>ТОВ "Вишиванка"</td>
      <td>Мастило</td>
      <td>2 л</td>
      <td>2 грн 5 коп</td>
      <td>весна 2010</td>
    </tr>
    <tr>
      <td>ВАТ "Рівень"</td>
      <td>ТОВ "Будучність"</td>
      <td>Табуретки</td>
      <td>6 шт</td>
      <td>25 грн</td>
      <td>літо 2010</td>
    </tr>
    <tr>
      <td>ЗАТ "Контора"</td>
      <td>ТОВ "Будучність"</td>
      <td>Столи</td>
      <td>2 шт</td>
      <td>5 грн</td>
      <td>літо 2011</td>
    </tr>
  </table>
</div>

@@ layouts/default.html.ep
<!doctype html>
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="style.css" media="all" />
    <title><%= title %></title>
  </head>
  <body>
    <div id="wrapper">
      <%= content %>
    </div>
    <div class="clear"></div>
  </body>
</html>
