DB::SQLite - SQLite access for Perl 6
=====================================

This is a reimplementation of Perl 6 bindings for SQLite.

Basic usage
-----------

```perl6
my $s = DB::SQLite.new();  # You can pass in various connection options
```

Execute a query, and get a single value:
```perl6
say $s.query('select 42').value;
# 42
```

Create a table:
```perl6
$s.execute('create table foo (x int, y varchar(80))');
```

Insert some values using placeholders:
```perl6
$s.query('insert into foo (x,y) values (?,?)', 1, 'this');
```

Or even fancy placeholders:
```perl6
$s.query('insert into foo (x,y) values ($x,$y)', x => 1, y => this');
```

Execute a query returning a row as an array or hash;
```perl6
say $s.query('select * from foo where x = $x', :x(1)).array;
say $s.query('select * from foo where x = $x', :1x).hash;
```

Execute a query returning a bunch of rows as arrays or hashes:

```perl6
.say for $s.query('select * from foo').arrays;
.say for $s.query('select * from foo').hashes;
```

`.query()` caches a prepared statement, and can have placeholders and
arguments -

`.execute()` does not prepare/cache and can't have placeholders and
doesn't return results.  It returns an integer with the number of rows
affected by an action.

Connection Information
----------------------

You can specify a filename option to `.new` for the database to open.
If it isn't specified, it will default to an empty string which causes
a private, temporary on-disk database to be created.  This will be
useless if you use more than one connection, since each will get its
own database, but maybe you want that..

If you specify `':memory'` you will get a private, temporary,
in-memory database.  Again, this will not be shared across
connections.

You can also specify a `busy-timeout` option to specify in
milliseconds, the amount of sleeping to wait for a locked table to
become available.  This defaults to 10000 (10 seconds).  Setting to
zero will turn off busy handling.

