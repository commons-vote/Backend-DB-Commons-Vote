package Commons::Vote::Backend::Transform;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Commons::Vote::Competition;
use Data::Commons::Vote::HashType;
use Data::Commons::Vote::Image;
use Data::Commons::Vote::Section;
use Data::Commons::Vote::User;
use Data::Commons::Vote::UserLogin;
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
		'dt_from' => $self->_convert_db_date_to_dt($comp->date_from),
		'dt_to' => $self->_convert_db_date_to_dt($comp->date_to),
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
		'uploader' => $self->user_db2obj($image->uploader),
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

sub user_db2obj {
	my ($self, $user) = @_;

	return Data::Commons::Vote::User->new(
		'first_upload_at' => $self->_convert_db_datetime_to_dt($user->first_upload_at),
		'id' => $user->user_id,
		'name' => $self->_decode_utf8($user->name),
		'wm_username' => $self->_decode_utf8($user->wm_username),
	);
}

sub user_login_db2obj {
	my ($self, $user_login_db, $user, $hash_type) = @_;

	return Data::Commons::Vote::UserLogin->new(
		'user_id' => $user,
		'login' => $user_login_db->login,
		'password' => $user_login_db->password,
		'hash_type' => $hash_type,
	);
}

sub _convert_db_date_to_dt {
	my ($self, $db_date) = @_;

	my ($year, $month, $day) = split m/-/ms, $db_date;

	my $dt = DateTime->new(
		'year' => $year,
		'month' => $month,
		'day' => $day,
	);

	return $dt;
}

sub _convert_db_datetime_to_dt {
	my ($self, $db_datetime) = @_;

	if (! defined $db_datetime) {
		return $db_datetime;
	}

	return $self->{'_dt_parser'}->parse_datetime($db_datetime),
}


sub _decode_utf8 {
	my ($self, $value) = @_;

	if (defined $value) {
		if (is_utf8($value)) {
			err "Value '$value' is decoded.";
		} else {
			return decode_utf8($value);
		}
	} else {
		return $value;
	}
}

1;

__END__
