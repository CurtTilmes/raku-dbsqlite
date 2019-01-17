use Test;
use Test::When <extended>;
use DB::SQLite;

plan 5;

END 'test.db'.IO.unlink;

isa-ok my $s = DB::SQLite.new(filename => 'test.db'),
       DB::SQLite, 'Create object';

lives-ok { $s.execute('create table foo (x,y)') }, 'create table';

await do for ^10 -> $x
{
    start
    {
        my $db = $s.db;
        my $sth = $db.prepare('insert into foo values (?,?)');
        $db.begin;
        for ^1000 -> $y
        {
            $sth.execute($x, $y);
        }
        $db.commit.finish;
    }
}

is $s.query('select count(*) from foo').value, 10000, 'all rows present';

lives-ok { $s.finish }, 'finish';

is DB::SQLite::Native.memory-used, 0, 'All handles deleted';

done-testing;
