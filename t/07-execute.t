use Test;
use Test::When <extended>;
use DB::SQLite;

plan 5;

isa-ok my $s = DB::SQLite.new, DB::SQLite, 'Create object';

lives-ok { $s.execute(q:to/END/) }, 'execute';
create table foo
(
   x int,
   y text
);
insert into foo (x,y) values (1, 'this');

insert into foo (x,y) values (2, 'that');
END

is $s.query('select * from foo order by x').arrays,
    ( (1, 'this'), (2, 'that') ), 'rows present';

lives-ok { $s.finish }, 'finish';

is DB::SQLite::Native.memory-used, 0, 'All handles deleted';

done-testing;




