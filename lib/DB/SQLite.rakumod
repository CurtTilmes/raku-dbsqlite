use DB;
use DB::SQLite::Native;
use DB::SQLite::Connection;

class DB::SQLite does DB
{
    has $.filename;
    has $.busy-timeout;
    has %.flags;

    method BUILD(:$!filename = '', :$!busy-timeout = 10000, *%!flags) {}

    method connect(--> DB::SQLite::Connection)
    {
        my $conn = DB::SQLite::Native.open($!filename, |%!flags);
        $conn.busy-timeout($_) with $!busy-timeout;
        DB::SQLite::Connection.new(owner => self, :$conn)
    }
}

=begin pod

=head1 NAME

DB::SQLite -- SQLite database access for Perl 6

=head1 SYNOPSIS

my $s = DB::SQLite.new; # You can pass in connection information if you want.

say $s.query('select 42').value;
# 42

$s.execute('insert into foo (x,y) values (1,2)');

for $s.query('select * from foo').arrays -> @row {
    say @row;
}

for $s.query('select * from foo').hashes -> %row {
    say %row;
}

=head1 DESCRIPTION

The main C<DB::SQLite> object.  It manages a pool of database connections
(C<DB::SQLite::Connection>), creating new ones as needed and caching idle
ones.

It has some methods that simply allocate a database connection, call the
same method on that connection, then immediately return the connection to
the pool.

=head1 METHODS

=head2 B<new>(:$filename, :$busy-timeout = 10000)

When you create a C<DB::SQLite object>, you can specify a filename option
to C<new> for the database to open. If it isn't specified, it will default
to an empty string which causes a private, temporary on-disk database to be
created. This will be useless if you use more than one connection, since
each will get its own database, but maybe you want that..

If you specify filename => ':memory:' you will get a private, temporary,
in-memory database. Again, this will not be shared across connections.

You can also use a busy-timeout option to specify in milliseconds, the amount
of sleeping to wait for a locked table to become available. This defaults to
10000 (10 seconds). Setting to zero will turn off busy handling.

=head2 B<db>()

Allocate a C<DB::SQLite::Connection> object, either using a cached one from the 
pool of idle connections, or creating a new one.

=head2 B<query>(Str:D $sql, Bool :$finish, Bool :$nocache)

Allocates a database connection and perform the query, then return the connection
to the pool.  B<:finish> causes the connection to return to the pool after use,
B<:nocache> causes the prepared statement not to be cached for later use.
If the query returns results, returns a C<DB::SQLite::Result> object with the 
result.

=head2 B<execute>(Str:D $sql, Bool :$finish)

Allocates a database connection, executes the SQL statement, then returns the 
connection to the pool.  B<:finish> causes the connection to return to the pool
after use.  This does not return any results, only the number of changes to the
database.

=head2 B<finish>()

Destroys all the pooled connections and the object itself.

=end pod
