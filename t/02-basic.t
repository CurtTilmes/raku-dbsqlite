use Test;
use Test::When <extended>;

use DB::SQLite;

plan 10;

isa-ok my $s = DB::SQLite.new, DB::SQLite, 'Create object';

isa-ok my $db = $s.db, DB::SQLite::Connection, 'Create database handle';

is $db.query('select 42').value, 42, 'simple query on db';

is $s.query('select 42').value, 42, 'query on object shortcut';

lives-ok { $db.finish }, 'Return database handle';

is $s.execute('create table foo (int x); insert into foo values (42)'), 1,
    'execute';

is $s.query('select * from foo').value, 42, 'query';

is-deeply $s.query(q<select 1       as a,
                            'this'  as b,
                            2e57    as c,
                            X'1234' as d,
                            NULL    as e>).hash,
    %(
        a => 1,
        b => 'this',
        c => 2e57,
        d => buf8.new(0x12, 0x34),
        e => Nil
    ), 'Hash of a bunch of types';

lives-ok { $s.finish }, 'Finish object';

is DB::SQLite::Native.memory-used, 0, 'All handles deleted';

done-testing;
