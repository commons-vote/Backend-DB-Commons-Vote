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

sub count_competition {
	my ($self, $cond_hr) = @_;

	return $self->{'schema'}->resultset('Competition')->search($cond_hr)->count;
}

sub count_competition_images {
	my ($self, $competition_id) = @_;

	my $count = $self->{'schema'}->resultset('SectionImage')->search({
		'section.competition_id' => $competition_id,
	}, {
		'join' => 'section',
	})->count;

	return $count;
}

sub count_competition_images_valid {
	my ($self, $competition_id) = @_;

	my $count = $self->{'schema'}->resultset('SectionImage')->search({
		'section.competition_id' => $competition_id,
		'image_id' => {
			-not_in => \[
				'SELECT image_id FROM validation_bad WHERE competition_id = ?',
				$competition_id,
			],
		},
	}, {
		'join' => 'section',
	})->count;

	return $count;
}

sub count_competition_sections {
	my ($self, $competition_id) = @_;

	my $count = $self->{'schema'}->resultset('Section')->search({
		'competition_id' => $competition_id,
	})->count;

	return $count;
}

sub count_competition_voting {
	my ($self, $cond_hr) = @_;

	return $self->{'schema'}->resultset('CompetitionVoting')->search($cond_hr)->count;
}

sub count_competition_voting_by_now {
	my ($self, $cond_hr) = @_;

	my $dtf = $self->{'schema'}->storage->datetime_parser;
	return $self->{'schema'}->resultset('CompetitionVoting')->search({
		%{$cond_hr},
		'date_to' => { '>=' => $dtf->format_datetime(DateTime->now) },
	})->count;
}

sub count_image {
	my ($self, $image_id) = @_;

	my $count = $self->{'schema'}->resultset('Image')->search({
		'image_id' => $image_id,
	})->count;

	return $count;
}

sub count_section_images {
	my ($self, $section_id) = @_;

	my $count = $self->{'schema'}->resultset('SectionImage')->search({
		'section_id' => $section_id,
	})->count;

	return $count;
}

sub count_person_role {
	my ($self, $cond_hr) = @_;

	return $self->{'schema'}->resultset('PersonRole')->search($cond_hr)->count;
}

sub count_validation_bad {
	my ($self, $cond_hr) = @_;

	return $self->{'schema'}->resultset('ValidationBad')->search($cond_hr)->count;
}

sub count_vote {
	my ($self, $cond_hr) = @_;

	return $self->{'schema'}->resultset('Vote')->search($cond_hr)->count;
}

sub delete_competition {
	my ($self, $competition_id) = @_;

	my $comp_db = $self->{'schema'}->resultset('Competition')->search({
		'competition_id' => $competition_id,
	})->single;
	$comp_db->delete;

	return $self->{'_transform'}->competition_db2obj($comp_db);
}

sub delete_competition_validation {
	my ($self, $competition_validation_id) = @_;

	my $competition_validation_db = $self->{'schema'}->resultset('CompetitionValidation')->search({
		'competition_validation_id' => $competition_validation_id,
	})->single;
	$competition_validation_db->delete;

	return $self->{'_transform'}->competition_validation_db2obj($competition_validation_db);
}

sub delete_competition_validation_options {
	my ($self, $competition_validation_id) = @_;

	my @competition_validation_options = $self->{'schema'}->resultset('CompetitionValidationOption')->search({
		'competition_validation_id' => $competition_validation_id,
	});

	foreach my $competition_validation_option (@competition_validation_options) {
		$competition_validation_option->delete;
	}

	return scalar @competition_validation_options;
}

sub delete_competition_voting {
	my ($self, $competition_voting_id) = @_;

	my $competition_voting_db = $self->{'schema'}->resultset('CompetitionVoting')->search({
		'competition_voting_id' => $competition_voting_id,
	})->single;
	$competition_voting_db->delete;

	return $self->{'_transform'}->competition_voting_db2obj($competition_voting_db);
}

sub delete_person_role {
	my ($self, $cond_hr) = @_;

	my $person_role_db = $self->{'schema'}->resultset('PersonRole')->search($cond_hr)->single;
	$person_role_db->delete;

	return $self->{'_transform'}->person_role_db2obj($person_role_db);
}

sub delete_section {
	my ($self, $section_id) = @_;

	my $section_db = $self->{'schema'}->resultset('Section')->search({
		'section_id' => $section_id,
	})->single;
	$section_db->delete;

	return $self->{'_transform'}->section_db2obj($section_db);
}

