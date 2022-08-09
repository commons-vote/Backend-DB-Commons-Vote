package Commons::Vote::Backend::Transform;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Commons::Vote::Category;
use Data::Commons::Vote::Competition;
use Data::Commons::Vote::HashType;
use Data::Commons::Vote::Image;
use Data::Commons::Vote::Section;
use Data::Commons::Vote::SectionImage;
use Data::Commons::Vote::Person;
use Data::Commons::Vote::PersonLogin;
use Encode qw(is_utf8);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);
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
		'created_by' => $self->person_db2obj($comp_db->created_by),
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
		$self->_check_value('competition_id', $comp_obj, ['id']),
		$self->_check_value('created_by_id', $comp_obj, ['created_by', 'id']),
		'name' => $comp_obj->name,
		'date_from' => $comp_obj->dt_from,
		'date_to' => $comp_obj->dt_to,
		$self->_check_value('logo', $comp_obj, ['logo']),
		$self->_check_value('organizer', $comp_obj, ['organizer']),
		$self->_check_value('organizer_logo', $comp_obj, ['organizer_logo']),
		$self->_check_value('public_voting', $comp_obj, ['public_voting']),
		$self->_check_value('number_of_votes',  $comp_obj, ['number_of_votes']),
		$self->_check_value('jury_voting', $comp_obj, ['jury_voting']),
		$self->_check_value('jury_max_marking_number', $comp_obj, ['jury_max_marking_number']),
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
		$self->_check_value('hash_type_id', $hash_type_obj, ['id']),
		'name' => $hash_type_obj->name,
		'active' => $hash_type_obj->active,
	};
}

sub image_db2obj {
	my ($self, $image_db) = @_;

	return Data::Commons::Vote::Image->new(
		'created_by' => $self->person_db2obj($image_db->created_by),
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
		$self->_check_value('image_id', $image_obj, ['id']),
		'image' => $image_obj->image,
		'uploader_id' => $image_obj->uploader->id,
		$self->_check_value('author', $image_obj, ['author']),
		$self->_check_value('comment', $image_obj, ['comment']),
		$self->_check_value('created_by_id', $image_obj, ['created_by', 'id']),
		$self->_check_value('image_created', $image_obj, ['dt_created']),
		$self->_check_value('width', $image_obj, ['width']),
		$self->_check_value('height', $image_obj, ['height']),
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
		$self->_check_value('person_id', $person_obj, ['id']),
		$self->_check_value('email', $person_obj, ['email']),
		$self->_check_value('name', $person_obj, ['name']),
		$self->_check_value('wm_username', $person_obj, ['wm_username']),
		$self->_check_value('first_upload_at', $person_obj, ['first_upload_at']),
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
		$self->_check_value('person_id', $person_login_obj, ['person', 'id']),
		$self->_check_value('login', $person_login_obj, ['login']),
		$self->_check_value('password', $person_login_obj, ['password']),
		$self->_check_value('hash_type_id', $person_login_obj, ['hash_type', 'id']),
	};
}

sub section_db2obj {
	my ($self, $section_db) = @_;

	return Data::Commons::Vote::Section->new(
		'categories' => [map { $self->section_category_db2obj($_); } $section_db->section_categories],
		'created_by' => $self->person_db2obj($section_db->created_by),
		'id' => $section_db->section_id,
		'images' => [map { $self->image_db2obj($_->image); } $section_db->section_images],
		'logo' => $self->_decode_utf8($section_db->logo),
		'name' => $self->_decode_utf8($section_db->name),
		'number_of_votes' => $section_db->number_of_votes,
	);
}

sub section_obj2db {
	my ($self, $section_obj) = @_;

	return {
		$self->_check_value('competition_id', $section_obj, ['competition', 'id']),
		$self->_check_value('created_by_id', $section_obj, ['created_by', 'id']),
		'name' => $section_obj->name,
		$self->_check_value('logo', $section_obj, ['logo']),
		$self->_check_value('number_of_votes', $section_obj, ['number_of_votes']),
		$self->_check_value('section_id', $section_obj, ['id']),
	};
}

sub section_category_db2obj {
	my ($self, $section_category_db) = @_;

	return Data::Commons::Vote::Category->new(
		'section_id' => $section_category_db->section_id,
		'category' => $section_category_db->category,
	);
}

sub section_category_obj2db {
	my ($self, $section_category_obj) = @_;

	return {
		'section_id' => $section_category_obj->section_id,
		'category' => $section_category_obj->category,
	};
}

sub section_image_db2obj {
	my ($self, $section_image_db) = @_;

	return Data::Commons::Vote::SectionImage->new(
		'section_id' => $section_image_db->section_id,
		'image' => $self->image_db2obj($section_image_db->image),
	);
}

sub section_image_obj2db {
	my ($self, $section_image_obj) = @_;

	return {
		'section_id' => $section_image_obj->section_id,
		'image_id' => $section_image_obj->image->id,
	};
}

sub _check_value {
	my ($self, $key, $obj, $method_ar) = @_;

	if (! defined $obj) {
		err 'Bad object',
			'Error', 'Object is not defined.',
		;
	}
	if (! blessed($obj)) {
		err 'Bad object.',
			'Error', 'Object in not a instance.',
		;
	}
	my $value = $obj;
	foreach my $method (@{$method_ar}) {
		$value = $value->$method;
		if (! defined $value) {
			return;
		}
	}
	return ($key => $value);
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
