use strictures 2;
use Test2::V0;
use experimental 'signatures';
use Git::Wrapper;
use Path::Tiny 0.125;

use Git::FetchNewCommitIds 'fetch_new_commit_ids';

run();
done_testing;

sub run() {
    $ENV{PATH} = "$ENV{PATH}:/usr/bin" if "Mithaldu" eq ( $ENV{USERNAME} || "" );    # provide git in vscode

    my $tmp_homedir = clean_environment();
    my $remote_path = path("$tmp_homedir/remote_repo")->mkdir;
    my $local_path  = path("$tmp_homedir/local_repo")->mkdir;

    my $remote = Git::Wrapper->new($remote_path);
    $remote->config(qw( --global user.name Mithaldu ));
    $remote->config(qw( --global user.email walde.christian@gmail.com ));
    $remote->init;

    my $local = Git::Wrapper->new($local_path);
    $local->init( -bare );
    $local->remote( add => origin => $remote_path );

    my ( $c1, $c2 );

    my $start_id =    #
      $c1 = new_commit( $remote, "$remote_path/file1" );
    sleep 2;
    $c2 = new_commit( $remote, "$remote_path/file2" );
    is [ fetch_new_commit_ids( $local, "origin" ) ], [ $c1, $c2 ], "found commits for new main branch";

    $c1 = new_commit( $remote, "$remote_path/file3" );
    sleep 2;
    $c2 = new_commit( $remote, "$remote_path/file4" );
    is [ fetch_new_commit_ids( $local, "origin" ) ], [ $c1, $c2 ], "found commits for updated main branch";

    $remote->checkout( qw( -b branch1 ), $start_id );
    $c1 = new_commit( $remote, "$remote_path/file5" );
    sleep 2;
    $c2 = new_commit( $remote, "$remote_path/file6" );
    is [ fetch_new_commit_ids( $local, "origin" ) ], [ $c1, $c2 ], "found commits for new side branch";

    $remote->reset( qw( --hard ), $start_id );
    $c1 = new_commit( $remote, "$remote_path/file7" );
    is [ fetch_new_commit_ids( $local, "origin" ) ], [$c1], "found commits for new side branch";

    return;
}

# see https://metacpan.org/release/ETHER/Dist-Zilla-Plugin-Git-2.051/source/t/lib/Util.pm
sub clean_environment () {
    my $tempdir = Path::Tiny->tempdir( CLEANUP => 1 );
    delete $ENV{$_} for grep /^G(?:IT|PG)_/i, keys %ENV;
    $ENV{HOME}                = $ENV{GNUPGHOME} = $tempdir->stringify;
    $ENV{GIT_CONFIG_NOSYSTEM} = 1;                                       # Don't read /etc/gitconfig
    $tempdir;
}

sub new_commit( $git, $file ) {
    path($file)->touch;
    $git->add(".");
    $git->commit( { message => "." } );
    my ($id) = $git->rev_parse("HEAD");
    return $id;
}
