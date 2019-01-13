use DB;
use DB::SQLite::Native;
use DB::SQLite::Database;

class DB::SQLite does DB
{
    has $.filename = '';
    has $.busy-timeout = 10000;

    method connect(--> DB::SQLite::Database)
    {
        my $conn = DB::SQLite::Native.open($!filename);
        $conn.busy-timeout($_) with $!busy-timeout;
        DB::SQLite::Database.new(owner => self, :$conn)
    }
}