sub delete_section_images {
	my ($self, $section_id) = @_;

	my @section_images = $self->{'schema'}->resultset('SectionImage')->search({
		'section_id' => $section_id,
	});

	foreach my $section_image (@section_images) {
		$section_image->delete;
	}

	return scalar @section_images;
}

sub delete_validation_bads {
	my ($self, $cond_hr) = @_;

	my @validation_bads = $self->{'schema'}->resultset('ValidationBad')->search($cond_hr)->delete;

	return scalar @validation_bads;
}

sub delete_vote {
	my ($self, $cond_hr) = @_;

	my @votes = $self->{'schema'}->resultset('Vote')->search($cond_hr)->delete;

	return scalar @votes;
}

sub fetch_competition {
	my ($self, $cond_hr, $attr_hr, $opts_hr) = @_;

	my $competition_db = $self->{'schema'}->resultset('Competition')->search($cond_hr, $attr_hr)->single;

	return unless defined $competition_db;
	return $self->{'_transform'}->competition_db2obj($competition_db,
		[$opts_hr->{'sections'}
			? $self->fetch_competition_sections({
				'competition_id' => $competition_db->competition_id,
			}, {}, $opts_hr)
			: (),
		],
		[$opts_hr->{'validations'}
			? $self->fetch_competition_validations($competition_db->competition_id)
			: (),
		],
		[$opts_hr->{'person_roles'}
			? $self->fetch_competition_person_roles($competition_db->competition_id)
			: (),
		],
		[$opts_hr->{'votings'}
			? $self->fetch_competition_votings({
				'competition_id' => $competition_db->competition_id,
			}) : (),
		],
	);
}

sub fetch_competition_images {
	my ($self, $competition_id, $attr_hr) = @_;

	my @ret = $self->{'schema'}->resultset('SectionImage')->search({
		'section.competition_id' => $competition_id,
	}, {
		'columns' => ['image_id'],
		'distinct' => 1,
		'join' => 'section',
		%{$attr_hr},
	});

	return map {
		$self->fetch_image($_->image_id);
	} @ret;
}

sub fetch_competition_images_valid {
	my ($self, $competition_id, $attr_hr) = @_;

	my @ret = $self->{'schema'}->resultset('SectionImage')->search({
		'section.competition_id' => $competition_id,
		'image_id' => {
			-not_in => \[
				'SELECT image_id FROM validation_bad WHERE competition_id = ?',
				$competition_id,
			],
		},
	}, {
		'columns' => ['image_id'],
		'distinct' => 1,
		'join' => 'section',
		%{$attr_hr},
	});

	return map {
		$self->fetch_image($_->image_id);
	} @ret;
}

sub fetch_competition_person_roles {
	my ($self, $competition_id) = @_;

	if (! $competition_id) {
		return ();
	}

	my @comp_person_roles_db = $self->{'schema'}->resultset('PersonRole')->search({
		'competition_id' => $competition_id,
	});

	return map {
		$self->{'_transform'}->person_role_db2obj($_);
	} @comp_person_roles_db;
}

sub fetch_competition_validation {
	my ($self, $competition_validation_id) = @_;

	my $comp_validation_db = $self->{'schema'}->resultset('CompetitionValidation')->search({
		'competition_validation_id' => $competition_validation_id,
	})->single;

	return unless defined $comp_validation_db;
	return $self->{'_transform'}->competition_validation_db2obj($comp_validation_db,
		 [$self->fetch_competition_validation_options($competition_validation_id)]);
}

sub fetch_competition_validations {
	my ($self, $competition_id) = @_;

	if (! $competition_id) {
		return ();
	}

	my @comp_validations_db = $self->{'schema'}->resultset('CompetitionValidation')->search({
		'competition_id' => $competition_id,
	});

	return map {
		$self->{'_transform'}->competition_validation_db2obj($_,
			[$self->fetch_competition_validation_options($_->competition_validation_id)]);
	} @comp_validations_db;
}

sub fetch_competition_validation_options {
	my ($self, $competition_validation_id) = @_;

	if (! $competition_validation_id) {
		return ();
	}

	my @ret = $self->{'schema'}->resultset('CompetitionValidationOption')->search({
		'competition_validation_id' => $competition_validation_id,
	});

	return map {
		$self->{'_transform'}->competition_validation_option_db2obj($_);
	} @ret;
}

