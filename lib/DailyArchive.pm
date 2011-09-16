use strict;
use warnings;

package DailyArchive;
use Moose;

use DailyArchive::Database;
use File::HomeDir ();
use Path::Class::Dir ();
use Config::Any ();
use Net::Twitter ();

sub BUILD {
    my ($self) = @_;
    die "Please specify 'consumer_key' in the [twitter] section of '" . $self->config_file . "'\n" unless $self->twitter_consumer_key;
    die "Please specify 'consumer_secret' in the [twitter] section of '" . $self->config_file . "'\n" unless $self->twitter_consumer_secret;
    die "Please specify 'access_token' in the [twitter] section of '"   . $self->config_file . "'\n" unless $self->twitter_access_token;
    die "Please specify 'access_token_secret' in the [twitter] section of '"    . $self->config_file . "'\n" unless $self->twitter_access_token_secret;
}

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'config_file' => (
    is => 'ro',
    isa => 'Path::Class::File',
    lazy_build => 1,
);

sub _build_config_file {
    my ($self) = @_;
    my $home = File::HomeDir->my_data;
    my $conf_file = Path::Class::Dir->new($home)->file('.twitter_daily_archive.ini');
    return $conf_file;
}

has 'config' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_config {
    my ($self) = @_;
    my $cfg = Config::Any->load_files({
        use_ext => 1,
        files   => [ $self->config_file ],
    });
    foreach my $config_entry ( @{ $cfg } ) {
        my ($filename, $config) = %{ $config_entry };
        warn("Loaded config from file: $filename\n") if $self->debug;
        return $config;
    }
    return {};
}

has 'twitter_consumer_key' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return (shift)->config->{'twitter'}->{'consumer_key'}; },
);

has 'twitter_consumer_secret' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return (shift)->config->{'twitter'}->{'consumer_secret'}; },
);

has 'twitter_access_token' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return (shift)->config->{'twitter'}->{'access_token'}; },
);

has 'twitter_access_token_secret' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return (shift)->config->{'twitter'}->{'access_token_secret'}; },
);

has 'twitter' => (
    is => 'ro',
    isa => 'Net::Twitter',
    lazy_build => 1,
);

sub _build_twitter {
    my ($self) = @_;
    return Net::Twitter->new(
        traits              => [qw/API::REST OAuth/],
        consumer_key        => $self->twitter_consumer_key,
        consumer_secret     => $self->twitter_consumer_secret,
        access_token        => $self->twitter_access_token,
        access_token_secret => $self->twitter_access_token_secret,
    );
}

has 'database' => (
    is         => 'ro',
    isa        => 'DailyArchive::Database',
    lazy_build => 1,
    handles    => [ 'dbh' ],
);

sub _build_database {
    my ($self) = @_;
    return DailyArchive::Database->new( da => $self );
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;
