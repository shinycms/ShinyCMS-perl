package ShinyCMS::Controller::Admin::Forums;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Forums

=head1 DESCRIPTION

Controller for ShinyCMS forum admin features.

=cut


=head1 METHODS

=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/forums' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'administrate the forums',
		role     => 'Forums Admin',
		redirect => '/forums'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Forums';
}


=head2 index

Bounce back to forums on main site unless user is a forums admin.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_forums' );
}


# ========== ( Posts ) ==========

=head2 stash_post

Stash details relating to a post.

=cut

sub stash_post : Chained( 'base' ) : PathPart( 'post' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $post_id ) = @_;

	$c->stash->{ forum_post } = $c->model( 'DB::ForumPost' )->find({
		id => $post_id
	});

	unless ( $c->stash->{ forum_post } ) {
		$c->stash->{ error_msg } =
			'Specified post not found - please try again.';
		$c->go( 'list_forums' );
	}
}


=head2 edit_post

Edit a forum post.

=cut

sub edit_post : Chained( 'stash_post' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 save_forum_post

Save a forum post.

=cut

sub save_forum_post : Chained( 'stash_post' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		# Delete the comments thread
		$c->stash->{ forum_post }->discussion->comments->delete;
		# Delete the post
		$c->stash->{ forum_post }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Forum post deleted';

		# Bounce to the 'view all forums' page
		$c->response->redirect( $c->uri_for( '/admin/forums' ) );
		$c->detach;
	}

	# Check for a collision in the menu_position settings for this section
	my $collision = $c->stash->{ forum_post }->forum->forum_posts->search({
		display_order => $c->request->param( 'display_order' ),
	})->count;

	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' ) ?
	    $c->request->param( 'url_title' ) :
	    $c->request->param( 'title'     );
	$url_title = $self->make_url_slug( $url_title );

	# TODO: catch and fix duplicate year/month/url_title combinations

	# Update forum post
	$c->stash->{ forum_post }->update({
		title         => $c->request->param( 'title'         ) || undef,
		url_title     => $url_title                            || undef,
		body          => $c->request->param( 'body'          ) || undef,
		display_order => $c->request->param( 'display_order' ) || undef,
	});

	# Update the display_order for other sticky posts in this forum, if necessary
	if ( $collision ) {
		$c->stash->{ forum_post }->forum->forum_posts->search({
			id            => { '!=' => $c->stash->{ forum_post }->id },
			display_order => { '>=' => $c->request->param( 'display_order' ) },
		})->update({
			display_order => \'display_order + 1',
		});
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Forum post updated';

	# Bounce back to the edit page
	my $uri = $c->uri_for( '/admin/forums/post', $c->stash->{ forum_post }->id, 'edit' );
	$c->response->redirect( $uri );
}


# ========== ( Forums ) ==========

=head2 list_forums

List all the forums.

=cut

sub list_forums : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @sections = $c->model( 'DB::ForumSection' )->search(
		{},
		{
			order_by => 'display_order'
		},
	)->all;
	$c->stash->{ sections } = \@sections;
}


=head2 stash_forum

Stash details relating to a forum.

=cut

sub stash_forum : Chained( 'base' ) : PathPart( 'forum' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $forum_id ) = @_;

	$c->stash->{ forum } = $c->model( 'DB::Forum' )->find( { id => $forum_id } );

	unless ( $c->stash->{ forum } ) {
		$c->stash->{ error_msg } =
			'Specified forum not found - please select from the options below';
		$c->go( 'list_forums' );
	}
}


=head2 add_forum

Add a forum.

=cut

sub add_forum : Chained( 'base' ) : PathPart( 'forum/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @sections = $c->model( 'DB::ForumSection' )->search(
		{},
		{ order_by => 'display_order' },
	);
	$c->stash->{ sections } = \@sections;

	$c->stash->{ template } = 'admin/forums/edit_forum.tt';
}


=head2 add_forum_do

Process adding a forum.

=cut

