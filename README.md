DB::SQLite - SQLite access for Perl 6
=====================================

This is a reimplementation of Perl 6 bindings for SQLite.

Basic usage
-----------

```perl6
my $s = DB::SQLite.new();  # You can pass in various options
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

Execute a query returning a row as an array or hash;
```perl6
say $s.query('select * from foo where x = ?', 1).array;
say $s.query('select * from foo where x = ?', 1).hash;
```

Execute a query returning a bunch of rows as arrays or hashes:

```perl6
.say for $s.query('select * from foo').arrays;
.say for $s.query('select * from foo').hashes;
```

`.query()` caches a prepared statement, and can have placeholders and
arguments - `.execute()` does not prepare/cache and can't have
placeholders and doesn't return results.  It retuns an integer with
the number of rows affected by an action.

