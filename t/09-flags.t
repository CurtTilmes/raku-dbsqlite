use Test;
use Test::When <extended>;

use DB::SQLite;

my $filename = 'test.sqlite3';

END $filename.IO.unlink;

plan 9;

isa-ok my $db = DB::SQLite.new(:$filename), DB::SQLite, 'Create object';

is $db.execute('create table foo (x int); insert into foo values (42)'), 1,
    'make a table, insert a row';

lives-ok { $db.finish }, 'Finish object';

isa-ok $db = DB::SQLite.new(:$filename, :readonly), DB::SQLite, 'Open readonly';

is $db.query('select x from foo').value, 42, 'Can still read';

throws-like { $db.execute('insert into foo values (19)') },
    DB::SQLite::Error, message => /readonly/,
    'Error writing read/only database';

is $db.query('select x from foo').value, 42, 'Can still read';

lives-ok { $db.finish }, 'Finish object';

is DB::SQLite::Native.memory-used, 0, 'All handles deleted';

done-testing;
