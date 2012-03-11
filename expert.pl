#!/usr/bin/env perl

use utf8;

package Model;
use ORLite {
    file => 'prices.db',
    unicode => 1,
    create => sub {
        my $dbh = shift;
        $dbh->do(
            'CREATE TABLE prices (
              id INTEGER PRIMARY KEY,
              seller TEXT NOT NULL,
              buyer TEXT NOT NULL,
              article TEXT NOT NULL,
              amount TEXT NOT NULL,
              date TEXT NOT NULL,
              price TEXT NOT NULL,
              comment TEXT NULL)'
        );
        $dbh->do("INSERT INTO prices (seller, buyer, article, amount, date, price) VALUES ('Продавець 1', 'Покупець 1', 'Товар 1', '6 штук', 'Жовтень 2006', '10 коп.')");
        $dbh->do("INSERT INTO prices (seller, buyer, article, amount, date, price) VALUES ('Продавець 2', 'Покупець 1', 'Товар 2', '7-8 штук', 'Жовтень 2008', '12 коп.')");
        $dbh->do("INSERT INTO prices (seller, buyer, article, amount, date, price, comment) VALUES ('Продавець 2', 'Покупець 2', 'Товар 1', 'коробка', 'Жовтень 2009', '18 коп.', 'коментар до ціни')");
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
                amount => $_->amount,
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
        Model::Prices->iterate(
            "ORDER BY id DESC LIMIT 100", $functor);
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
    my $amount = $self->param('amount');
    my $price = $self->param('price');
    my $comment = $self->param('comment');
    unless (defined($seller) and defined($buyer) and defined($article) and
        defined($date) and defined($amount) and defined($price)) {
        $self->render_json({message => 'seller, buyer, article, date and price are obligatory parameters'}, status => 400);
    } else {
        my $record = Model::Prices->create(seller => $seller, buyer => $buyer,
            article => $article, date => $date, amount => $amount, price => $price, comment => $comment);
        $self->render_json(
            {
                id  => $record->id,
                seller => $record->seller,
                buyer => $record->buyer,
                article => $record->article,
                date => $record->date,
                amount => $record->amount,
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
    warn "here for id is $id\n";
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
% content_for header => begin
<script type="text/javascript">
    var refreshList = function() {
        var pricetable = $('#pricetable tbody');
        pricetable.empty();
        $.getJSON('/prices', function(data) {
            $.each(data, function(key, val) {
                pricetable.prepend(
                    '<tr><td><a href="#" onclick="deleteItemConfirmation('+val.id+')"><i class="icon-trash"></i></a></td>'
                    +'<td>'+val.seller+'</td>'
                    +'<td>'+val.buyer+'</td>'
                    +'<td>'+val.article+'</td>'
                    +'<td>'+val.amount+'</td>'
                    +'<td>'+val.price+'</td>'
                    +'<td>'+val.date+'</td></tr>');
            });
        });
    };

    var deleteItem = function(id) {
        $.ajax({ type: 'DELETE', url: "/prices", data: "id="+id });
        refreshList();
        $('#confirmDeleteModal').modal('hide');
    };

    var deleteItemConfirmation = function(id) {
        $('#confirmDeleteModal .modal-body p').replaceWith(
            '<p>Ви справді хочете видалити ціну '+id);
        $('#deleteButton').click(function() { deleteItem(id) });
        $('#confirmDeleteModal').modal('show');
    };

    $(document).ready(function() {
        refreshList();
    });
</script>
% end
        <div class="modal hide fade" id="confirmDeleteModal">
          <div class="modal-header">
            <a class="close" data-dismiss="modal">×</a>
            <h3>Видалення ціни</h3>
          </div>
          <div class="modal-body">
            <p></p>
          </div>
          <div class="modal-footer">
            <a href="#" class="btn btn-danger" id="deleteButton"><i class="icon-trash icon-white"></i>Видалити</a>
            <a href="#" class="btn" data-dismiss="modal">Скасувати видалення</a>
          </div>
        </div>
        <div class="container">
            <table class="table table-striped" id="pricetable">
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
                  %# search content should be here
                </tbody>
                <tfoot>
                    <tr id="add-row">
                      <td><i class="icon-plus"></i></td>
                      <td><input type="text" maxwidth="10"></input></td>
                      <td><input type="text" maxwidth="10"></input></td>
                      <td><input type="text" maxwidth="10"></input></td>
                      <td><input type="text" maxwidth="10"></input></td>
                      <td><input type="text" maxwidth="10"></input></td>
                      <td><input type="text" maxwidth="10"></input></td>
                    </tr>
                </tfoot>
            </table>
        </div><!-- /container -->

@@ add.html.ep
% layout 'default';
% title 'Додати нову ціну';
        <div class="container">
         <div class="row"
          <div class="span12">
            <form class="form-horizontal">
              <fieldset>
                <legend>Нова ціна</legend>
                  <div class="control-group">
                      <label class="control-label" for="seller">Продавець</label>
                      <div class="controls">
                          <input id="seller" type="text" size="30" name="seller">
                      </div>
                  </div>
                  <div class="control-group">
                      <label class="control-label" for="buyer">Покупець</label>
                      <div class="controls">
                          <input id="buyer" type="text" size="30" name="buyer">
                      </div>
                  </div>
                  <div class="control-group">
                      <label class="control-label" for="article">Продукт</label>
                      <div class="controls">
                          <input id="article" type="text" size="30" name="article">
                      </div>
                  </div>
                  <div class="control-group">
                      <label class="control-label" for="amount">Кількість</label>
                      <div class="controls">
                          <input id="article" type="text" size="30" name="amount">
                      </div>
                  </div>
                  <div class="control-group">
                      <label class="control-label" for="price">Ціна</label>
                      <div class="controls">
                          <input id="price" type="text" size="30" name="price">
                      </div>
                  </div>
                  <div class="control-group">
                      <label class="control-label" for="date">Дата</label>
                      <div class="controls">
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
<html>
    <head>
        <meta charset="utf-8">
        <title><%= title %></title>
        <link rel="stylesheet" href="bootstrap.min.css">
        <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
        <%= content_for 'header' %>
    </head>
    <body style="padding-top: 40px">
        <div class="navbar navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <a class="brand" href="/">Price Expert</a>
                    <form class="navbar-search pull-left" action="">
                        <input type="text" class="search-query" placeholder="Пошук"/>
                    </form>
                    <ul class="nav">
                        <li><a href="<%= url_for 'add' %>"><i class="icon-plus-sign icon-white"></i> Додати</a></li>
                    </ul>
                </div>
            </div>
        </div>
        <%= content %>
        <script src="/js/bootstrap.min.js"></script>
    </body>
</html>
