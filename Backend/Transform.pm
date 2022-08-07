package Commons::Vote::Backend::Transform;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Commons::Vote::Competition;
use Data::Commons::Vote::HashType;
use Data::Commons::Vote::Image;
use Data::Commons::Vote::Section;
use Data::Commons::Vote::Person;
use Data::Commons::Vote::PersonLogin;
use Encode qw(is_utf8);
use Error::Pure qw(err);
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub competition_db2obj {
	my ($self, $comp_db, $sections_ar) = @_;

	$sections_ar ||= [];

	return Data::Commons::Vote::Competition->new(
		'dt_from' => $comp_db->date_from,
		'dt_to' => $comp_db->date_to,
		'id' => $comp_db->competition_id,
		'jury_max_marking_number' => $comp_db->jury_max_marking_number,
		'jury_voting' => $comp_db->jury_voting,
		'logo' => $self->_decode_utf8($comp_db->logo),
		'name' => $self->_decode_utf8($comp_db->name),
		'number_of_votes' => $comp_db->number_of_votes,
		'organizer' => $self->_decode_utf8($comp_db->organizer),
		'organizer_logo' => $self->_decode_utf8($comp_db->organizer_logo),
		'public_voting' => $comp_db->public_voting,
		'sections' => $sections_ar,
	);
}

sub competition_obj2db {
	my ($self, $comp_obj) = @_;

	return {
		'competition_id' => $comp_obj->id,
		'name' => $comp_obj->name,
		'date_from' => $comp_obj->dt_from,
		'date_to' => $comp_obj->dt_to,
		'logo' => $comp_obj->logo,
		'organizer' => $comp_obj->organizer,
		'organizer_logo' => $comp_obj->organizer_logo,
		'public_voting' => $comp_obj->public_voting,
		'number_of_votes' => $comp_obj->number_of_votes,
		'jury_voting' => $comp_obj->jury_voting,
		'jury_max_marking_number' => $comp_obj->jury_max_marking_number,
	};
}

sub hash_type_db2obj {
	my ($self, $hash_type_db) = @_;

	return Data::Commons::Vote::HashType->new(
		'active' => $hash_type_db->active,
		'id' => $hash_type_db->hash_type_id,
		'name' => $hash_type_db->name,
	);
}

sub hash_type_obj2db {
	my ($self, $hash_type_obj) = @_;

	return {
		'hash_type_id' => $hash_type_obj->id,
		'name' => $hash_type_obj->name,
		'active' => $hash_type_obj->active,
	};
}

sub image_db2obj {
	my ($self, $image_db) = @_;

	return Data::Commons::Vote::Image->new(
		'height' => $image_db->height,
		'id' => $image_db->image_id,
		'image' => $self->_decode_utf8($image_db->image),
		'uploader' => $self->person_db2obj($image_db->uploader),
		'width' => $image_db->width,
	);
}

sub image_obj2db {
	my ($self, $image_obj) = @_;

	return {
		'image_id' => $image_obj->id,
		'image' => $image_obj->image,
		'uploader_id' => $image_obj->uploader->id,
		'author' => $image_obj->author,
		'comment' => $image_obj->comment,
		'image_created' => $image_obj->dt_created,
		'width' => $image_obj->width,
		'height' => $image_obj->height,
	};
}

sub person_db2obj {
	my ($self, $person_db) = @_;

	return Data::Commons::Vote::Person->new(
		'first_upload_at' => $person_db->first_upload_at,
		'id' => $person_db->person_id,
		'name' => $self->_decode_utf8($person_db->name),
		'wm_username' => $self->_decode_utf8($person_db->wm_username),
	);
}

sub person_obj2db {
	my ($self, $person_obj) = @_;

	return {
		'person_id' => $person_obj->id,
		'email' => $person_obj->email,
		'name' => $person_obj->name,
		'wm_username' => $person_obj->wm_username,
		'first_upload_at' => $person_obj->first_upload_at,
	};
}

sub person_login_db2obj {
	my ($self, $person_login_db) = @_;

	return Data::Commons::Vote::PersonLogin->new(
		'person' => $self->person_db2obj($person_login_db->person),
		'login' => $person_login_db->login,
		'password' => $person_login_db->password,
		'hash_type' => $self->hash_type_db2obj($person_login_db->hash_type),
	);
}

sub person_login_obj2db {
	my ($self, $person_login_obj) = @_;

	return {
		'person_id' => $person_login_obj->person->id,
		'login' => $person_login_obj->login,
		'password' => $person_login_obj->password,
		'hash_type_id' => $person_login_obj->hash_type->id,
	};
}

sub section_db2obj {
	my ($self, $section_db, $images_ar) = @_;

	$images_ar ||= [];

	return Data::Commons::Vote::Section->new(
		'id' => $section_db->section_id,
		'images' => $images_ar,
		'logo' => $self->_decode_utf8($section_db->logo),
		'name' => $self->_decode_utf8($section_db->name),
		'number_of_votes' => $section_db->number_of_votes,
	);
}

sub section_obj2db {
	my ($self, $section_obj) = @_;

	return {
		'section_id' => $section_obj->id,
		'competition_id' => $section_obj->competition->id,
		'name' => $section_obj->name,
		'logo' => $section_obj->logo,
		'number_of_votes' => $section_obj->number_of_votes,
	};
}

sub section_category_db2obj {
	my ($self, $section_category_db) = @_;

	return Data::Commons::Vote::SectionCategory->new(
		'section' => $self->section_db2obj($section_category_db->section),
		'category' => $section_category_db->category,
	);
}

sub section_category_obj2db {
	my ($self, $section_category_obj) = @_;

	return {
		'section_id' => $section_category_obj->section->id,
		'category' => $section_category_obj->category,
	};
}

sub _decode_utf8 {
	my ($self, $value) = @_;

	if (defined $value) {
		if (is_utf8($value)) {
# XXX Pg is converting this automatically.
			return $value;
#			err "Value '$value' is decoded.";
		} else {
			return decode_utf8($value);
		}
	} else {
		return $value;
	}
}

1;

__END__