sub fetch_competition_voting {
	my ($self, $cond_hr, $attr_hr) = @_;

	my $competition_voting_db = $self->{'schema'}->resultset('CompetitionVoting')->search($cond_hr, $attr_hr)->single;

	return unless defined $competition_voting_db;
	return $self->{'_transform'}->competition_voting_db2obj($competition_voting_db);
}

sub fetch_competition_votings {
	my ($self, $cond_hr, $attr_hr) = @_;

	my @comp_votings_db = $self->{'schema'}->resultset('CompetitionVoting')->search($cond_hr, $attr_hr);

	return map {
		$self->{'_transform'}->competition_voting_db2obj($_);
	} @comp_votings_db;
}

sub fetch_competitions {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->competition_db2obj($_);
	} $self->{'schema'}->resultset('Competition')->search($cond_hr, $attr_hr);
}

sub fetch_competition_sections {
	my ($self, $cond_hr, $attr_hr, $opts_hr) = @_;

	my @ret = $self->{'schema'}->resultset('Section')->search($cond_hr, $attr_hr);

	return map {
		$self->{'_transform'}->section_db2obj($_, $opts_hr);
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

sub fetch_image_next {
	my ($self, $image_id) = @_;

	# TODO Combine this two select to one?
	my $image_min_db = $self->{'schema'}->resultset('Image')->search({
		'image_id' => {'>', $image_id},
	}, {
		'columns' => [
			{'next_image_id' => {'min' => 'image_id'}},
		],
	})->single;
	return unless defined $image_min_db;

	my $image_db = $self->{'schema'}->resultset('Image')->search({
		'image_id' => $image_min_db->get_column('next_image_id'),
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

sub fetch_license_by_qid {
	my ($self, $qid) = @_;

	my $license_db = $self->{'schema'}->resultset('License')->search({
		'qid' => $qid,
	})->single;

	return unless defined $license_db;
	return $self->{'_transform'}->license_db2obj($license_db);
}

sub fetch_log {
	my ($self, $log_id) = @_;

	my $log_db = $self->{'schema'}->resultset('Log')->search({
		'log_id' => $log_id,
	})->single;

	return unless defined $log_db;
	return $self->{'_transform'}->log_db2obj($log_db);
}

sub fetch_logs {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->log_db2obj($_);
	} $self->{'schema'}->resultset('Log')->search($cond_hr, $attr_hr);
}

sub fetch_log_type_name {
	my ($self, $log_type_name) = @_;

	my $log_type_db = $self->{'schema'}->resultset('LogType')->search({'type' => $log_type_name})->single;

	return unless $log_type_db;
	return $self->{'_transform'}->log_type_db2obj($log_type_db);
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

sub fetch_person_role {
	my ($self, $cond_hr) = @_;

	my $person_role_db = $self->{'schema'}->resultset('PersonRole')->search($cond_hr)->single;

	return unless defined $person_role_db;
	return $self->{'_transform'}->person_role_db2obj($person_role_db);
}

sub fetch_person_roles {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->person_role_db2obj($_);
	} $self->{'schema'}->resultset('PersonRole')->search($cond_hr, $attr_hr);
}

sub fetch_people {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->person_db2obj($_);
	} $self->{'schema'}->resultset('Person')->search($cond_hr, $attr_hr);
}

sub fetch_role {
	my ($self, $cond_hr) = @_;

	my $role_db = $self->{'schema'}->resultset('Role')->search($cond_hr)->single;

	return unless defined $role_db;
	return $self->{'_transform'}->role_db2obj($role_db);
}

sub fetch_roles {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->role_db2obj($_);
	} $self->{'schema'}->resultset('Role')->search($cond_hr, $attr_hr);
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
	my ($self, $section_id, $attr_hr) = @_;

	my @ret = $self->{'schema'}->resultset('SectionImage')->search({
		'section_id' => $section_id,
	}, $attr_hr);

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

sub fetch_theme {
	my ($self, $theme_id) = @_;

	my $theme_db = $self->{'schema'}->resultset('Theme')->search({
		'theme_id' => $theme_id,
	})->single;

	return unless defined $theme_db;
	return $self->{'_transform'}->theme_db2obj($theme_db);
}

sub fetch_theme_by_shortcut {
	my ($self, $theme_shortcut) = @_;

	my $theme_db = $self->{'schema'}->resultset('Theme')->search({
		'shortcut' => $theme_shortcut,
	})->single;

	return unless defined $theme_db;
	return $self->{'_transform'}->theme_db2obj($theme_db);
}

sub fetch_validation_type {
	my ($self, $cond_hr) = @_;

	my $validation_type_db = $self->{'schema'}->resultset('ValidationType')->search($cond_hr)->single;

	return unless defined $validation_type_db;
	return $self->{'_transform'}->validation_type_db2obj($validation_type_db);
}

sub fetch_validation_type_options {
	my ($self, $validation_type_id) = @_;

	my @validation_type_options_db
		= $self->{'schema'}->resultset('ValidationOption')->search({
		'validation_type_id' => $validation_type_id,
	});

	map {
		$self->{'_transform'}->validation_option_db2obj($_);
	} @validation_type_options_db;
}

sub fetch_validation_types {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->validation_type_db2obj($_);
	} $self->{'schema'}->resultset('ValidationType')->search($cond_hr, $attr_hr);
}

sub fetch_validation_types_not_used {
	my ($self, $competition_id) = @_;

	return map {
		$self->{'_transform'}->validation_type_db2obj($_);
	} $self->{'schema'}->resultset('ValidationType')->search({
		'validation_type_id' => {
			-not_in => \[
				'SELECT validation_type_id FROM competition_validation WHERE competition_id = ?',
				$competition_id,
			],
		},
	});
}

sub fetch_vote {
	my ($self, $cond_hr) = @_;

	my $vote_db = $self->{'schema'}->resultset('Vote')
		->search($cond_hr)->single;

	return unless defined $vote_db;
	return $self->{'_transform'}->vote_db2obj($vote_db);
}

sub fetch_vote_counted {
	my ($self, $competition_voting_id) = @_;

	my @votes_counted_db = $self->{'schema'}->resultset('Vote')->search({
		'competition_voting_id' => $competition_voting_id,
	}, {
		'group_by' => 'image_id',
		'select' => [
			'image_id',
			{'count' => 'image_id', -as => 'count_images'},
		],
	});

	return map {
		$self->{'_transform'}->vote_stats_db2obj(
			$_,
			$self->fetch_competition_voting({
				'competition_voting_id' => $competition_voting_id,
			}),
			$self->fetch_image($_->get_column('image_id')),
		);
	} @votes_counted_db;
}

sub fetch_vote_counted_sum {
	my ($self, $competition_voting_id) = @_;

	my @votes_counted_db = $self->{'schema'}->resultset('Vote')->search({
		'competition_voting_id' => $competition_voting_id,
	}, {
		'group_by' => 'image_id',
		'select' => [
			'image_id',
			{'count' => 'image_id', -as => 'count_images'},
			{'sum' => 'vote_value::int', -as => 'sum_images'},
		],
	});

	return map {
		$self->{'_transform'}->vote_stats_db2obj(
			$_,
			$self->fetch_competition_voting({
				'competition_voting_id' => $competition_voting_id,
			}),
			$self->fetch_image($_->get_column('image_id')),
		);
	} @votes_counted_db;
}

sub fetch_voting_type {
	my ($self, $cond_hr) = @_;

	my $voting_type_db = $self->{'schema'}->resultset('VotingType')
		->search($cond_hr)->single;

	return unless defined $voting_type_db;
	return $self->{'_transform'}->voting_type_db2obj($voting_type_db);
}

sub fetch_voting_types {
	my ($self, $cond_hr, $attr_hr) = @_;

	return map {
		$self->{'_transform'}->voting_type_db2obj($_);
	} $self->{'schema'}->resultset('VotingType')->search($cond_hr, $attr_hr);
}

sub fetch_voting_types_not_used {
	my ($self, $competition_id) = @_;

	return map {
		$self->{'_transform'}->voting_type_db2obj($_);
	} $self->{'schema'}->resultset('VotingType')->search({
		'voting_type_id' => {
			-not_in => \[
				'SELECT voting_type_id FROM competition_voting WHERE competition_id = ?',
				$competition_id,
			],
		},
	});
}

sub save_competition {
	my ($self, $competition_obj) = @_;

	if (! $competition_obj->isa('Data::Commons::Vote::Competition')) {
		err "Competition object must be a 'Data::Commons::Vote::Competition' instance.";
	}

	my $comp_db = $self->{'schema'}->resultset('Competition')->create(
		$self->{'_transform'}->competition_obj2db($competition_obj),
	);

	return unless defined $comp_db;
	return $self->{'_transform'}->competition_db2obj($comp_db);
}

sub save_competition_validation {
	my ($self, $competition_validation_obj) = @_;

	if (! $competition_validation_obj->isa('Data::Commons::Vote::CompetitionValidation')) {
		err "CompetitionValidation object must be a 'Data::Commons::Vote::CompetitionValidation' instance.";
	}

	my $comp_validation_db = $self->{'schema'}->resultset('CompetitionValidation')->create(
		$self->{'_transform'}->competition_validation_obj2db($competition_validation_obj),
	);

	return unless defined $comp_validation_db;
	return $self->{'_transform'}->competition_validation_db2obj($comp_validation_db);
}

sub save_competition_validation_option {
	my ($self, $competition_validation_option_obj) = @_;

	if (! $competition_validation_option_obj->isa('Data::Commons::Vote::CompetitionValidationOption')) {
		err "CompetitionValidationOption object must be a ".
			"'Data::Commons::Vote::CompetitionValidationOption' instance.";
	}

	my $comp_validation_option_db = $self->{'schema'}->resultset('CompetitionValidationOption')->create(
		$self->{'_transform'}->competition_validation_option_obj2db($competition_validation_option_obj),
	);

	return unless defined $comp_validation_option_db;
	return $self->{'_transform'}->competition_validation_option_db2obj($comp_validation_option_db);
}

sub save_competition_voting {
	my ($self, $competition_voting_obj) = @_;

	if (! $competition_voting_obj->isa('Data::Commons::Vote::CompetitionVoting')) {
		err "CompetitionVoting object must be a 'Data::Commons::Vote::CompetitionVoting' instance.";
	}

	my $comp_voting_db = $self->{'schema'}->resultset('CompetitionVoting')->create(
		$self->{'_transform'}->competition_voting_obj2db($competition_voting_obj),
	);

	return unless defined $comp_voting_db;
	return $self->{'_transform'}->competition_voting_db2obj($comp_voting_db);
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

	if (! $image_obj->isa('Data::Commons::Vote::Image')) {
		err "Image object must be a 'Data::Commons::Vote::Image' instance.";
	}

	my $image_db = $self->{'schema'}->resultset('Image')->update_or_create(
		$self->{'_transform'}->image_obj2db($image_obj),
	);

	return unless defined $image_db;
	return $self->{'_transform'}->image_db2obj($image_db);
}

sub save_license {
	my ($self, $license_obj) = @_;

	if (! $license_obj->isa('Data::Commons::Vote::License')) {
		err "Log object must be a 'Data::Commons::Vote::License' instance.";
	}

	my $license_db = $self->{'schema'}->resultset('License')->create(
		$self->{'_transform'}->license_obj2db($license_obj),
	);

	return unless defined $license_db;
	return $self->{'_transform'}->license_db2obj($license_db);
}

sub save_log {
	my ($self, $log_obj) = @_;

	if (! $log_obj->isa('Data::Commons::Vote::Log')) {
		err "Log object must be a 'Data::Commons::Vote::Log' instance.";
	}

	my $log_db = $self->{'schema'}->resultset('Log')->create(
		$self->{'_transform'}->log_obj2db($log_obj),
	);

	return unless defined $log_db;
	return $self->{'_transform'}->log_db2obj($log_db);
}

sub save_log_type {
	my ($self, $log_type_obj) = @_;

	if (! $log_type_obj->isa('Data::Commons::Vote::LogType')) {
		err "Log type object must be a 'Data::Commons::Vote::LogType' instance.";
	}

	my $log_type_db = $self->{'schema'}->resultset('LogType')->create(
		$self->{'_transform'}->log_obj2db($log_type_obj),
	);

	return unless defined $log_type_db;
	return $self->{'_transform'}->log_type_db2obj($log_type_db);
}

sub save_person {
	my ($self, $person_obj) = @_;

	if (! $person_obj->isa('Data::Commons::Vote::Person')) {
		err "Person object must be a 'Data::Commons::Vote::Person' instance.";
	}

	my $person_db = $self->{'schema'}->resultset('Person')->create(
		$self->{'_transform'}->person_obj2db($person_obj),
	);

	return unless defined $person_db;
	return $self->{'_transform'}->person_db2obj($person_db);
}

sub save_person_role {
	my ($self, $person_role_obj) = @_;

	if (! $person_role_obj->isa('Data::Commons::Vote::PersonRole')) {
		err "Person role object must be a 'Data::Commons::Vote::PersonRole' instance.";
	}

	my $person_role_db = $self->{'schema'}->resultset('PersonRole')->create(
		$self->{'_transform'}->person_role_obj2db($person_role_obj),
	);

	return unless defined $person_role_db;
	return $self->{'_transform'}->person_role_db2obj($person_role_db);
}

sub save_section {
	my ($self, $section_obj) = @_;

	if (! $section_obj->isa('Data::Commons::Vote::Section')) {
		err "Section object must be a 'Data::Commons::Vote::Section' instance.";
	}

	my $section_db = $self->{'schema'}->resultset('Section')->create(
		$self->{'_transform'}->section_obj2db($section_obj),
	);

	return unless defined $section_db;
	return $self->{'_transform'}->section_db2obj($section_db);
}

sub save_section_category {
	my ($self, $section_category_obj) = @_;

	if (! $section_category_obj->isa('Data::Commons::Vote::Category')) {
		err "Section category object must be a 'Data::Commons::Vote::Category' instance.";
	}

	my $section_category_db = $self->{'schema'}->resultset('SectionCategory')->update_or_create(
		$self->{'_transform'}->section_category_obj2db($section_category_obj),
	);

	return unless defined $section_category_db;
	return $self->{'_transform'}->section_category_db2obj($section_category_db);
}

sub save_section_image {
	my ($self, $section_image_obj) = @_;

	if (! $section_image_obj->isa('Data::Commons::Vote::SectionImage')) {
		err "Section image object must be a 'Data::Commons::Vote::SectionImage' instance.";
	}

	my $section_image_db = $self->{'schema'}->resultset('SectionImage')->update_or_create(
		$self->{'_transform'}->section_image_obj2db($section_image_obj),
	);

	return unless defined $section_image_db;
	return $self->{'_transform'}->section_image_db2obj($section_image_db);
}

sub save_theme {
	my ($self, $theme_obj) = @_;

	if (! $theme_obj->isa('Data::Commons::Vote::Theme')) {
		err "Section object must be a 'Data::Commons::Vote::Theme' instance.";
	}

	my $theme_db = $self->{'schema'}->resultset('Theme')->create(
		$self->{'_transform'}->theme_obj2db($theme_obj),
	);

	return unless defined $theme_db;
	return $self->{'_transform'}->theme_db2obj($theme_db);
}

sub save_theme_image {
	my ($self, $theme_image_obj) = @_;

	if (! $theme_image_obj->isa('Data::Commons::Vote::ThemeImage')) {
		err "Section image object must be a 'Data::Commons::Vote::ThemeImage' instance.";
	}

	my $theme_image_db = $self->{'schema'}->resultset('ThemeImage')->update_or_create(
		$self->{'_transform'}->theme_image_obj2db($theme_image_obj),
	);

	return unless defined $theme_image_db;
	return $self->{'_transform'}->theme_image_db2obj($theme_image_db);
}

sub save_validation_bad {
	my ($self, $validation_bad_obj) = @_;

	if (! $validation_bad_obj->isa('Data::Commons::Vote::ValidationBad')) {
		err "ValidationBad object must be a 'Data::Commons::Vote::ValidationBad' instance.";
	}

	my $validation_bad_db = $self->{'schema'}->resultset('ValidationBad')->create(
		$self->{'_transform'}->validation_bad_obj2db($validation_bad_obj),
	);

	return unless defined $validation_bad_db;
	return $self->{'_transform'}->validation_bad_db2obj($validation_bad_db);
}

sub save_vote {
	my ($self, $vote_obj) = @_;

	if (! $vote_obj->isa('Data::Commons::Vote::Vote')) {
		err "Vote object must be a 'Data::Commons::Vote::Vote' instance.";
	}

	my $vote_db = $self->{'schema'}->resultset('Vote')->create(
		$self->{'_transform'}->vote_obj2db($vote_obj),
	);

	return unless defined $vote_db;
	return $self->{'_transform'}->vote_db2obj($vote_db);
}

sub update_competition {
	my ($self, $competition_id, $competition_obj) = @_;

	my $competition_db = $self->{'schema'}->resultset('Competition')->search({
		'competition_id' => $competition_id,
	})->single;

	$competition_db->update(
		$self->{'_transform'}->competition_obj2db($competition_obj),
	);

	return $competition_obj;
}

sub update_person {
	my ($self, $person_id, $person_obj) = @_;

	my $person_db = $self->{'schema'}->resultset('Person')->search({
		'person_id' => $person_id,
	})->single;

	$person_db->update(
		$self->{'_transform'}->person_obj2db($person_obj),
	);

	return $person_obj;
}

sub update_section {
	my ($self, $section_obj) = @_;

	$self->{'schema'}->resultset('Section')->update(
		$self->{'_transform'}->section_obj2db($section_obj),
	);

	return $section_obj;
}

1;

__END__
