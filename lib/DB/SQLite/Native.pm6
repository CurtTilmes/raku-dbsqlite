use NativeCall;

my constant LIB = 'sqlite3';

enum SQLITE (
    SQLITE_OK   => 0,
    SQLITE_ROW  => 100,
    SQLITE_DONE => 101
);

enum SQLITE_TYPE (
    SQLITE_INTEGER => 1,
    SQLITE_FLOAT   => 2,
    SQLITE_TEXT    => 3,
    SQLITE_BLOB    => 4,
    SQLITE_NULL    => 5
);

my constant NULL = Pointer;

class DB::SQLite::Native is repr('CPointer') {...}

class DB::SQLite::Error is Exception
{
    has Int $.code;
    has Str $.message = DB::SQLite::Native.errstr($!code);
}

class DB::SQLite::Native::Statement is repr('CPointer')
{
    method db(--> DB::SQLite::Native)
        is native(LIB) is symbol('sqlite3_db_handle') {}

    method check(int32 $code)
    {
        $.db.check($code) unless $code == SQLITE_OK
    }

    method step(--> int32)
        is native(LIB) is symbol('sqlite3_step') {}

    method bind-blob(int32, Blob, int32, Pointer --> int32)
        is native(LIB) is symbol('sqlite3_bind_blob') {}

    multi method bind(Int $n, Blob:D $b)
    {
        $.check($.bind-blob($n, $b, $b.bytes, Pointer.new(-1)))
    }

    method bind-double(int32, num64 --> int32)
        is native(LIB) is symbol('sqlite3_bind_double') {}

    multi method bind(Int $n, Real:D $v)
    {
        $.check($.bind-double($n,$v.Num))
    }

    method bind-int64(int32, int64 --> int32)
        is native(LIB) is symbol('sqlite3_bind_int64') {}

    multi method bind(Int $n, Int:D $v)
    {
        $.check($.bind-int64($n,$v));
    }

    method bind-null(int32 --> int32)
        is native(LIB) is symbol('sqlite3_bind_null') {}

    multi method bind(Int $n, Any:U)
    {
        $.check($.bind-null($n))
    }

    method bind-text(int32, Str, int32, Pointer --> int32)
        is native(LIB) is symbol('sqlite3_bind_text') {}

    multi method bind(Int $n, Str:D $v)
    {
        $.check($.bind-text($n, $v, -1, Pointer.new(-1)))
    }

    method param-index(Str $name --> int32)
        is native(LIB) is symbol('sqlite3_bind_parameter_index') {}

    multi method bind(Str:D $name where /^<[:@$]>/, |rest)
    {
        $.bind($.param-index($name), |rest)
    }

    multi method bind(Str:D $name, |rest)
    {
        $.bind($.param-index('$' ~ $name), |rest)
    }

    method count(--> int32)
        is native(LIB) is symbol('sqlite3_column_count') {}

    method name(int32 $iCol --> Str)
        is native(LIB) is symbol('sqlite3_column_name') {}

    method type(int32 $iCol --> int32)
        is native(LIB) is symbol('sqlite3_column_type') {}

    method bytes(int32 $iCol --> int32)
        is native(LIB) is symbol('sqlite3_column_bytes') {}

    method blob(int32 $iCol --> CArray[uint8])
        is native(LIB) is symbol('sqlite3_column_blob') {}

    method double(int32 $iCol --> num64)
        is native(LIB) is symbol('sqlite3_column_double') {}

    method int64(int32 $iCol --> int64)
        is native(LIB) is symbol('sqlite3_column_int64') {}

    method text(int32 $iCol --> Str)
        is native(LIB) is symbol('sqlite3_column_text') {}

    method finalize(--> int32)
        is native(LIB) is symbol('sqlite3_finalize') {}

    method reset(--> int32)
        is native(LIB) is symbol('sqlite3_reset') {}

    method clear(--> int32)
        is native(LIB) is symbol('sqlite3_clear_bindings') {}

    method sql(--> Str)
        is native(LIB) is symbol('sqlite3_sql') {}
}

class DB::SQLite::Native
{
    method libversion-number(--> int32)
        is native(LIB) is symbol('sqlite3_libversion_number') {}

    method libversion(--> Str)
        is native(LIB) is symbol('sqlite3_libversion') {}

    method threadsafe(--> int32)
        is native(LIB) is symbol('sqlite3_threadsafe') {}

    method memory-used(--> int64)
        is native(LIB) is symbol('sqlite3_memory_used') {}

    method memory-highwater(int32 $resetFlag --> int64)
        is native(LIB) is symbol('sqlite3_memory_highwater') {}

    method errcode(--> int32)
        is native(LIB) is symbol('sqlite3_errcode') {}

    method extended-errcode(-->int32)
        is native(LIB) is symbol('sqlite3_extended_errcode') {}

    method errmsg(--> Str)
        is native(LIB) is symbol('sqlite3_errmsg') {}

    method errstr(int32 --> Str)
        is native(LIB) is symbol('sqlite3_errstr') {}

    method check(int32 $code) is hidden-from-backtrace
    {
        die DB::SQLite::Error.new(:$code, message => $.errmsg)
            unless $code == SQLITE_OK
    }

    method busy-timeout(int32 --> int32)
        is native(LIB) is symbol('sqlite3_busy_timeout') {}

    sub sqlite3_open(Str $filename, DB::SQLite::Native $handle is rw --> int32)
        is native(LIB) {}

    method close( --> int32)
        is native(LIB) is symbol('sqlite3_close_v2') {}

    method open(Str:D $filename --> DB::SQLite::Native)
    {
        my DB::SQLite::Native $handle .= new;
        UNDO .close with $handle;
        $.check(sqlite3_open($filename, $handle));
        return $handle;
    }

    sub sqlite3_prepare_v2(DB::SQLite::Native $handle,
                           Str $zSql,
                           int32 $nByte,
                           DB::SQLite::Native::Statement $ppStmt is rw,
                           Pointer $pzTail --> int32)
        is native(LIB) {}

    method prepare(Str:D $sql) is hidden-from-backtrace
    {
        my DB::SQLite::Native::Statement $stmt .= new;
        UNDO .finalize with $stmt;
        $.check(sqlite3_prepare_v2(self, $sql, -1, $stmt, Pointer));
        return $stmt;
    }

    method changes(--> int32)
        is native(LIB) is symbol('sqlite3_changes') {}

    method sqlite3_exec(Str, Pointer, Pointer, Pointer --> int32)
        is native(LIB) {}

    method exec(Str:D $sql)
    {
        $.check($.sqlite3_exec($sql, NULL, NULL, NULL));
        return $.changes
    }
}

