package Commons::Vote::Backend;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Commons::Vote::Backend::Transform;
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

	$self->{'_transform'} = Commons::Vote::Backend::Transform->new;

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

	return $self->{'_transform'}->competition_db2obj($comp,
		[$self->fetch_competition_sections($competition_id)]);
}

sub fetch_competitions {
	my ($self, $opts_hr) = @_;

	return map {
		$self->{'_transform'}->competition_db2obj($_);
	} $self->{'schema'}->resultset('Competition')->search($opts_hr);
}

sub fetch_competition_sections {
	my ($self, $competition_id) = @_;

	my @ret = $self->{'schema'}->resultset('Section')->search({
		'competition_id' => $competition_id,
	});

	return map {
		$self->{'_transform'}->section_db2obj($_,
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

	return $self->{'_transform'}->image_db2obj($image);
}

sub fetch_images {
	my ($self, $opts_hr) = @_;

	return map {
		$self->{'_transform'}->image_db2obj($_);
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

	return $self->{'_transform'}->section_db2obj($section,
		[$self->fetch_section_images($section_id)]);
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

	return $self->{'_transform'}->user_db2obj($user);
}

sub fetch_users {
	my ($self, $opts_hr) = @_;

	return map {
		$self->{'_transform'}->user_db2obj($_);
	} $self->{'schema'}->resultset('User')->search($opts_hr);
}

sub save_competition {
	my ($self, $competition_hr) = @_;

	my $comp = $self->{'schema'}->resultset('Competition')
		->create($competition_hr);

	return defined $comp ? $self->{'_transform'}->competition_db2obj($comp) : undef;
}

sub save_image {
	my ($self, $image_hr) = @_;

	my $image = $self->{'schema'}->resultset('Image')
		->create($image_hr);

	return defined $image ? $self->{'_transform'}->image_db2obj($image) : undef;
}

sub save_section {
	my ($self, $section_hr) = @_;

	my $section = $self->{'schema'}->resultset('Section')
		->create($section_hr);

	return defined $section ? $self->{'_transform'}->section_db2obj($section) : undef;
}

sub save_section_category {
	my ($self, $section_category_hr) = @_;

	my $section_category = $self->{'schema'}->resultset('SectionCategory')
		->create($section_category_hr);

	# TODO Co mam vracet?
	return defined $section_category ? $section_category : undef;
}

sub save_section_image {
	my ($self, $section_image_hr) = @_;

	my $section_image = $self->{'schema'}->resultset('SectionImage')
		->create($section_image_hr);

	# TODO Co vracet?
	return defined $section_image ? $section_image : undef
}

sub save_user {
	my ($self, $user_hr) = @_;

	my $user = $self->{'schema'}->resultset('User')->create($user_hr);

	return defined $user ? $self->{'_transform'}->user_db2obj($user) : undef;
}

1;

__END__
