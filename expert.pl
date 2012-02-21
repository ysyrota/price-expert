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

# HTML
get '/' => sub {
  my $self = shift;
  $self->render('index');
};

get '/add' => sub {
  my $self = shift;
  $self->render('add');
} => 'add';

# REST API
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
        <div class="topbar" data-scrollspy="scrollspy">
            <div class="topbar-inner">
                <div class="container">
                    <a class="brand" href="/">Price Expert</a>
                    <form class="pull-left" action="">
                        <input type="text" placeholder="Пошук"/>
                    </form>
                    <ul class="nav">
                        <li><a href="<%= url_for 'add' %>">Додати</a></li>
                        <li><a href="#">Видалити</a></li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="container">
            <table class="zebra-striped">
                <thead>
                    <tr>
                        <th> </th>
                        <th>Продавець</th>
                        <th>Покупець</th>
                        <th>Продукт</th>
                        <th>Кількість</th>
                        <th>Ціна</th>
                        <th>Дата</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><input type="checkbox" name="q1"/></td>
                        <td>kerhtkjreh</td>
                        <td>KUHlke</td>
                        <td>welrfkh</td>
                        <td>2 welr</td>
                        <td>16 eklh</td>
                        <td>Травень 2011</td>
                    </tr>
                    <tr>
                        <td><input type="checkbox" name="q2"/></td>
                        <td>kerhtkjreh</td>
                        <td>KUHlke</td>
                        <td>welrfkh</td>
                        <td>2 welr</td>
                        <td>16 eklh</td>
                        <td>Травень 2011</td>
                    </tr>
                    <tr>
                        <td><input type="checkbox" name="q3"/></td>
                        <td>kerhtkjreh</td>
                        <td>KUHlke</td>
                        <td>welrfkh</td>
                        <td>2 welr</td>
                        <td>16 eklh</td>
                        <td>Травень 2011</td>
                    </tr>
                </tbody>
            </table>
        </div><!-- /container -->

@@ add.html.ep
% layout 'default';
% title 'Додати нову ціну';
        <div class="topbar" data-scrollspy="scrollspy">
            <div class="topbar-inner">
                <div class="container">
                    <a class="brand" href="/">Price Expert</a>
                    <form class="pull-left" action="">
                        <input type="text" placeholder="Пошук"/>
                    </form>
                    <ul class="nav">
                        <li><a href="#">Додати</a></li>
                        <li><a href="#">Видалити</a></li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="container">
         <div class="row"
          <div class="span12">
            <form>
              <fieldset>
                <legend>Нова ціна</legend>
                  <div class="clearfix">
                      <label for="seller">Продавець</label>
                      <div class="input">
                          <input id="seller" type="text" size="30" name="seller">
                      </div>
                  </div>
                  <div class="clearfix">
                      <label for="buyer">Покупець</label>
                      <div class="input">
                          <input id="buyer" type="text" size="30" name="buyer">
                      </div>
                  </div>
                  <div class="clearfix">
                      <label for="article">Товар</label>
                      <div class="input">
                          <input id="article" type="text" size="30" name="article">
                      </div>
                  </div>
                  <div class="clearfix">
                      <label for="price">Ціна</label>
                      <div class="input">
                          <input id="price" type="text" size="30" name="price">
                      </div>
                  </div>
                  <div class="clearfix">
                      <label for="date">Дата</label>
                      <div class="input">
                          <script>
                            $(function() { $( "#date" ).datepicker(); });
                          </script>
                          <input id="date" type="text" size="30" name="date">
                      </div>
                  </div>
                  <div class="actions">
                      <input class="btn primary" type="submit" value="Додати">
                      <button class="btn" type="reset">Очистити</button>
                  </div>
              </fieldset>
            </form>
          </div>
         </div>
        </div>

@@ layouts/default.html.ep
<!doctype html>
<html style="margin-top:60px">
    <head>
        <meta charset="utf-8">
        <title><%= title %></title>
        <link rel="stylesheet" href="bootstrap.min.css">
        <script type="text/javascript" src="jquery-1.6.2.min.js"></script>
        <script type="text/javascript" src="jquery-ui-1.8.17.custom.min.js"></script>
    </head>
    <body style="padding-top: 40px">
        <%= content %>
    </body>
</html>
