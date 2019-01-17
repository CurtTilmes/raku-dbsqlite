use DB::SQLite::Native;
use DB::Result;

sub sqlite-int($stmt, $i)    { $stmt.int64($i)  }
sub sqlite-double($stmt, $i) { $stmt.double($i) }
sub sqlite-text($stmt, $i)   { $stmt.text($i)   }
sub sqlite-blob($stmt, $i)   { buf8.new($stmt.blob($i)[^$stmt.bytes($i)]) }
sub sqlite-null($stmt, $i)   { Any }

my %convert = Map.new: map( { +SQLITE_TYPE::{.key} => .value}, (
    SQLITE_INTEGER => &sqlite-int,
    SQLITE_FLOAT   => &sqlite-double,
    SQLITE_TEXT    => &sqlite-text,
    SQLITE_BLOB    => &sqlite-blob,
    SQLITE_NULL    => &sqlite-null
));

class DB::SQLite::Result does DB::Result
{
    has $.stmt = $!sth.stmt;
    has $.count = $!sth.count;

    method names() { do for ^$!count { $!stmt.name($_) } }

    method row()
    {
        given $!stmt.step()
        {
            when SQLITE_ROW
            {
                do for ^$!count -> $i
                {
                    %convert{$!stmt.type($i)}($!stmt, $i);
                }
            }
            when SQLITE_DONE
            {
                ()
            }
            default
            {
                $!stmt.db.check($_)
            }
        }
    }
}
