package Commons::Vote::Backend;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Commons::Vote::Competition;
use Data::Commons::Vote::Image;
use Data::Commons::Vote::Section;
use Data::Commons::Vote::User;
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

	$self->{'schema'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'schema'}) {
		err "Parameter 'schema' is required.";
	}
	if (! $self->{'schema'}->isa('Schema::Commons::Vote')) {
		err "Parameter 'schema' must be 'Schema::Commons::Vote' instance.";
	}

	$self->{'_dt_parser'} = DateTime::Format::Strptime->new(
		'pattern' => '%FT%T',
		'time_zone' => 'UTC',
	);

	return $self;
}

sub fetch_competition {
	my ($self, $competition_id) = @_;

	my $comp = $self->{'schema'}->resultset('Competition')->search({
		'competition_id' => $competition_id,
	})->single;

	if (! defined $comp) {
		return;
	}

	return $self->_construct_competition($comp,
		[$self->fetch_competition_sections($competition_id)]);
}

sub fetch_competitions {
	my ($self, $opts_hr) = @_;

	return map {
		$self->_construct_competition($_);
	} $self->{'schema'}->resultset('Competition')->search($opts_hr);
}

sub fetch_competition_sections {
	my ($self, $competition_id) = @_;

	my @ret = $self->{'schema'}->resultset('Section')->search({
		'competition_id' => $competition_id,
	});

	return map {
		$self->_construct_section($_,
			[$self->fetch_section_images($_->section_id)]);
	} @ret;
}

sub fetch_image {
	my ($self, $image_id) = @_;

	my $image = $self->{'schema'}->resultset('Image')->search({
		'image_id' => $image_id,
	})->single;

	if (! defined $image) {
		return;
	}

	return $self->_construct_image($image);
}

sub fetch_images {
	my ($self, $opts_hr) = @_;

	return map {
		$self->_construct_image($_);
	} $self->{'schema'}->resultset('Image')->search($opts_hr);
}

sub fetch_section {
	my ($self, $section_id) = @_;

	my $section = $self->{'schema'}->resultset('Section')->search({
		'section_id' => $section_id,
	})->single;

	if (! defined $section) {
		return;
	}

	return $self->_construct_section($section);
}

sub fetch_section_categories {
	my ($self, $section_id) = @_;

	my @ret = $self->{'schema'}->resultset('SectionCategory')->search({
		'section_id' => $section_id,
	});

	return map { decode_utf8($_->category) } @ret;
}

sub fetch_section_images {
	my ($self, $section_id) = @_;

	my @ret = $self->{'schema'}->resultset('SectionImage')->search({
		'section_id' => $section_id,
	});

	return map {
		$self->fetch_image($_->image_id);
	} @ret;
}

sub fetch_user {
	my ($self, $user_id) = @_;

	my $user = $self->{'schema'}->resultset('User')->search({
		'user_id' => $user_id,
	})->single;

	if (! defined $user) {
		return;
	}

	return $self->_construct_user($user);
}

sub fetch_users {
	my ($self, $opts_hr) = @_;

	return map {
		$self->_construct_user($_);
	} $self->{'schema'}->resultset('User')->search($opts_hr);
}

sub _construct_competition {
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

sub _construct_image {
	my ($self, $image) = @_;

	return Data::Commons::Vote::Image->new(
		'height' => $image->height,
		'id' => $image->image_id,
		'image' => $self->_decode_utf8($image->image),
		'uploader' => $self->_construct_user($image->uploader),
		'width' => $image->width,
	);
}

sub _construct_section {
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

sub _construct_user {
	my ($self, $user) = @_;

	return Data::Commons::Vote::User->new(
		'first_upload_at' => $self->_convert_db_datetime_to_dt($user->first_upload_at),
		'id' => $user->user_id,
		'name' => $self->_decode_utf8($user->name),
		'wm_username' => $self->_decode_utf8($user->wm_username),
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
