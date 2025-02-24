package Git::FetchNewCommitIds;

use strictures 2;
use experimental 'signatures';
use Exporter 'import';

# ABSTRACT: fetches a repository's remote and returns all new commit ids on all branches

# VERSION

our @EXPORT_OK = qw( fetch_new_commit_ids );

sub fetch_new_commit_ids( $git, $remote = "origin" ) {
    die "first argument must be a Git::Wrapper object" unless ref $git eq "Git::Wrapper";

    $git->fetch( $remote, "--dry-run" );
    return if not $git->{err};

    my %seen = !$git->reflog("--all") ? () :    # don't run log on an empty repo
      map +( $_ => 1 ), $git->RUN(qw( log --reflog --pretty=format:%H ));

    $git->fetch($remote);

    my %new =                                   #
      map +( $_ => 1 ), $git->RUN(qw( log --reflog --pretty=format:%H ));

    my @commits_w_age = map { id => $_, age => $git->RUN( qw( log --no-walk --format=%at ), $_ ) },    #
      grep !$seen{$_}, keys %new;

    return map $_->{id}, sort { $a->{age} <=> $b->{age} } @commits_w_age;
}

1;
