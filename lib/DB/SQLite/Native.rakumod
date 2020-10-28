use NativeLibs:ver<0.0.7+>:auth<github:salortiz>;
use BitEnum;

sub LIBSQLITE {
    NativeLibs::Searcher.at-runtime(
         'sqlite3', 'sqlite3_version', 0).()
}

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

enum SQLITE_FILE_OPEN_FLAGS (
    SQLITE_OPEN_READONLY      => 0x00000001,
    SQLITE_OPEN_READWRITE     => 0x00000002,
    SQLITE_OPEN_CREATE        => 0x00000004,
    SQLITE_OPEN_DELETEONCLOSE => 0x00000008,
    SQLITE_OPEN_EXCLUSIVE     => 0x00000010,
    SQLITE_OPEN_AUTOPROXY     => 0x00000020,
    SQLITE_OPEN_URI           => 0x00000040,
    SQLITE_OPEN_MEMORY        => 0x00000080,
    SQLITE_OPEN_MAIN_DB       => 0x00000100,
    SQLITE_OPEN_TEMP_DB       => 0x00000200,
    SQLITE_OPEN_TRANSIENT_DB  => 0x00000400,
    SQLITE_OPEN_MAIN_JOURNAL  => 0x00000800,
    SQLITE_OPEN_TEMP_JOURNAL  => 0x00001000,
    SQLITE_OPEN_SUBJOURNAL    => 0x00002000,
    SQLITE_OPEN_SUPER_JOURNAL => 0x00004000,
    SQLITE_OPEN_NOMUTEX       => 0x00008000,
    SQLITE_OPEN_FULLMUTEX     => 0x00010000,
    SQLITE_OPEN_SHAREDCACHE   => 0x00020000,
    SQLITE_OPEN_PRIVATECACHE  => 0x00040000,
    SQLITE_OPEN_WAL           => 0x00080000,
    SQLITE_OPEN_NOFOLLOW      => 0x01000000
);

my constant NULL = Pointer;

class DB::SQLite::Native is repr('CPointer') {...}

sub sqlite3_errstr(int32 --> Str) is native(LIBSQLITE) {}

class DB::SQLite::Error is Exception
{
    has Int $.code;
    has Str $.message = sqlite3_errstr($!code);
}

class DB::SQLite::Native::Statement is repr('CPointer')
{
    method db(--> DB::SQLite::Native)
        is native(LIBSQLITE) is symbol('sqlite3_db_handle') {}

    method check($code = $.db.errcode) is hidden-from-backtrace
    {
        $.db.check($code) unless $code == SQLITE_OK
    }

