use utf8;
package ShinyCMS::Schema::Result::Basket;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Basket

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<basket>

=cut

__PACKAGE__->table("basket");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 session

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 72

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "session",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 72 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 basket_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::BasketItem>

=cut

__PACKAGE__->has_many(
  "basket_items",
  "ShinyCMS::Schema::Result::BasketItem",
  { "foreign.basket" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 session

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Session>

=cut

__PACKAGE__->belongs_to(
  "session",
  "ShinyCMS::Schema::Result::Session",
  { id => "session" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 user

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ShinyCMS::Schema::Result::User",
  { id => "user" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-04 20:48:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WO3B5dHKHlljJFDfUwpRAA



# EOF
__PACKAGE__->meta->make_immutable;
1;
