# ===================================================================
# File:		t/controllers/controller_Shop.t
# Project:	ShinyCMS
# Purpose:	Tests for shop features
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Start at the beginning  :)
$t->get_ok(
	'/shop',
	'Fetch shop homepage'
);
$t->title_is(
	'Shop Categories - ShinySite',
	'Loaded shop homepage'
);
# List of categories
$t->get_ok(
	'/shop/category',
	'Try to fetch /category without a category specified'
);
$t->title_is(
	'Shop Categories - ShinySite',
	'Loaded shop homepage again'
);
# List of items in empty category
$t->follow_link_ok(
	{ url_regex => qr{/shop/category/[-\w]+$} },
	'Click on link to view first category'
);
$t->title_is(
	'Doodahs - ShinySite',
	'Loaded Doodah category page'
);
$t->text_contains(
	'Viewing items 0 to 0 of 0',
	'Confirmed that there are no items in this category'
);
$t->back;
# List of items in non-empty category
$t->follow_link_ok(
	{ url_regex => qr{/shop/category/[-\w]+$}, n => 2 },
	'Go back, click on link to view next category'
);
$t->title_is(
	'Widgets - ShinySite',
	'Loaded Widgets category page'
);
$t->text_contains(
	'Viewing items 1 to 3 of 3',
	'Confirmed that there are 3 items in this category'
);
# Individual item
$t->follow_link_ok(
	{ url_regex => qr{/shop/item/[-\w]+$}, n => 3 }, # 2 links per item
	'Click on link to view second item'
);
$t->title_is(
	'Green ambidextrous widget - ShinySite',
	'Loaded individual item page'
);
my $widget_path = $t->uri->path;
# Go to alt category page from item page
$t->follow_link_ok(
	{ url_regex => qr{/shop/category/[-\w]+$}, n => 2 },
	'Click on link to view second category in list from item page'
);
$t->title_is(
	'Ambidextrous Widgets - ShinySite',
	'Loaded Ambidextrous Widgets category page'
);
# Back to item page, try like/unlike/favourite
$t->back;
$t->follow_link_ok(
	{ text => 'Like this item' },
	'Click on link to like this item'
);
$t->text_contains(
	'You like this item',
	"Verified that 'like' feature worked"
);
$t->follow_link_ok(
	{ text => 'undo' },
	"Click on link to remove 'like' from this item"
);
$t->text_contains(
	'Like this item',
	"Verified that 'like' removal worked"
);
$t->get_ok(
	$t->uri->path . '/favourite',
	'Try to add item to favourites, whilst not logged in'
);
$t->text_contains(
	'You must be logged in to add favourites',
	'Adding to favourites failed due to not being logged in'
);
# Try to see list of recently viewed items (won't work, not logged in yet)
$t->add_header( Referer => undef );
$t->get_ok(
	'/shop/recently-viewed',
	'Try to view recently-viewed items, whilst not logged in'
);
$t->text_contains(
	'You must be logged in to see your recently viewed items',
	'Recently viewed feature only available to logged in users'
);
# Log in
my $user = create_test_user( 'test_shop_user' );
$t = login_test_user( $user->username, $user->username ) or die 'Failed to log in';
ok(
	ref $user eq 'ShinyCMS::Schema::Result::User',
	'Logged in as test user'
);
# Look at recently viewed again
$t->get_ok(
	'/shop/recently-viewed',
	'Try to view recently-viewed items, after logging in'
);
$t->title_is(
	'Recently Viewed - ShinySite',
	'Loaded recently viewed items'
);
$t->text_contains(
	'Viewing items 0 to 0 of 0',
	'No recently-viewed items ... yet'
);
# Go look at an item
$t->get_ok(
	$widget_path,
	'Look at a widget again'
);
$t->follow_link_ok(
	{ text => 'Like this item' },
	'Click on link to like item as logged-in user'
);
# Look at recently viewed again
$t->get_ok(
	'/shop/recently-viewed',
	'Then go back to recently-viewed items page'
);
$t->text_contains(
	'Viewing items 1 to 1 of 1',
	'And now we have something in recently-viewed items!'
);

# TODO: ...

done_testing();
