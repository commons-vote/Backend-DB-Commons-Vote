package Commons::Vote::Backend;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Commons::Vote::Backend::Transform;
use English;
use Error::Pure qw(err);
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Database schema instance.
	$self->{'schema'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Check schema.
	if (! defined $self->{'schema'}) {
		err "Parameter 'schema' is required.";
	}
	if (! $self->{'schema'}->isa('Schema::Commons::Vote')) {
		err "Parameter 'schema' must be 'Schema::Commons::Vote' instance.";
	}

	# Transform object.
	$self->{'_transform'} = Commons::Vote::Backend::Transform->new;

	return $self;
}

sub fetch_competition {
	my ($self, $competition_id) = @_;

	my $comp = $self->{'schema'}->resultset('Competition')->search({
		'competition_id' => $competition_id,
	})->single;

	return unless defined $comp;
	return $self->{'_transform'}->competition_db2obj($comp,
		[$self->fetch_competition_sections($competition_id)]);
}

sub fetch_competitions {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->competition_db2obj($_);
	} $self->{'schema'}->resultset('Competition')->search($cond_hr, $attr_hr);
}

sub fetch_competition_sections {
	my ($self, $competition_id) = @_;

	if (! $competition_id) {
		return ();
	}

	my @ret = $self->{'schema'}->resultset('Section')->search({
		'competition_id' => $competition_id,
	});

	return map {
		$self->{'_transform'}->section_db2obj($_,
			[$self->fetch_section_images($_->section_id)]);
	} @ret;
}

sub fetch_hash_type {
	my ($self, $hash_type_id) = @_;

	my $hash_type = $self->{'schema'}->resultset('HashType')->search({
		'hash_type_id' => $hash_type_id,
	})->single;

	return unless defined $hash_type;
	return $self->{'_transform'}->hash_type_db2obj($hash_type);
}

sub fetch_hash_type_name {
	my ($self, $hash_type_name) = @_;

	my $hash_type = $self->{'schema'}->resultset('HashType')->search({
		'name' => $hash_type_name,
	})->single;

	return unless defined $hash_type;
	return $self->{'_transform'}->hash_type_db2obj($hash_type);
}

sub fetch_image {
	my ($self, $image_id) = @_;

	my $image_db = $self->{'schema'}->resultset('Image')->search({
		'image_id' => $image_id,
	})->single;

	return unless defined $image_db;
	return $self->{'_transform'}->image_db2obj($image_db);
}

sub fetch_images {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->image_db2obj($_);
	} $self->{'schema'}->resultset('Image')->search($cond_hr, $attr_hr);
}

sub fetch_section {
	my ($self, $section_id) = @_;

	my $section = $self->{'schema'}->resultset('Section')->search({
		'section_id' => $section_id,
	})->single;

	return unless defined $section;
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

sub fetch_person {
	my ($self, $cond_hr) = @_;

	my $person = $self->{'schema'}->resultset('Person')->search($cond_hr)->single;

	return unless defined $person;
	return $self->{'_transform'}->person_db2obj($person);
}

sub fetch_person_login {
	my ($self, $login) = @_;

	my $person_login = $self->{'schema'}->resultset('PersonLogin')->search({
		'login' => $login,
	})->single;

	return unless defined $person_login;
	return $self->{'_transform'}->person_login_db2obj($person_login);
}

sub fetch_people {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->person_db2obj($_);
	} $self->{'schema'}->resultset('Person')->search($cond_hr, $attr_hr);
}

sub save_competition {
	my ($self, $competition_hr) = @_;

	my $comp = $self->{'schema'}->resultset('Competition')
		->create($competition_hr);

	return unless defined $comp;
	return $self->{'_transform'}->competition_db2obj($comp);
}

sub save_hash_type {
	my ($self, $hash_type) = @_;

	if (! $hash_type->isa('Data::Commons::Vote::HashType')) {
		err "Hash type object must be a 'Data::Commons::Vote::HashType' instance.";
	}

	my $hash_type_db = eval {
		$self->{'schema'}->resultset('HashType')->create({
			'active' => $hash_type->active,
			'name' => $hash_type->name,
		});
	};
	if ($EVAL_ERROR) {
		err "Cannot save hash type.",
			'Error', $EVAL_ERROR;
	}

	return unless defined $hash_type_db;
	return $self->{'_transform'}->hash_type_db2obj($hash_type_db);
}

sub save_image {
	my ($self, $image_hr) = @_;

	my $image = $self->{'schema'}->resultset('Image')
		->create($image_hr);

	return unless defined $image;
	return $self->{'_transform'}->image_db2obj($image);
}

sub save_section {
	my ($self, $section_hr) = @_;

	my $section = $self->{'schema'}->resultset('Section')
		->create($section_hr);

	return unless defined $section;
	return $self->{'_transform'}->section_db2obj($section);
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

sub fetch_sections {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->section_db2obj($_);
	} $self->{'schema'}->resultset('Section')->search($cond_hr, $attr_hr);
}

sub save_person {
	my ($self, $person_hr) = @_;

	my $person = $self->{'schema'}->resultset('Person')->create($person_hr);

	return unless defined $person;
	return $self->{'_transform'}->person_db2obj($person);
}

1;

__END__
