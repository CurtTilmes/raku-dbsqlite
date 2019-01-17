use Test;
use Test::When <extended>;

use DB::SQLite;

plan 20;

isa-ok my $s = DB::SQLite.new, DB::SQLite, 'Create object';

isa-ok my $sth = $s.db.prepare('select ?3, ?2, ?1'),
    DB::SQLite::Statement, 'prepare';

is-deeply $sth.execute().array, (Any, Any, Any), 'Just NULLs';

is-deeply $sth.execute(1, 2).array, (Any, 2, 1), 'Bind only 2';

is-deeply $sth.execute().array, (Any, 2, 1), 'Reuse binds';

lives-ok { $sth.clear }, 'clear binds';

is-deeply $sth.execute().array, (Any, Any, Any), 'Back to NULLs';

lives-ok { $sth.finish }, 'finish';

isa-ok $sth = $s.db.prepare('select $x, $y, $z'),
    DB::SQLite::Statement, 'prepare named';

is-deeply $sth.execute(:x(1), :y(2), :z(3)).array,
                       (1,2,3), 'colon pairs binds array';

is-deeply $sth.execute(x => 1, y => 2, z => 3).array,
                       (1,2,3), 'fat arrow pairs binds array';

lives-ok { $sth.finish }, 'finish';

isa-ok $sth = $s.db.prepare('select :x, $y, @z'),
    DB::SQLite::Statement, 'prepare named';

lives-ok { $sth.bind(':x', 1) }, 'bind :x';

lives-ok { $sth.bind('$y', 2) }, 'bind $y';

lives-ok { $sth.bind('@z', 3) }, 'bind @z';

is-deeply $sth.execute().array,
                       (1,2,3), 'colon pairs binds array';

lives-ok { $sth.finish }, 'finish';

lives-ok { $s.finish }, 'finish object';

is DB::SQLite::Native.memory-used, 0, 'All handles deleted';
