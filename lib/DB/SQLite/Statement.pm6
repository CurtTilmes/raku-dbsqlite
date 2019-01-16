use DB::Statement;
use DB::SQLite::Native;
use DB::SQLite::Result;

class DB::SQLite::Statement does DB::Statement
{
    has DB::SQLite::Native::Statement $.stmt handles <sql>;
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
                $!stmt.bind-named($k, $v)
            }
        }

        if $!count                         # Has results?
        {
            return DB::SQLite::Result.new(:sth(self), :$finish)
        }

        my $code = $!stmt.step;
        $.finish if $finish;
        return $!stmt.db.changes if $code == SQLITE_DONE;
        $!stmt.db.check($code);
    }
}
