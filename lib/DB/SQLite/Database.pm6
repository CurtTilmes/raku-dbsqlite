use DB::Database;
use DB::SQLite::Native;
use DB::SQLite::Statement;

class DB::SQLite::Database does DB::Database
{
    has DB::SQLite::Native $.conn;

    submethod DESTROY(--> Nil)
    {
        .close with $!conn;
        $!conn = Nil;
    }

    method ping(--> Bool)
    {
        $!conn.defined
    }

    method prepare-nocache(Str:D $query --> DB::SQLite::Statement)
    {
        DB::SQLite::Statement.new(:db(self), stmt => $!conn.prepare($query))
    }

    method execute(Str:D $query, Bool :$finish = False --> Int)
    {
        LEAVE $.finish if $finish;
        $!conn.exec($query);
    }
}
