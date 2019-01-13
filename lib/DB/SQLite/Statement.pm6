use DB::Statement;
use DB::SQLite::Native;
use DB::SQLite::Result;

class DB::SQLite::Statement does DB::Statement
{
    has DB::SQLite::Native::Statement $.stmt handles <sql>;
    has $.count = $!stmt.count;

    method execute(Bool :$finish = False, *@args, *%args)
    {
        with $!stmt { .reset; .clear }
        for 1..@args.elems -> $i           # Bind numbers start at 1
        {
            $!stmt.bind($i, @args[$i-1])
        }
        for %args.kv -> $k, $v
        {
            $!stmt.bind($k, $v)
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

    submethod DESTROY()
    {
        .finalize with $!stmt;
        $!stmt = Nil;
    }
}
