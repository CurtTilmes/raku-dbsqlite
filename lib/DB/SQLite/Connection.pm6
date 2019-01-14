use DB::Connection;
use DB::SQLite::Native;
use DB::SQLite::Statement;

class DB::SQLite::Connection does DB::Connection
{
    has DB::SQLite::Native $.conn;

    method ping(--> Bool)
    {
        $!conn.defined
    }

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
    }
}