sub add_forum_do : Chained( 'base' ) : PathPart( 'forum/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Create forum
	my $forum = $c->model( 'DB::Forum' )->create({
		name          => $c->request->param( 'name'          ),
		url_name      => $url_name || undef,
		display_order => $c->request->param( 'display_order' ) || undef,
		description   => $c->request->param( 'description'   ),
		section       => $c->request->param( 'section'       ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'New forum created';

	# Bounce to the edit page
	my $url = $c->uri_for( '/admin/forums/forum', $forum->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 edit_forum

Edit a forum.

=cut

sub edit_forum : Chained( 'stash_forum' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @sections = $c->model( 'DB::ForumSection' )->search(
		{},
		{ order_by => 'display_order' },
	);
	$c->stash->{ sections } = \@sections;
}


=head2 edit_forum_do

Save an edited forum.

=cut

sub edit_forum_do : Chained( 'stash_forum' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		# Delete posts in forum
		$c->stash->{ forum }->forum_posts->delete;
		# Delete forum
		$c->stash->{ forum }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Forum deleted';

		# Bounce to the 'view all forums' page
		$c->response->redirect( $c->uri_for( '/admin/forums' ) );
		$c->detach;
	}

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Update forum
	$c->stash->{ forum }->update({
		name          => $c->request->param( 'name'          ),
		url_name      => $url_name,
		display_order => $c->request->param( 'display_order' ) || undef,
		description   => $c->request->param( 'description'   ),
		section       => $c->request->param( 'section'       ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Forum details updated';

	# Bounce back to the edit page
	# Bounce to the edit page
	my $url = $c->uri_for( '/admin/forums/forum', $c->stash->{ forum }->id, 'edit' );
	$c->response->redirect( $url );
}


# ========== ( Sections ) ==========

=head2 list_sections

List all the sections.

=cut

sub list_sections : Chained( 'base' ) : PathPart( 'sections' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @sections = $c->model( 'DB::ForumSection' )->search(
		{},
		{ order_by => 'display_order' },
	);
	$c->stash->{ sections } = \@sections;
}


=head2 stash_section

Stash details relating to a section.

=cut

sub stash_section : Chained( 'base' ) : PathPart( 'section' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $section_id ) = @_;

	$c->stash->{ section } = $c->model( 'DB::ForumSection' )->find( { id => $section_id } );

	unless ( $c->stash->{ section } ) {
		$c->stash->{ error_msg } =
			'Specified section not found - please select from the options below';
		$c->go( 'list_sections' );
	}
}


=head2 add_section

Add a section.

=cut

sub add_section : Chained( 'base' ) : PathPart( 'section/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ template } = 'admin/forums/edit_section.tt';
}


=head2 add_section_do

Process adding a section.

=cut

sub add_section_do : Chained( 'base' ) : PathPart( 'section/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Create section
	my $section = $c->model( 'DB::ForumSection' )->create({
		name          => $c->request->param( 'name'          ) || undef,
		url_name      => $url_name || undef,
		display_order => $c->request->param( 'display_order' ) || undef,
		description   => $c->request->param( 'description'   ) || undef,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'New section created';

	# Bounce to the new section's edit page
	my $url = $c->uri_for( '/admin/forums/section', $section->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 edit_section

Edit a section.

=cut

sub edit_section : Chained( 'stash_section' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 edit_section_do

Save an edited section.

=cut

sub edit_section_do : Chained( 'stash_section' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		# Check for forums in section
		if ( $c->stash->{ section }->forums->count > 0 ) {
			# Shove a warning message into the flash
			$c->flash->{ error_msg }
				= 'You cannot delete a section that still contains forums';
		}
		else {
			# Delete section
			$c->stash->{ section }->delete;
			# Shove a confirmation message into the flash
			$c->flash->{ status_msg } = 'Section deleted';
		}

		# Bounce to the 'view all sections' page
		$c->response->redirect( $c->uri_for( '/admin/forums/sections' ) );
		$c->detach;
	}

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Update section
	$c->stash->{ section }->update({
		name          => $c->request->param( 'name'          ) || undef,
		url_name      => $url_name || undef,
		display_order => $c->request->param( 'display_order' ) || undef,
		description   => $c->request->param( 'description'   ) || undef,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Section details updated';

	# Bounce back to the section's edit page
	my $url = $c->uri_for( '/admin/forums/section', $c->stash->{ section }->id, 'edit' );
	$c->response->redirect( $url );
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
