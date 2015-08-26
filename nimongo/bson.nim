import oids
import sequtils
import tables
import streams
import sequtils
import strutils

# ------------- type: BsonKind -------------------#

type BsonKind* = enum
    BsonKindGeneric         = 0x00.char
    BsonKindDouble          = 0x01.char  ## 64-bit floating-point
    BsonKindStringUTF8      = 0x02.char  ## UTF-8 encoded C string
    BsonKindDocument        = 0x03.char
    BsonKindArray           = 0x04.char  ## Like document with numbers as keys
    BsonKindBinary          = 0x05.char
    BsonKindUndefined       = 0x06.char
    BsonKindOid             = 0x07.char  ## Mongo Object ID
    BsonKindBool            = 0x08.char
    BsonKindTimeUTC         = 0x09.char
    BsonKindNull            = 0x0A.char  ## nil value stored in Mongo
    BsonKindRegexp          = 0x0B.char
    BsonKindDBPointer       = 0x0C.char
    BsonKindJSCode          = 0x0D.char
    BsonKindDeprecated      = 0x0E.char
    BsonKindJSCodeWithScope = 0x0F.char
    BsonKindInt32           = 0x10.char  ## 32-bit integer number
    BsonKindTimestamp       = 0x11.char
    BsonKindInt64           = 0x12.char  ## 64-bit integer number
    BsonKindMaximumKey      = 0x7F.char
    BsonKindMinimumKey      = 0xFF.char

converter toChar*(bk: BsonKind): char = bk.char  ## Convert BsonKind to char

# ------------- type: Bson -----------------------#

type
    Bson* = object of RootObj  ## Bson Node
        key: string
        case kind: BsonKind
        of BsonKindGeneric:    discard
        of BsonKindDouble:     valueFloat64:  float64    ## +
        of BsonKindStringUTF8: valueString:   string     ## +
        of BsonKindDocument:   valueDocument: seq[Bson]  ## +
        of BsonKindArray:      valueArray:    seq[Bson]
        of BsonKindBinary:     valueBinary:   cstring
        of BsonKindUndefined:  discard
        of BsonKindOid:        valueOid:      Oid
        of BsonKindBool:       valueBool:     bool
        of BsonKindNull:       discard
        of BsonKindInt32:      valueInt32:    int32
        of BsonKindInt64:      valueInt64:    int64
        else: discard

converter toBson*(x: float64): Bson =
    ## Convert float64 to Bson object
    return Bson(key: "", kind: BsonKindDouble, valueFloat64: x)

converter toBson*(x: string): Bson =
    ## Convert string to Bson object
    return Bson(key: "", kind: BsonKindStringUTF8, valueString: x)

converter toBson*(x: int64): Bson =
    ## Convert int64 to Bson object
    return Bson(key: "", kind: BsonKindInt64, valueInt64: x)

converter toBson*(x: int32): Bson =
    ## Convert int32 to Bson object
    return Bson(key: "", kind: BsonKindInt32, valueInt32: x)

converter toBson*(x: int): Bson =
    ## Convert int to Bson object
    return Bson(key: "", kind: BsonKindInt64, valueInt64: x)

proc int32ToBytes*(x: int32): string =
    ## Convert int32 data piece into series of bytes
    let a = toSeq(cast[array[0..3, char]](x).items())
    return a.mapIt(string, $it).join()

proc float64ToBytes*(x: float64): string =
  ## Convert float64 data piece into series of bytes
  let a = toSeq(cast[array[0..7, char]](x).items())
  return a.mapIt(string, $it).join()

proc int64ToBytes*(x: int64): string =
  ## Convert int64 data piece into series of bytes
  let a = toSeq(cast[array[0..7, char]](x).items())
  return a.mapIt(string, $it).join()

proc bytes*(bs: Bson): string =
    ## Serialize Bson object into byte-stream
    case bs.kind
    of BsonKindDouble:
        return bs.kind & bs.key & char(0) & float64ToBytes(bs.valueFloat64)
    of BsonKindStringUTF8:
        return bs.kind & bs.key & char(0) & int32ToBytes(len(bs.valueString).int32 + 1) & bs.valueString & char(0)
    of BsonKindNull:
        return bs.kind & bs.key & char(0)
    of BsonKindInt32:
        return bs.kind & bs.key & char(0) & int32ToBytes(bs.valueInt32)
    of BsonKindInt64:
        return bs.kind & bs.key & char(0) & int64ToBytes(bs.valueInt64)
    of BsonKindDocument:
        result = ""
        for val in bs.valueDocument: result = result & bytes(val)
        if bs.key != "":
            result = bs.kind & bs.key & char(0) & result
        else:
            result = result & char(0)
        result = int32ToBytes(int32(len(result) + 4)) & result
    else:
        raise new(Exception)

proc `$`*(bs: Bson): string =
    ## Serialize Bson document into readable string
    var ident = ""
    proc stringify(bs: Bson): string =
        case bs.kind
        of BsonKindDouble:
            return "\"$#\": $#" % [bs.key, $bs.valueFloat64]
        of BsonKindStringUTF8:
            return "\"$#\": \"$#\"" % [bs.key, bs.valueString]
        of BsonKindDocument:
            var res: string = ""
            if bs.key != "":
                res = res & ident[0..len(ident) - 3] & "\"" & bs.key & "\":\n"
            res = res & ident & "{\n"
            ident = ident & "  "
            for i, item in bs.valueDocument:
                if i == len(bs.valueDocument) - 1: res = res & ident & stringify(item) & "\n"
                else: res = res & ident & stringify(item) & ",\n"
            ident = ident[0..len(ident) - 3]
            res = res & ident & "}"
            return res
        else:
            raise new(Exception)
    return stringify(bs)

proc initBsonDocument*(): Bson =
    ## Create new top-level Bson document
    result = Bson(
        key: "",
        kind: BsonKindDocument,
        valueDocument: newSeq[Bson]()
    )

proc null*(): Bson =
    ## Create new Bson 'null' value
    return Bson(key: "", kind: BsonKindNull)

proc `()`*(bs: Bson, key: string, val: Bson): Bson {.discardable.} =
    ## Add field to bson object
    result = bs
    var value: Bson = val
    value.key = key
    result.valueDocument.add(value)

when isMainModule:
    echo "Testing nimongo/bson.nim module..."
    var bdoc: Bson = initBsonDocument()(
        "balance", 1000.23)(
        "name", "John")(
        "surname", "Smith")(
        "subdoc", initBsonDocument()(
            "salary", 500.0
        )
    )
    var bdoc2: Bson = initBsonDocument()("balance", 1000.23)
    for i in bdoc2.bytes():
        stdout.write(ord(i))
        stdout.write(" ")
    echo ""
