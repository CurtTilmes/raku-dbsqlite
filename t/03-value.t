use Test;
use Test::When <extended>;

use DB::SQLite;

plan 8;

isa-ok my $s = DB::SQLite.new, DB::SQLite, 'Create object';

is $s.query('select 42').value, 42, 'value int';

nok $s.query('select 1 where 1=2').value, 'No value';

is $s.query('select ?', 42).value, 42, 'value ? placeholder';

is $s.query('select ?1', 42).value, 42, 'value ?1 placeholder';

is $s.query('select $this', 42).value, 42, 'value $this placeholder';

is-deeply $s.query('select $this, $that', that => 'foo', this => 12).array,
    (12, 'foo'), 'value named placeholders';

is-deeply $s.query('select :this, $that', 12, that => 'foo').array,
    (12, 'foo'), 'mixed number and named placeholders';

done-testing;
