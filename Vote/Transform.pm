package Backend::DB::Commons::Vote::Transform;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Commons::Vote::Category;
use Data::Commons::Vote::Competition;
use Data::Commons::Vote::CompetitionValidation;
use Data::Commons::Vote::CompetitionValidationOption;
use Data::Commons::Vote::CompetitionVoting;
use Data::Commons::Vote::HashType;
use Data::Commons::Vote::Image;
use Data::Commons::Vote::License;
use Data::Commons::Vote::Log;
use Data::Commons::Vote::LogType;
use Data::Commons::Vote::Person;
use Data::Commons::Vote::PersonLogin;
use Data::Commons::Vote::PersonRole;
use Data::Commons::Vote::Role;
use Data::Commons::Vote::Section;
use Data::Commons::Vote::SectionImage;
use Data::Commons::Vote::Theme;
use Data::Commons::Vote::ValidationBad;
use Data::Commons::Vote::ValidationOption;
use Data::Commons::Vote::ValidationType;
use Data::Commons::Vote::Vote;
use Data::Commons::Vote::VotingType;
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
	my ($self, $comp_db, $sections_ar, $validations_ar, $person_roles_ar, $voting_types_ar) = @_;

	$sections_ar ||= [];
	$validations_ar ||= [];
	$person_roles_ar ||= [];
	$voting_types_ar ||= [];

	return Data::Commons::Vote::Competition->new(
		'created_by' => $self->person_db2obj($comp_db->created_by),
		'dt_from' => $comp_db->date_from,
		'dt_images_loaded' => $comp_db->images_loaded_at,
		'dt_jury_voting_from' => $comp_db->jury_voting_date_from,
		'dt_jury_voting_to' => $comp_db->jury_voting_date_to,
		'dt_public_voting_from' => $comp_db->public_voting_date_from,
		'dt_public_voting_to' => $comp_db->public_voting_date_to,
		'dt_to' => $comp_db->date_to,
		'id' => $comp_db->competition_id,
		'jury_max_marking_number' => $comp_db->jury_max_marking_number,
		'jury_voting' => $comp_db->jury_voting,
		'logo' => $self->_decode_utf8($comp_db->logo),
		'name' => $self->_decode_utf8($comp_db->name),
		'number_of_votes' => $comp_db->number_of_votes,
		'organizer' => $self->_decode_utf8($comp_db->organizer),
		'organizer_logo' => $self->_decode_utf8($comp_db->organizer_logo),
		'person_roles' => $person_roles_ar,
		'public_voting' => $comp_db->public_voting,
		'sections' => $sections_ar,
		'validations' => $validations_ar,
		'voting_types' => $voting_types_ar,
		'wd_qid' => $comp_db->wd_qid,
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
		$self->_check_value('public_voting_date_from', $comp_obj, ['dt_public_voting_from']),
		$self->_check_value('public_voting_date_to', $comp_obj, ['dt_public_voting_to']),
		$self->_check_value('number_of_votes',  $comp_obj, ['number_of_votes']),
		$self->_check_value('jury_voting', $comp_obj, ['jury_voting']),
		$self->_check_value('jury_voting_date_from', $comp_obj, ['dt_jury_voting_from']),
		$self->_check_value('jury_voting_date_to', $comp_obj, ['dt_jury_voting_to']),
		$self->_check_value('jury_max_marking_number', $comp_obj, ['jury_max_marking_number']),
		$self->_check_value('images_loaded_at', $comp_obj, ['dt_images_loaded']),
		$self->_check_value('wd_qid', $comp_obj, ['wd_qid']),
	};
}

sub competition_validation_db2obj {
	my ($self, $comp_validation_db, $options_ar) = @_;

	$options_ar ||= [];

	return Data::Commons::Vote::CompetitionValidation->new(
		'competition' => $self->competition_db2obj($comp_validation_db->competition),
		'created_by' => $self->person_db2obj($comp_validation_db->created_by),
		'id' => $comp_validation_db->competition_validation_id,
		'options' => $options_ar,
		'validation_type' => $self->validation_type_db2obj($comp_validation_db->validation_type),
	);
}

sub competition_validation_obj2db {
	my ($self, $competition_validation_obj) = @_;

	return {
		$self->_check_value('competition_id', $competition_validation_obj, ['competition', 'id']),
		$self->_check_value('competition_validation_id', $competition_validation_obj, ['id']),
		$self->_check_value('created_by_id', $competition_validation_obj, ['created_by', 'id']),
		$self->_check_value('validation_type_id', $competition_validation_obj, ['validation_type', 'id']),
	};
}

