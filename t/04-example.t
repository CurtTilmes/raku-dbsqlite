use Test;
use Test::When <extended>;

use DB::SQLite;

plan 9;

isa-ok my $s = DB::SQLite.new, DB::SQLite, 'Create object';

is $s.query('select 42').value, 42, 'simple value';

is $s.execute('create table foo (x int, y text)'), 0, 'create table';

is $s.query('insert into foo (x,y) values (?,?)', 1, 'this'), 1, 'insert row';

is $s.query('insert into foo (x,y) values ($x,$y)', x => 2, y => 'that'), 1,
    'insert named args';

is-deeply $s.query('select * from foo where x = $x', :x(1)).array,
    (1, 'this'), 'array';

is-deeply $s.query('select * from foo where x = $x', :2x).hash,
    %(x => 2, y => 'that'), 'hash';

is-deeply $s.query('select * from foo order by x').arrays,
    ((1, 'this'), (2, 'that')), 'arrays';

is-deeply $s.query('select * from foo order by x').hashes,
    (%(x => 1, y => 'this'), %(x => 2, y => 'that')), 'hashes';
