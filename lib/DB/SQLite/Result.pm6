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

=begin pod

=head1 NAME

DB::MySQL::Result -- Results from a MySQL query

=head1 SYNOPSIS

my $results = $sth.execute(1);

say $results.count;      # Number of column fields

say $results.keys;       # Array of column field keys

say $results.value;      # A single scalar value

say $results.array;      # A single array with one row

say $results.hash;       # A single hash with one row

say $results.arrays;     # A sequence of arrays with all rows

say $results.hashes;     # A sequence of hashes with all rows

$results.finish;         # Only needed if results aren't consumed.

=head1 DESCRIPTION

Returned from a C<DB::SQLite::Statement> execution that returns
results.  

=head1 METHODS

=head2 B<count>()

Returns the number of fields in each row.

=head2 B<keys>()

Array of the names of the columns (fields) to be returned.

=head2 B<finish>()

Finish the database connection.  This is only needed if the complete
database returns aren't consumed.

=head2 B<value>()

Return a single scalar value from the results.

=head2 B<array>()

Return a single row from the results as an array.

=head2 B<hash>()

Return a single row from the results as a hash.

=head2 B<arrays>()

Return a sequence of all rows as arrays.

=head2 B<hashes>()

Return a sequence of all rows as hashes.

=end pod