sub competition_validation_option_db2obj {
	my ($self, $comp_validation_option_db) = @_;

	return Data::Commons::Vote::CompetitionValidationOption->new(
		'competition_validation' => $self->competition_validation_db2obj($comp_validation_option_db->competition_validation),
		'created_by' => $self->person_db2obj($comp_validation_option_db->created_by),
		'id' => $comp_validation_option_db->competition_validation_option_id,
		'validation_option' => $self->validation_option_db2obj($comp_validation_option_db->validation_option),
		'value' => $comp_validation_option_db->value,
	);
}

sub competition_validation_option_obj2db {
	my ($self, $competition_validation_option_obj) = @_;

	return {
		$self->_check_value('competition_validation_option_id', $competition_validation_option_obj, ['id']),
		$self->_check_value('competition_validation_id', $competition_validation_option_obj, ['competition_validation', 'id']),
		$self->_check_value('created_by_id', $competition_validation_option_obj, ['created_by', 'id']),
		$self->_check_value('validation_option_id', $competition_validation_option_obj, ['validation_option', 'id']),
		'value' => $competition_validation_option_obj->value,
	};
}

sub competition_voting_db2obj {
	my ($self, $competition_voting_db) = @_;

	return Data::Commons::Vote::CompetitionVoting->new(
		'competition' => $self->competition_db2obj($competition_voting_db->competition),
		'created_by' => $self->person_db2obj($competition_voting_db->created_by),
		'dt_from' => $competition_voting_db->date_from,
		'dt_to' => $competition_voting_db->date_to,
		'id' => $competition_voting_db->competition_id,
		'number_of_votes' => $competition_voting_db->number_of_votes,
		'voting_type' => $self->voting_type_db2obj($competition_voting_db->voting_type),
	);
}

