use strict;
use warnings;

package DailyArchive::Database;
use Moose;

use DBI ();

sub DEMOLISH {
    my ($self) = @_;
    if ( $self->has_dbh ) {
        warn("Disconnecting from database...\n") if $self->_da->debug;
        $self->dbh->disconnect();
    }
}

has '_da' => (
    is       => 'ro',
    isa      => 'DailyArchive',
    init_arg => 'da',
    required => 1,
);

has '_config' => (
    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,
);

sub _build__config {
    my ($self) = @_;
    return $self->_da->config->{'database'} || {};
}

has 'dsn' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_dsn {
    my ($self) = @_;
    return $self->_config->{'dsn'} || 'dbi:Pg:dbname=twitter_daily_archive';
}

has 'username' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_username {
    my ($self) = @_;
    return $self->_config->{'username'} || '';
}

has 'password' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_password {
    my ($self) = @_;
    return $self->_config->{'password'} || '';
}

has 'dbh' => (
    is         => 'ro',
    isa        => 'DBI::db',
    lazy_build => 1,
);

sub _build_dbh {
    my ($self) = @_;
    my $dbh = DBI->connect(
        $self->dsn,
        $self->username,
        $self->password,
    );
    confess("Can't connect to database!") unless $dbh and $dbh->ping();

    # Use database exceptions
    $dbh->{'RaiseError'} = 1;
    $dbh->{'PrintError'} = 0;

    # Return data from DB already decoded as native perl string
    $dbh->{'pg_enable_utf8'} = 1;

    return $dbh;
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;
