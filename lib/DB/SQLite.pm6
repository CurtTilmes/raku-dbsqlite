use DB;
use DB::SQLite::Native;
use DB::SQLite::Connection;

class DB::SQLite does DB
{
    has $.filename = '';
    has $.busy-timeout = 10000;

    method connect(--> DB::SQLite::Connection)
    {
        my $conn = DB::SQLite::Native.open($!filename);
        $conn.busy-timeout($_) with $!busy-timeout;
        DB::SQLite::Connection.new(owner => self, :$conn)
    }
}
