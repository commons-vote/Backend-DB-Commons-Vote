package Backend::DB::Commons::Vote;

use base qw(Backend::DB);
use strict;
use warnings;

use Backend::DB::Commons::Vote::Transform;
use Class::Utils qw(set_params);
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
	if (! $self->{'schema'}->isa('Schema::Commons::Vote::0_1_0')) {
		err "Parameter 'schema' must be 'Schema::Commons::Vote::0_1_0' instance.";
	}

	# Transform object.
	$self->{'_transform'} = Backend::DB::Commons::Vote::Transform->new;

	return $self;
}

sub delete_competition {
	my ($self, $competition_id) = @_;

	my $comp_db = $self->{'schema'}->resultset('Competition')->search({
		'competition_id' => $competition_id,
	})->single;
	$comp_db->delete;

	return $self->{'_transform'}->competition_db2obj($comp_db);
}

sub delete_section {
	my ($self, $section_id) = @_;

	my $section_db = $self->{'schema'}->resultset('Section')->search({
		'section_id' => $section_id,
	})->single;
	$section_db->delete;

	return $self->{'_transform'}->section_db2obj($section_db);
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

	my $hash_type_db = $self->{'schema'}->resultset('HashType')->search({
		'hash_type_id' => $hash_type_id,
	})->single;

	return unless defined $hash_type_db;
	return $self->{'_transform'}->hash_type_db2obj($hash_type_db);
}

sub fetch_hash_type_name {
	my ($self, $hash_type_name) = @_;

	my $hash_type_db = $self->{'schema'}->resultset('HashType')->search({
		'name' => $hash_type_name,
	})->single;

	return unless defined $hash_type_db;
	return $self->{'_transform'}->hash_type_db2obj($hash_type_db);
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

sub fetch_person {
	my ($self, $cond_hr) = @_;

	my $person_db = $self->{'schema'}->resultset('Person')->search($cond_hr)->single;

	return unless defined $person_db;
	return $self->{'_transform'}->person_db2obj($person_db);
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

sub fetch_role {
	my ($self, $role_name) = @_;

	my $role_db = $self->{'schema'}->resultset('Role')->search({
		'name' => $role_name,
	})->single;

	return unless defined $role_db;
	return $self->{'_transform'}->role_db2obj($role_db);
}
sub fetch_section {
	my ($self, $section_id) = @_;

	my $section_db = $self->{'schema'}->resultset('Section')->search({
		'section_id' => $section_id,
	})->single;

	return unless defined $section_db;
	return $self->{'_transform'}->section_db2obj($section_db);
}

sub fetch_section_categories {
	my ($self, $section_id) = @_;

	my @ret = $self->{'schema'}->resultset('SectionCategory')->search({
		'section_id' => $section_id,
	});

	return map { $_->category } @ret;
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

sub fetch_sections {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->section_db2obj($_);
	} $self->{'schema'}->resultset('Section')->search($cond_hr, $attr_hr);
}

sub fetch_vote_type {
	my ($self, $cond_hr) = @_;

	my $vote_type_db = $self->{'schema'}->resultset('VoteType')
		->search($cond_hr)->single;

	return unless defined $vote_type_db;
	return $self->{'_transform'}->vote_type_db2obj($vote_type_db);
}

sub save_competition {
	my ($self, $competition_obj) = @_;

	my $comp_db = $self->{'schema'}->resultset('Competition')->create(
		$self->{'_transform'}->competition_obj2db($competition_obj),
	);

	return unless defined $comp_db;
	return $self->{'_transform'}->competition_db2obj($comp_db);
}

sub save_hash_type {
	my ($self, $hash_type_obj) = @_;

	if (! $hash_type_obj->isa('Data::Commons::Vote::HashType')) {
		err "Hash type object must be a 'Data::Commons::Vote::HashType' instance.";
	}

	my $hash_type_db = eval {
		$self->{'schema'}->resultset('HashType')->create(
			$self->{'_transform'}->hash_type_obj2db($hash_type_obj),
		);
	};
	if ($EVAL_ERROR) {
		err "Cannot save hash type.",
			'Error', $EVAL_ERROR;
	}

	return unless defined $hash_type_db;
	return $self->{'_transform'}->hash_type_db2obj($hash_type_db);
}

sub save_image {
	my ($self, $image_obj) = @_;

	my $image_db = $self->{'schema'}->resultset('Image')->create(
		$self->{'_transform'}->image_obj2db($image_obj),
	);

	return unless defined $image_db;
	return $self->{'_transform'}->image_db2obj($image_db);
}

sub save_person {
	my ($self, $person_obj) = @_;

	my $person_db = $self->{'schema'}->resultset('Person')->create(
		$self->{'_transform'}->person_obj2db($person_obj),
	);

	return unless defined $person_db;
	return $self->{'_transform'}->person_db2obj($person_db);
}

sub save_person_role {
	my ($self, $person_role_obj) = @_;

	my $person_role_db = $self->{'schema'}->resultset('PersonRole')->create(
		$self->{'_transform'}->person_role_obj2db($person_role_obj),
	);

	return unless defined $person_role_db;
	return $self->{'_transform'}->person_role_db2obj($person_role_db);
}

sub save_section {
	my ($self, $section_obj) = @_;

	my $section_db = $self->{'schema'}->resultset('Section')->create(
		$self->{'_transform'}->section_obj2db($section_obj),
	);

	return unless defined $section_db;
	return $self->{'_transform'}->section_db2obj($section_db);
}

sub save_section_category {
	my ($self, $section_category_obj) = @_;

	my $section_category_db = $self->{'schema'}->resultset('SectionCategory')->create(
		$self->{'_transform'}->section_category_obj2db($section_category_obj),
	);

	return unless defined $section_category_db;
	return $self->{'_transform'}->section_category_db2obj($section_category_db);
}

sub save_section_image {
	my ($self, $section_image_obj) = @_;

	my $section_image_db = $self->{'schema'}->resultset('SectionImage')->create(
		$self->{'_transform'}->section_image_obj2db($section_image_obj),
	);

	return unless defined $section_image_db;
	return $self->{'_transform'}->section_image_db2obj($section_image_db);
}

sub save_vote {
	my ($self, $vote_obj) = @_;

	my $vote_db = $self->{'schema'}->resultset('Vote')->create(
		$self->{'_transform'}->vote_obj2db($vote_obj),
	);

	return unless defined $vote_db;
	return $self->{'_transform'}->vote_db2obj($vote_db);
}

sub save_vote_type {
	my ($self, $vote_type_obj) = @_;

	my $vote_type_db = $self->{'schema'}->resultset('VoteType')->create(
		$self->{'_transform'}->vote_type_obj2db($vote_type_obj),
	);

	return unless defined $vote_type_db;
	return $self->{'_transform'}->vote_type_db2obj($vote_type_db);
}

1;

__END__
