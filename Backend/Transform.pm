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
use DateTime;
use DateTime::Format::Strptime;
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

	$self->{'_dt_parser'} = DateTime::Format::Strptime->new(
		'pattern' => '%FT%T',
		'time_zone' => 'UTC',
	);

	return $self;
}

sub competition_db2obj {
	my ($self, $comp, $sections_ar) = @_;

	$sections_ar ||= [];

	return Data::Commons::Vote::Competition->new(
		'dt_from' => $comp->date_from,
		'dt_to' => $comp->date_to,
		'id' => $comp->competition_id,
		'logo' => $self->_decode_utf8($comp->logo),
		'name' => $self->_decode_utf8($comp->name),
		'number_of_votes' => $comp->number_of_votes,
		'organizer' => $self->_decode_utf8($comp->organizer),
		'organizer_logo' => $self->_decode_utf8($comp->organizer_logo),
		'sections' => $sections_ar,
	);
}

sub hash_type_db2obj {
	my ($self, $hash_type_db) = @_;

	return Data::Commons::Vote::HashType->new(
		'active' => $hash_type_db->active,
		'id' => $hash_type_db->hash_type_id,
		'name' => $hash_type_db->name,
	);
}

sub image_db2obj {
	my ($self, $image) = @_;

	return Data::Commons::Vote::Image->new(
		'height' => $image->height,
		'id' => $image->image_id,
		'image' => $self->_decode_utf8($image->image),
		'uploader' => $self->person_db2obj($image->uploader),
		'width' => $image->width,
	);
}

sub section_db2obj {
	my ($self, $section, $images_ar) = @_;

	$images_ar ||= [];

	return Data::Commons::Vote::Section->new(
		'id' => $section->section_id,
		'images' => $images_ar,
		'logo' => $self->_decode_utf8($section->logo),
		'name' => $self->_decode_utf8($section->name),
		'number_of_votes' => $section->number_of_votes,
	);
}

sub person_db2obj {
	my ($self, $person) = @_;

	return Data::Commons::Vote::Person->new(
		'first_upload_at' => $self->_convert_db_datetime_to_dt($person->first_upload_at),
		'id' => $person->person_id,
		'name' => $self->_decode_utf8($person->name),
		'wm_username' => $self->_decode_utf8($person->wm_username),
	);
}

sub person_login_db2obj {
	my ($self, $person_login_db, $person, $hash_type) = @_;

	return Data::Commons::Vote::PersonLogin->new(
		'person_id' => $person,
		'login' => $person_login_db->login,
		'password' => $person_login_db->password,
		'hash_type' => $hash_type,
	);
}

sub _convert_db_datetime_to_dt {
	my ($self, $db_datetime) = @_;

	if (! defined $db_datetime) {
		return $db_datetime;
	}

	# TODO $db_datetime isn't same.

	my $dt = $self->{'_dt_parser'}->parse_datetime($db_datetime);
	return $dt;
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