sub competition_voting_obj2db {
	my ($self, $competition_voting_obj) = @_;

	return {
		$self->_check_value('competition_voting_id', $competition_voting_obj, ['id']),
		$self->_check_value('competition_id', $competition_voting_obj, ['competition', 'id']),
		$self->_check_value('voting_type_id', $competition_voting_obj, ['voting_type', 'id']),
		'date_from' => $competition_voting_obj->dt_from,
		'date_to' => $competition_voting_obj->dt_to,
		$self->_check_value('number_of_votes',  $competition_voting_obj, ['number_of_votes']),
		$self->_check_value('created_by_id', $competition_voting_obj, ['created_by', 'id']),
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

	my $uploader;
	if ($image_db->uploader_id) {
		$uploader = $self->person_db2obj($image_db->uploader);
	}
	return Data::Commons::Vote::Image->new(
		'author' => $self->_decode_utf8($image_db->author),
		'comment' => $self->_decode_utf8($image_db->comment),
		'created_by' => $self->person_db2obj($image_db->created_by),
		'dt_created' => $image_db->image_created,
		'dt_uploaded' => $image_db->image_uploaded,
		'height' => $image_db->height,
		'id' => $image_db->image_id,
		'commons_name' => $self->_decode_utf8($image_db->image),
		'size' => $image_db->size,
		defined $uploader ? ('uploader' => $uploader) : (),
		'width' => $image_db->width,
		defined $image_db->license_id ? ('license_obj' => $self->license_db2obj($image_db->license)) : (),
	);
}

sub image_obj2db {
	my ($self, $image_obj) = @_;

	return {
		$self->_check_value('image_id', $image_obj, ['id']),
		'image' => $image_obj->commons_name,
		$self->_check_value('uploader_id', $image_obj, ['uploader', 'id']),
		$self->_check_value('author', $image_obj, ['author']),
		$self->_check_value('comment', $image_obj, ['comment']),
		$self->_check_value('created_by_id', $image_obj, ['created_by', 'id']),
		$self->_check_value('image_created', $image_obj, ['dt_created']),
		$self->_check_value('image_uploaded', $image_obj, ['dt_uploaded']),
		$self->_check_value('width', $image_obj, ['width']),
		$self->_check_value('height', $image_obj, ['height']),
		$self->_check_value('size', $image_obj, ['size']),
		$self->_check_value('license_id', $image_obj, ['license_obj', 'id']),
	};
}

sub license_db2obj {
	my ($self, $license_db) = @_;

	return Data::Commons::Vote::License->new(
		'created_at' => $license_db->created_at,
		'created_by' => $self->person_db2obj($license_db->created_by),
		'id' => $license_db->license_id,
		'qid' => $license_db->qid,
		'short_name' => $license_db->short_name,
		'text' => $self->_decode_utf8($license_db->text),
	);
}

sub license_obj2db {
	my ($self, $license_obj) = @_;

	return {
		$self->_check_value('license_id', $license_obj, ['id']),
		$self->_check_value('qid', $license_obj, ['qid']),
		$self->_check_value('short_name', $license_obj, ['short_name']),
		$self->_check_value('text', $license_obj, ['text']),
		$self->_check_value('created_by_id', $license_obj, ['created_by', 'id']),
	};
}

sub log_db2obj {
	my ($self, $log_db) = @_;

	return Data::Commons::Vote::Log->new(
		'competition' => $self->competition_db2obj($log_db->competition),
		'created_at' => $log_db->created_at,
		'created_by' => $self->person_db2obj($log_db->created_by),
		'id' => $log_db->log_id,
		'log' => $self->_decode_utf8($log_db->log),
		'log_type' => $self->log_type_db2obj($log_db->log_type),
	);
}

sub log_obj2db {
	my ($self, $log_obj) = @_;

	return {
		$self->_check_value('log_id', $log_obj, ['id']),
		$self->_check_value('log_type_id', $log_obj, ['log_type', 'id']),
		$self->_check_value('competition_id', $log_obj, ['competition', 'id']),
		$self->_check_value('log', $log_obj, ['log']),
		$self->_check_value('created_by_id', $log_obj, ['created_by', 'id']),
	};
}

sub log_type_db2obj {
	my ($self, $log_type_db) = @_;

	return Data::Commons::Vote::LogType->new(
		'created_by' => $self->person_db2obj($log_type_db->created_by),
		'description' => $self->_decode_utf8($log_type_db->description),
		'id' => $log_type_db->log_type_id,
		'type' => $log_type_db->type,
	);
}

sub log_type_obj2db {
	my ($self, $log_type_obj) = @_;

	return {
		'log_type_id' => $log_type_obj->id,
		'type' => $log_type_obj->type,
		$self->_check_value('description', $log_type_obj, ['description']),
		$self->_check_value('created_by_id', $log_type_obj, ['created_by', 'id']),
	};
}

sub person_db2obj {
	my ($self, $person_db) = @_;

	return Data::Commons::Vote::Person->new(
		'email' => $person_db->email,
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

sub person_role_db2obj {
	my ($self, $person_role_db) = @_;

	return Data::Commons::Vote::PersonRole->new(
		'competition' => $self->competition_db2obj($person_role_db->competition),
		'created_by' => $self->person_db2obj($person_role_db->created_by),
		'id' => $person_role_db->person_role_id,
		'person' => $self->person_db2obj($person_role_db->person),
		'role' => $self->role_db2obj($person_role_db->role),
	);
}

sub person_role_obj2db {
	my ($self, $person_role_obj) = @_;

	return {
		$self->_check_value('competition_id', $person_role_obj, ['competition', 'id']),
		$self->_check_value('created_by_id', $person_role_obj, ['created_by', 'id']),
		$self->_check_value('person_role_id', $person_role_obj, ['id']),
		$self->_check_value('person_id', $person_role_obj, ['person', 'id']),
		$self->_check_value('role_id', $person_role_obj, ['role', 'id']),
	};
}

sub role_db2obj {
	my ($self, $role_db) = @_;

	return Data::Commons::Vote::Role->new(
		'id' => $role_db->role_id,
		'name' => $self->_decode_utf8($role_db->name),
		'description' => $self->_decode_utf8($role_db->description),
	);
}

sub role_obj2db {
	my ($self, $role_obj) = @_;

	return {
		$self->_check_value('role_id', $role_obj, ['id']),
		'name' => $role_obj->name,
		$self->_check_value('description', $role_obj, ['description']),
	};
}

sub section_db2obj {
	my ($self, $section_db) = @_;

	return Data::Commons::Vote::Section->new(
		'categories' => [map { $self->section_category_db2obj($_); } $section_db->section_categories],
		'competition' => $self->competition_db2obj($section_db->competition),
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
		'category' => $self->_decode_utf8($section_category_db->category),
		'created_by' => $self->person_db2obj($section_category_db->created_by),
		'section_id' => $section_category_db->section_id,
	);
}

sub section_category_obj2db {
	my ($self, $section_category_obj) = @_;

	return {
		'section_id' => $section_category_obj->section_id,
		$self->_check_value('created_by_id', $section_category_obj, ['created_by', 'id']),
		'category' => $section_category_obj->category,
	};
}

sub section_image_db2obj {
	my ($self, $section_image_db) = @_;

	return Data::Commons::Vote::SectionImage->new(
		'created_by' => $self->person_db2obj($section_image_db->created_by),
		'image' => $self->image_db2obj($section_image_db->image),
		'section_id' => $section_image_db->section_id,
	);
}

sub section_image_obj2db {
	my ($self, $section_image_obj) = @_;

	return {
		'section_id' => $section_image_obj->section_id,
		'image_id' => $section_image_obj->image->id,
		$self->_check_value('created_by_id', $section_image_obj, ['created_by', 'id']),
	};
}

sub theme_db2obj {
	my ($self, $theme_db) = @_;

	return Data::Commons::Vote::Theme->new(
		'created_by' => $self->person_db2obj($theme_db->created_by),
		'id' => $theme_db->theme_id,
		'images' => [map { $self->image_db2obj($_->image); } $theme_db->theme_images],
		'shortcut' => $self->_decode_utf8($theme_db->shortcut),
		'name' => $self->_decode_utf8($theme_db->name),
	);
}

sub theme_obj2db {
	my ($self, $theme_obj) = @_;

	return {
		$self->_check_value('created_by_id', $theme_obj, ['created_by', 'id']),
		'name' => $theme_obj->name,
		$self->_check_value('shortcut', $theme_obj, ['shortcut']),
		$self->_check_value('theme_id', $theme_obj, ['id']),
	};
}

sub theme_image_db2obj {
	my ($self, $theme_image_db) = @_;

	return Data::Commons::Vote::ThemeImage->new(
		'created_by' => $self->person_db2obj($theme_image_db->created_by),
		'image' => $self->image_db2obj($theme_image_db->image),
		'theme_id' => $theme_image_db->theme_id,
	);
}

sub theme_image_obj2db {
	my ($self, $theme_image_obj) = @_;

	return {
		'theme_id' => $theme_image_obj->theme_id,
		'image_id' => $theme_image_obj->image->id,
		$self->_check_value('created_by_id', $theme_image_obj, ['created_by', 'id']),
	};
}

sub validation_bad_db2obj {
	my ($self, $validation_bad_db) = @_;

	return Data::Commons::Vote::ValidationBad->new(
		'created_by' => $self->person_db2obj($validation_bad_db->created_by),
		'competition' => $self->competition_db2obj($validation_bad_db->competition),
		'image' => $self->image_db2obj($validation_bad_db->image),
		'validation_type' => $self->validation_type_db2obj($validation_bad_db->validation_type),
	);
}

sub validation_bad_obj2db {
	my ($self, $validation_bad_obj) = @_;

	return {
		'competition_id' => $validation_bad_obj->competition->id,
		'image_id' => $validation_bad_obj->image->id,
		'validation_type_id' => $validation_bad_obj->validation_type->id,
		$self->_check_value('created_by_id', $validation_bad_obj, ['created_by', 'id']),
	};
}

sub validation_option_db2obj {
	my ($self, $validation_option_db) = @_;

	return Data::Commons::Vote::ValidationOption->new(
		'created_by' => $self->person_db2obj($validation_option_db->created_by),
		'description' => $self->_decode_utf8($validation_option_db->description),
		'id' => $validation_option_db->validation_option_id,
		'option' => $validation_option_db->option,
		'option_type' => $validation_option_db->option_type,
		'validation_type' => $self->validation_type_db2obj($validation_option_db->validation_type),
	);
}

sub validation_type_db2obj {
	my ($self, $validation_type_db) = @_;

	return Data::Commons::Vote::ValidationType->new(
		'created_by' => $self->person_db2obj($validation_type_db->created_by),
		'description' => $self->_decode_utf8($validation_type_db->description),
		'id' => $validation_type_db->validation_type_id,
		'type' => $validation_type_db->type,
	);
}

sub vote_db2obj {
	my ($self, $vote_db) = @_;

	return Data::Commons::Vote::Vote->new(
		'competition' => $self->competition_db2obj($vote_db->competition),
		'image' => $self->image_db2obj($vote_db->image),
		'person' => $self->person_db2obj($vote_db->person),
		'voting_type' => $self->voting_type_db2obj($vote_db->voting_type),
		'vote_value' => $vote_db->vote_value,
	);
}

sub vote_obj2db {
	my ($self, $vote_obj) = @_;

	return {
		$self->_check_value('competition_id', $vote_obj, ['competition', 'id']),
		$self->_check_value('image_id', $vote_obj, ['image', 'id']),
		$self->_check_value('person_id', $vote_obj, ['person', 'id']),
		$self->_check_value('voting_type_id', $vote_obj, ['voting_type', 'id']),
		$self->_check_value('vote_value', $vote_obj, ['vote_value']),
	};
}

sub voting_type_db2obj {
	my ($self, $voting_type_db) = @_;

	return Data::Commons::Vote::VotingType->new(
		'created_by' => $self->person_db2obj($voting_type_db->created_by),
		'description' => $self->_decode_utf8($voting_type_db->description),
		'id' => $voting_type_db->voting_type_id,
		'type' => $voting_type_db->type,
	);
}

sub voting_type_obj2db {
	my ($self, $voting_type_obj) = @_;

	return {
		'voting_type_id' => $voting_type_obj->id,
		'type' => $voting_type_obj->type,
		$self->_check_value('description', $voting_type_obj, ['description']),
		$self->_check_value('created_by_id', $voting_type_obj, ['created_by', 'id']),
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