    method step(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_step') {}

    method bind-blob(int32, Blob, int32, Pointer --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_bind_blob') {}

    method bind-double(int32, num64 --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_bind_double') {}

    method bind-int64(int32, int64 --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_bind_int64') {}

    method bind-null(int32 --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_bind_null') {}

    method bind-text(int32, Str, int32, Pointer --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_bind_text') {}

    multi method bind(Int $n, Blob:D $b --> Nil)
    {
        $.bind-blob($n, $b, $b.bytes, Pointer.new(-1)) == SQLITE_OK or $.check
    }

    multi method bind(Int $n, Real:D $v --> Nil)
    {
        $.bind-double($n,$v.Num) == SQLITE_OK or $.check
    }

    multi method bind(Int $n, Int:D $v --> Nil)
    {
        $.bind-int64($n,$v) == SQLITE_OK or $.check
    }

    multi method bind(Int $n, IntStr:D $v --> Nil)
    {
        $.bind-int64($n,$v) == SQLITE_OK or $.check
    }

    multi method bind(Int $n, Any:U --> Nil)
    {
        $.bind-null($n) == SQLITE_OK or $.check
    }

    multi method bind(Int $n, Str:D $v --> Nil)
    {
        $.bind-text($n, $v, -1, Pointer.new(-1)) == SQLITE_OK or $.check
    }

    method param-index(Str $name --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_bind_parameter_index') {}

    multi method bind(Str:D $name, |rest)
    {
        $.bind($.param-index($name ~~ /^<[:@$]>/ ?? $name !! ('$' ~ $name)),
               |rest)
    }

    method count(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_column_count') {}

    method name(int32 $iCol --> Str)
        is native(LIBSQLITE) is symbol('sqlite3_column_name') {}

    method type(int32 $iCol --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_column_type') {}

    method bytes(int32 $iCol --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_column_bytes') {}

    method blob(int32 $iCol --> CArray[uint8])
        is native(LIBSQLITE) is symbol('sqlite3_column_blob') {}

    method double(int32 $iCol --> num64)
        is native(LIBSQLITE) is symbol('sqlite3_column_double') {}

    method int64(int32 $iCol --> int64)
        is native(LIBSQLITE) is symbol('sqlite3_column_int64') {}

    method text(int32 $iCol --> Str)
        is native(LIBSQLITE) is symbol('sqlite3_column_text') {}

    method finalize(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_finalize') {}

    method reset(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_reset') {}

    method clear(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_clear_bindings') {}

    method sql(--> Str)
        is native(LIBSQLITE) is symbol('sqlite3_sql') {}
}

class DB::SQLite::Native
{
    method libversion-number(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_libversion_number') {}

    method libversion(--> Str)
        is native(LIBSQLITE) is symbol('sqlite3_libversion') {}

    method threadsafe(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_threadsafe') {}

    method memory-used(--> int64)
        is native(LIBSQLITE) is symbol('sqlite3_memory_used') {}

    method memory-highwater(int32 $resetFlag --> int64)
        is native(LIBSQLITE) is symbol('sqlite3_memory_highwater') {}

    method errcode(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_errcode') {}

    method extended-errcode(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_extended_errcode') {}

    method errmsg(--> Str)
        is native(LIBSQLITE) is symbol('sqlite3_errmsg') {}

    method check(int32 $code = $.errcode) is hidden-from-backtrace
    {
        die DB::SQLite::Error.new(:$code) unless $code == SQLITE_OK
    }

    method busy-timeout(int32 --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_busy_timeout') {}

    sub sqlite3_open_v2(Str $filename,
                        DB::SQLite::Native $handle is rw,
                        int32 $flags,
                        Str $zVfs --> int32)
        is native(LIBSQLITE) {}

    method close( --> int32)
        is native(LIBSQLITE) is symbol('sqlite3_close_v2') {}

    method open(Str:D $filename, *%flags --> DB::SQLite::Native)
    {
        my DB::SQLite::Native $handle .= new;
        UNDO .close with $handle;

        my $flags = BitEnum[SQLITE_FILE_OPEN_FLAGS, :lc,
                            prefix => 'SQLITE_OPEN_'].new(%flags.keys);

        $flags.set(<readwrite create>) unless $flags.isset(<readonly>) ||
                                              $flags.isset(<readwrite>);

        $.check(sqlite3_open_v2($filename, $handle, +$flags, Str));
        return $handle;
    }

    sub sqlite3_prepare_v2(DB::SQLite::Native $handle,
                           Str $zSql,
                           int32 $nByte,
                           DB::SQLite::Native::Statement $ppStmt is rw,
                           Pointer $pzTail --> int32)
        is native(LIBSQLITE) {}

    method prepare(Str:D $sql) is hidden-from-backtrace
    {
        my DB::SQLite::Native::Statement $stmt .= new;
        UNDO .finalize with $stmt;
        $.check(sqlite3_prepare_v2(self, $sql, -1, $stmt, Pointer));
        return $stmt;
    }

    method changes(--> int32)
        is native(LIBSQLITE) is symbol('sqlite3_changes') {}

    method sqlite3_exec(Str, Pointer, Pointer, Pointer --> int32)
        is native(LIBSQLITE) {}

    method exec(Str:D $sql)
    {
        $.check($.sqlite3_exec($sql, NULL, NULL, NULL));
    }
}

