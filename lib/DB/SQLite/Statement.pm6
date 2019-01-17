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
