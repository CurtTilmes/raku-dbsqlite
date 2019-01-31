use DB::Statement;
use DB::SQLite::Native;
use DB::SQLite::Result;

class DB::SQLite::Statement does DB::Statement
{
    has DB::SQLite::Native::Statement $.stmt handles <bind sql clear>;
    has $.count = $!stmt.count;

    method free(--> Nil)
    {
        .finalize with $!stmt;
        $!stmt = Nil;
    }

    method execute(Bool :$finish, *@args, *%args)
    {
        .reset with $!stmt;

        if @args
        {
            my \num-params = @args.elems;
            loop (my $i = 0; $i < num-params; $i++)
            {
                $!stmt.bind($i+1, @args[$i]);
            }
        }

        if %args
        {
            for %args.kv -> $k, $v
            {
                $!stmt.bind($k, $v)
            }
        }

        if $!count                         # Has results?
        {
            return DB::SQLite::Result.new(:sth(self), :$finish)
        }
        else
        {
            LEAVE $.finish if $finish;
            $!stmt.step == SQLITE_DONE
                ?? $!stmt.db.changes
                !! $!stmt.db.check;
        }
    }
}

=begin pod

=head1 NAME

DB::SQLite::Statement -- SQLite prepared statement object

=head1 SYNOPSIS

my $s = DB::SQLite.new;

my $db = $s.db;

my $sth = $db.prepare('select * from foo where x = ?');

my $result = $sth.execute(12);

=head1 DESCRIPTION

Holds a prepared database statement.  The only thing you can
really do with a prepared statement is to C<execute> it with 
arguments to bind to the prepared placeholders.

=head1 METHODS

=head2 B<execute>(**@args, Bool :$finish)

Executes the database statement with the supplied arguments.

If C<:finish> is C<True> the database connection will C<finish>
following the execution.

Returns the number of changes to the database.

=head2 B<finish>()

Calls C<finish> on the creating database connection.

=head2 B<free>()

Frees the resources associated with the prepared statement.  You
normally do not need to call this since cached statements want to
stick around, and it will automatically be called when the garbage
collector reaps the object anyway.

=end pod
