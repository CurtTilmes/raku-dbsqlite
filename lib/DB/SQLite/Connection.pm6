use DB::Connection;
use DB::SQLite::Native;
use DB::SQLite::Statement;

class DB::SQLite::Connection does DB::Connection
{
    has DB::SQLite::Native $.conn is required;

    method free(--> Nil)
    {
        .close with $!conn;
        $!conn = Nil;
    }

    method prepare-nocache(Str:D $query --> DB::SQLite::Statement)
    {
        DB::SQLite::Statement.new(:db(self), stmt => $!conn.prepare($query))
    }

    method execute(Str:D $query, Bool :$finish --> Int)
    {
        LEAVE $.finish if $finish;
        $!conn.exec($query);
        $!conn.changes
    }
}

=begin pod

=head1 NAME

DB::SQLite::Connection -- Database connection object

=head1 SYNOPSIS

my $s = DB::MySQL.new;

my $db = $my.db;

say "Good connection" if $db.ping;

say $db.query('select * from foo where x = ?', 27).hash;

my $sth = $db.prepare('select * from foo where x = ?'); # DB::SQLite::Statement

$db.execute('insert into foo (x,y) values (1,2)'); # No return or placeholder args

$db.begin;

$db.commit;

$db.rollback;

$db.finish; # Finished with database connection, return to idle pool

=head1 DESCRIPTION

Always allocate from a C<DB::MySQL> object with the C<.db> method.  Use
C<.finish> to return the database connection to the pool when finished.

=head1 METHODS

=head2 B<finish>()

Return this database connection to the connection pool in the parent C<DB::SQLite>
object.

=head2 B<ping>()

Returns C<True> if the connection to the server is active.

=head2 B<execute>(Str:D $sql, Bool :$finish, Bool :$store)

Executes the sql statement.  C<:finish> causes the database connection to
be C<finish>ed after the command executes.  

Returns the number of affected rows.

=head2 B<prepare>(Str:D $query, Bool :$nocache --> DB::SQLite::Statement)

Prepares the SQL query, returning a C<DB::SQLite::Statement> object with the prepared
query.  These are cached in the database connection object, so if the same query
is prepared again, the previous statement is returned.  You can avoid the statement
caching by setting C<:nocache> to C<True> (or by calling B<prepare-nocache>()).

=head2 B<prepare-nocache>(Str:D $query --> DB::SQLite::Statement)

Prepares the SQL query, returning a C<DB::SQLite::Statement> object with the prepared
query.

=head2 B<query>(Str:D $query, Bool :$finish, Bool :$nocache, *@args)
prepares, then executes the query with the supplied arguments.

=head2 B<begin>()

Begins a new database transaction.  Returns the C<DB::SQLite::Connection> object.

=head2 B<commit>()

Commits an active database transaction.  Returns the C<DB::SQLite::Connection> object.

=head2 B<rollback>()

Rolls back an active database transaction.  If the database is
finished with an active transaction, it will be rolled back
automatically.  Returns the C<DB::SQLite::Connection> object.

=end pod
