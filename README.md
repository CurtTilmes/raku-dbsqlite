DB::SQLite - SQLite access for Raku
===================================

[![Build Status](https://travis-ci.org/CurtTilmes/raku-dbsqlite.svg)](https://travis-ci.org/CurtTilmes/raku-dbsqlite)

This is a reimplementation of Raku bindings for SQLite.

Basic usage
-----------

```raku
my $s = DB::SQLite.new();  # You can pass in various connection options
```

Execute a query, and get a single value:
```raku
say $s.query('select 42').value;
# 42
```

Create a table:
```raku
$s.execute('create table foo (x int, y text)');
```

Insert some values using placeholders:
```raku
$s.query('insert into foo (x,y) values (?,?)', 1, 'this');
```

Or even fancy placeholders:
```raku
$s.query('insert into foo (x,y) values ($x,$y)', x => 2, y => 'that');
```

Execute a query returning a row as an array or hash;
```raku
say $s.query('select * from foo where x = $x', :x(1)).array;
say $s.query('select * from foo where x = $x', :2x).hash;
```

Execute a query returning a bunch of rows as arrays or hashes:

```raku
.say for $s.query('select * from foo').arrays;
.say for $s.query('select * from foo').hashes;
```

Connection Information
----------------------

When you create a **DB::SQLite** object, you can specify a `filename`
option to `.new` for the database to open.  If it isn't specified, it
will default to an empty string which causes a private, temporary
on-disk database to be created.  This will be useless if you use more
than one connection, since each will get its own database, but maybe
you want that..

If you specify `filename => ':memory:'` you will get a private,
temporary, in-memory database.  Again, this will not be shared across
connections.

You can also use a `busy-timeout` option to specify in
milliseconds, the amount of sleeping to wait for a locked table to
become available.  This defaults to 10000 (10 seconds).  Setting to
zero will turn off busy handling.

```raku
use DB::SQLite;

my $s = DB::SQLite.new(filename => 'this.db', busy-timeout => 50000);
```

You can also pass in additional extended open flags, such as
'readonly':

```raku
my $s = DB::SQLite.new(filename => 'this.db', :readonly);
```

Depending on your sqlite version, Flags may include: readonly,
readwrite, create, deleteonclose, exclusive, autoproxy, uri, memory,
main_db, temp_db, transient_db, main_journal, temp_journal,
subjournal, super_journal, nomutex, fullmutex, sharedcache,
privatecache, wal, nofollow.  Refer to the SQLite docs for more
information on them.

DB::SQLite::Connection
----------------------

The main **DB::SQLite** object acts as a factory for connections,
maintaining a cache of connections already created.  A new connection
can be requested with the `.db` method, but often this isn't needed.
When you are finished with a connection, you can explicitly return it
to the cache with `.finish`.

You can call `.query()` or `.execute()` on the main **DB::SQLite**
object, but all they really do is allocate a
**DB::SQLite::Connection** (either from the cache, or create a new
one) and call those methods on it, then return the connection to the
cache.

These are equivalent:

```raku
.say for $s.query('select * from foo').arrays;
```

```raku
my $db = $s.db;
.say for $db.query('select * from foo').arrays;
$db.finish;
```

The connection object also has some extra methods for separately
preparing and executing the query:

```raku
my $db = $s.db;
my $sth = $db.prepare('insert into foo (x,y) values (?,?)');
$sth.execute(1, 'this');
$sth.execute(2, 'that');
$db.finish;
```

You can also call `.finish()` on the statement:

```raku
my $sth = $s.db.prepare('insert into foo (x,y) values (?,?)');
$sth.execute(1, 'this');
$sth.execute(2, 'that');
$sth.finish;
```

The statement will finish the associated connection, returning it to
the cache.  Yet another way to do it is to pass `:finish` in to the
execute.

```raku
my $sth = $s.db.prepare('insert into foo (x,y) values (?,?)');
$sth.execute(1, 'this');
$sth.execute(2, 'that', :finish);
```

And finally, a cool Perl 6ish way is the `will` trait to install a
Phaser directly on the variable:

```raku
{
    my $sth will leave { .finish } = $s.db.prepare('insert into foo (x,y) values (?,?)');
    $sth.execute(1, 'this');
    $sth.execute(2, 'that');
}
```

Calling `.prepare()` on the **DB::SQLite::Connection** prepares and
returns a **DB::SQLite::Statement** that can then be `.execute()`ed.
The prepared statement is also retained in a cache with the
connection.  If the same statement is prepared again on the same
connection, the cached object will be returned instead of
re-preparing.  If you don't want it to be cached, you can pass in the
`:nocache` option.


```raku
my $sth = $s.db.prepare('insert into foo (x,y) values (?,?)', :nocache);
$sth.execute(1, 'this');
$sth.execute(2, 'that', :finish);
```

You must still take care to call `.finish()` to return the connection
to the connection cache so it will get reused.  (Or take care NOT to
call `.finish()` if you don't want the connection to be reused,
possibly in another thread.)

For the main object, or the connection object, `.execute()` is used
instead of `.query()` under two conditions:

1. You don't need placeholders/arguments.
2. You don't want the results.

As a special added bonus you can execute multiple statements separated
by semi-colons in one shot:

```raku
$s.execute(q:to/END/);
create table foo
(
   x int,
   y text
);
insert into foo (x,y) values (1, 'this');
insert into foo (x,y) values (2, 'that');
END
```

Transactions
------------

The database connection object can also manage transactions with the
`.begin`, `.commit`, and `.rollback` methods:

```raku
my $db = $s.db;
my $sth = $db.prepare('insert into foo (x,y) values (?,?)');
$db.begin;
$sth.execute(1, 'this');
$sth.execute(2, 'that');
$db.commit;
$db.finish;
```
The `begin`/`commit` ensure that the statements between them happen
atomically, either all or none.

Transactions can also dramatically improve performance for some
actions, such as performing thousands of inserts/deletes/updates since
the indexes for the affected table can be updated in bulk once for the
entire transaction.

If you `.finish` the database prior to a `.commit`, an uncommitted
transaction will automatically be rolled back.

As a convenience, `.commit` also returns the database object, so you
can just `$db.commit.finish`.

Placeholders and Binding
------------------------

SQLite parameters can take several different forms:

* ?
* ?_NNN_
* :_AAA_
* $_AAA_
* @_AAA_

Where _NNN_ is an integer value, and _AAA_ is an identifier.  When
calling execute, the numbered binds are bound starting with 1 from the
arguments to `.execute` (or `.query`):

```raku
my $sth = $s.db.prepare('select ?1, ?2, ?3');
say $sth.execute(1,2,3).array;
$sth.finish;
```

The named binds with $_AAA_ placeholders are bound with named
parameter pairs:

```raku
my $sth = $s.db.prepare('select $x, $y, $z');
say $sth.execute(:x(1), :y(2), :z(3)).array;
say $sth.execute(x => 1, y => 2, z => 3).array; # same thing
$sth.finish;
```

Binding the other placeholders is a little more complicated.  They
must be bound explicitly prior to calling `.execute()` (This will work
with numbered placeholders too.):

```raku
my $sth = $s.db.prepare('select :x, $y, @z');
$sth.bind(':x', 1)
$sth.bind('$y', 2)
$sth.bind('@z', 3)
$sth.execute();
$sth.finish;
```

You don't have to bind every placeholder.  If you leave one out, it
just gets a `NULL`.  If you `.execute` multiple times with the same
statement, it will use whatever bindings are in place from previous
executions.  Since by default, statements get cached and re-used, the
safest approach is always to bind every placeholder, even ones you
want to be `NULL`. (Bind with an undefined type, such as `Any` for
`NULL`).

You can even mix and match numbered and named placeholders if you want
to (and are careful).

Results
-------

Calling `.query()` on a **DB::SQLite** or **DB::SQLite::Connection**,
or calling `.execute()` on a **DB::SQLite::Statement** with an SQL
SELECT or something that returns data, a `DB::SQLite::Result` object
will be returned.

The query results can be consumed from that object with the following
methods:

* `.value` - a single scalar result
* `.array` - a single array of results from one row
* `.hash` - a single hash of results from one row
* `.arrays` - a sequence of arrays of results from all rows
* `.hashes` - a sequence of hashes of results from all rows

If the query isn't a select or otherwise doesn't return data, such as
an INSERT, UPDATE, or DELETE, it will return the number of rows
affected.

Exceptions
----------

All database errors, including broken SQL queries, are thrown as exceptions.

Acknowledgements
----------------

Inspiration taken from the existing Raku
[DBIish](https://github.com/raku-community-modules/DBIish) module as
well as the Perl 5 [Mojo::Pg](http://mojolicious.org/perldoc/Mojo/Pg)
from the Mojolicious project.

Thanks to hythm7 for contributing to the open flags capability.

License
-------

Portions thanks to DBIish:

Copyright © 2009-2016, the DBIish contributors All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
