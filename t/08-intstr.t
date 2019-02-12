use Test;
use Test::When <extended>;

use DB::SQLite;

plan 4;

isa-ok my $db = DB::SQLite.new, DB::SQLite, 'Create object';

my IntStr $foo = <42>;

is $db.query('select 1 where ? = ?', $foo, $foo).value, 1,
    'Pass in IntStr value';

lives-ok { $db.finish }, 'Finish object';

is DB::SQLite::Native.memory-used, 0, 'All handles deleted';

done-testing;
