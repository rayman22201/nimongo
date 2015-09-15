import oids
import sequtils
import times
import streams
import sequtils
import strutils

# ------------- type: BsonKind -------------------#

type BsonKind* = enum
    BsonKindUnknown         = 0x00.char  ##
    BsonKindDouble          = 0x01.char  ## 64-bit floating-point
    BsonKindStringUTF8      = 0x02.char  ## UTF-8 encoded C string
    BsonKindDocument        = 0x03.char  ## Embedded document
    BsonKindArray           = 0x04.char  ## Embedded array of Bson values
    BsonKindBinary          = 0x05.char  ## Generic binary data
    BsonKindUndefined       = 0x06.char  ## Some undefined value (deprecated)
    BsonKindOid             = 0x07.char  ## Mongo Object ID
    BsonKindBool            = 0x08.char  ## boolean value
    BsonKindTimeUTC         = 0x09.char
    BsonKindNull            = 0x0A.char  ## nil value stored in Mongo
    BsonKindRegexp          = 0x0B.char
    BsonKindDBPointer       = 0x0C.char
    BsonKindJSCode          = 0x0D.char
    BsonKindDeprecated      = 0x0E.char  ## DEPRECATED
    BsonKindJSCodeWithScope = 0x0F.char
    BsonKindInt32           = 0x10.char  ## 32-bit integer number
    BsonKindTimestamp       = 0x11.char  ##
    BsonKindInt64           = 0x12.char  ## 64-bit integer number
    BsonKindMaximumKey      = 0x7F.char  ## Maximum MongoDB comparable value
    BsonKindMinimumKey      = 0xFF.char  ## Minimum MongoDB comparable value

type BsonSubtype* = enum
    BsonSubtypeGeneric      = 0x00.char  ##
    BsonSubtypeFunction     = 0x01.char  ##
    BsonSubtypeBinaryOld    = 0x02.char  ##
    BsonSubtypeUUIDOld      = 0x03.char  ##
    BsonSubtypeUUID         = 0x04.char  ##
    BsonSubtypeMD5          = 0x05.char  ##
    BsonSubtypeUserDefined  = 0x80.char  ##

converter toChar*(bk: BsonKind): char =
    ## Convert BsonKind to char
    return bk.char

converter toChar*(sub: BsonSubtype): char =
    ## Convert BsonSubtype to char
    return sub.char

converter toBsonKind*(c: char): BsonKind =
    ## Convert char to BsonKind
    return c.BsonKind

# ------------- type: Bson -----------------------#

type
  BsonTimestamp* = object ## Internal MongoDB type used by mongos instances
    increment*: int32
    timestamp*: int32

  Bson* = object of RootObj  ## Bson Node
    key: string
    case kind*: BsonKind
    of BsonKindDouble:          valueFloat64:   float64
    of BsonKindStringUTF8:      valueString:    string
    of BsonKindDocument:        valueDocument:  seq[Bson]
    of BsonKindArray:           valueArray:     seq[Bson]
    of BsonKindBinary:
                                valueBinary:    string
                                subtype:        BsonSubtype
    of BsonKindUndefined:       discard
    of BsonKindOid:             valueOid:       Oid
    of BsonKindBool:            valueBool:      bool
    of BsonKindTimeUTC:         valueTime:      Time
    of BsonKindNull:            discard
    of BsonKindRegexp:
                                expr1:          string
                                expr2:          string
    of BsonKindDBPointer:       discard
    of BsonKindJSCode:          valueCode:      string
    of BsonKindDeprecated:      valueDepr:      string
    of BsonKindJSCodeWithScope: valueCodeWS:    string
    of BsonKindInt32:           valueInt32:     int32
    of BsonKindTimestamp:       valueTimestamp: int64
    of BsonKindInt64:           valueInt64:     int64
    of BsonKindMaximumKey:      discard
    of BsonKindMinimumKey:      discard
    else:                       discard

converter toOid*(x: Bson): Oid =
    ## Convert Bson to Mongo Object ID
    return x.valueOid

converter toBson*(x: float64): Bson =
    ## Convert float64 to Bson object
    return Bson(key: "", kind: BsonKindDouble, valueFloat64: x)

converter toFloat64*(x: Bson): float64 =
    ## Convert Bson object to float64
    return x.valueFloat64

converter toString*(x: Bson): string =
    ## Convert Bson to UTF8 string
    return x.valueString

converter toBson*(x: string): Bson =
    ## Convert string to Bson object
    return Bson(key: "", kind: BsonKindStringUTF8, valueString: x)

converter toBson*(x: int64): Bson =
    ## Convert int64 to Bson object
    return Bson(key: "", kind: BsonKindInt64, valueInt64: x)

converter toBson*(x: int32): Bson =
    ## Convert int32 to Bson object
    return Bson(key: "", kind: BsonKindInt32, valueInt32: x)

converter toInt32*(x: Bson): int32 =
    ## Convert Bson to int32
    return x.valueInt32

converter toBson*(x: int): Bson =
    ## Convert int to Bson object
    return Bson(key: "", kind: BsonKindInt64, valueInt64: x)

converter toInt64*(x: Bson): int64 =
    ## Convert Bson object to int
    return x.valueInt64

converter toBson*(x: bool): Bson =
    ## Convert bool to Bson object
    return Bson(key: "", kind: BsonKindBool, valueBool: x)

converter toBool*(x: Bson): bool =
    ## Convert Bson object to bool
    return x.valueBool

converter toBson*(x: Oid): Bson =
    ## Convert Mongo Object Id to Bson object
    return Bson(key: "", kind: BsonKindOid, valueOid: x)

converter toBson*(x: Time): Bson =
    ## Convert Time to Bson object
    return Bson(key: "", kind: BsonKindTimeUTC, valueTime: x)

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

proc boolToBytes*(x: bool): string =
  ## Convert bool data piece into series of bytes
  if x == true: return $char(1)
  else: return $char(0)

proc oidToBytes*(x: Oid): string =
  ## Convert Mongo Object ID data piece into series to bytes
  let a = toSeq(cast[array[0..11, char]](x).items())
  return a.mapIt(string, $it).join()

proc bytes*(bs: Bson): string =
    ## Serialize Bson object into byte-stream
    case bs.kind
    of BsonKindDouble:
        return bs.kind & bs.key & char(0) & float64ToBytes(bs.valueFloat64)
    of BsonKindStringUTF8:
        return bs.kind & bs.key & char(0) & int32ToBytes(len(bs.valueString).int32 + 1) & bs.valueString & char(0)
    of BsonKindDocument:
        result = ""
        for val in bs.valueDocument: result = result & bytes(val)
        if bs.key != "":
            result = result & char(0)
            result = bs.kind & bs.key & char(0) & int32ToBytes(int32(len(result) + 4)) & result
        else:
            result = result & char(0)
            result = int32ToBytes(int32(len(result) + 4)) & result
    of BsonKindArray:
        result = ""
        for val in bs.valueArray: result = result & bytes(val)
        result = result & char(0)
        result = bs.kind & bs.key & char(0) & int32ToBytes(int32(len(result) + 4)) & result
    of BsonKindUndefined:
        return bs.kind & bs.key & char(0)
    of BsonKindOid:
        return bs.kind & bs.key & char(0) & oidToBytes(bs.valueOid)
    of BsonKindBool:
        return bs.kind & bs.key & char(0) & boolToBytes(bs.valueBool)
    of BsonKindTimeUTC:
        return bs.kind & bs.key & char(0) & int64ToBytes(int64(bs.valueTime.toSeconds() * 1000))
    of BsonKindNull:
        return bs.kind & bs.key & char(0)
    of BsonKindInt32:
        return bs.kind & bs.key & char(0) & int32ToBytes(bs.valueInt32)
    of BsonKindInt64:
        return bs.kind & bs.key & char(0) & int64ToBytes(bs.valueInt64)
    of BsonKindMinimumKey:
        return bs.kind & bs.key & char(0)
    of BsonKindMaximumKey:
        return bs.kind & bs.key & char(0)
    else:
        echo "BYTES: ", bs.kind
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
        of BsonKindArray:
            var res: string = ""
            res = res & "\"" & bs.key & "\": ["
            ident = ident & "  "
            for i, item in bs.valueArray:
                if i == len(bs.valueArray) - 1: res = res & stringify(item)
                else: res = res & stringify(item) & ", "
            ident = ident[0..len(ident) - 3]
            res = res & "]"
            return res
        of BsonKindBinary:
            var res: string = "\"$#\" ($#): [" % [bs.key, $bs.subtype]
            for i in bs.valueBinary:
                res = res & $ord(i)
            return res & "]"
        of BsonKindUndefined:
            return "\"$#\": null" % [bs.key]
        of BsonKindOid:
            return "\"$#\": {\"$$oid\": \"$#\"}" % [bs.key, $bs.valueOid]
        of BsonKindBool:
            return "\"$#\": $#" % [bs.key, if bs.valueBool == true: "true" else: "false"]
        of BsonKindTimeUTC:
            return "\"$#\": $#" % [bs.key, $bs.valueTime]
        of BsonKindNull:
            return "\"$#\": null" % [bs.key]
        of BsonKindInt32:
            return "\"$#\": \"$#\"" % [bs.key, $bs.valueInt32]
        of BSonKindInt64:
            return "\"$#\": \"$#\"" % [bs.key, $bs.valueInt64]
        of BsonKindMinimumKey:
            return "\"$#\": {\"$$minkey\": 1}" % [bs.key]
        of BsonKindMaximumKey:
            return "\"$#\": {\"$$maxkey\": 1}" % [bs.key]
        else:
            echo bs.kind
            raise new(Exception)
    return stringify(bs)

proc initBsonDocument*(): Bson =
    ## Create new top-level Bson document
    result = Bson(
        key: "",
        kind: BsonKindDocument,
        valueDocument: newSeq[Bson]()
    )

proc initBsonArray*(): Bson =
    ## Create new Bson array
    result = Bson(
        key: "",
        kind: BsonKindArray,
        valueArray: newSeq[Bson]()
    )

template B*: expr =
    initBsonDocument()

template B*(key: string, val: Bson): expr =  ## Shortcut for _initBsonDocument
    initBsonDocument()(key, val)

template B*[T](key: string, values: seq[T]): expr =
    initBsonDocument()(key, values)

proc undefined*(): Bson =
  ## Create new Bson 'undefined' value
  return Bson(key: "", kind: BsonKindUndefined)

proc null*(): Bson =
  ## Create new Bson 'null' value
  return Bson(key: "", kind: BsonKindNull)

proc minkey*(): Bson =
  ## Create new Bson value representing 'Min key' bson type
  return Bson(key: "", kind: BsonKindMinimumKey)

proc maxkey*(): Bson =
  ## Create new Bson value representing 'Max key' bson type
  return Bson(key: "", kind: BsonKindMaximumKey)

proc `()`*(bs: Bson, key: string, val: Bson): Bson {.discardable.} =
    ## Add field to bson object
    result = bs
    var value: Bson = val
    value.key = key
    result.valueDocument.add(value)

proc `()`*[T](bs: Bson, key: string, values: seq[T]): Bson {.discardable.} =
    ## Add array field to bson object
    result = bs

    var arr: Bson = initBsonArray()

    arr.kind = BsonKindArray
    arr.valueArray = @[]
    arr.key = key

    var counter = 0
    for val in values.items():
        var tmpVal: Bson = val
        tmpVal.key = $counter
        arr.valueArray.add(tmpVal)
        inc(counter)

    result.valueDocument.add(arr)

proc `[]`*(bs: Bson, key: string): Bson =
    ## Get Bson document field
    if bs.kind == BsonKindDocument:
        for item in bs.valueDocument:
            if item.key == key:
                return item
    else:
        raise new(Exception)

proc `[]`*(bs: Bson, key: int): Bson =
    ## Get Bson array item by index
    if bs.kind == BsonKindArray:
        return bs.valueArray[key]
    else:
        raise new(Exception)

proc initBsonDocument*(bytes: string): Bson =
    ## Create new Bson document from byte stream
    let
        stream: Stream = newStringStream(bytes)
        docSize: int32 = stream.readInt32()
    var document: Bson = initBsonDocument()

    let parseBson = proc(s: Stream, doc: Bson): Bson =
        let kind: BsonKind = s.readChar()
        var name: TaintedString = ""
        discard s.readLine(name)
        case kind:
        of BsonKindDouble:
            return doc(name.string, s.readFloat64())
        of BsonKindStringUTF8:
            let valueString: string = s.readStr(s.readInt32() - 1)
            discard s.readChar()
            return doc(name.string, valueString)
        of BsonKindDocument:
            let ds: int32 = stream.readInt32()
            s.setPosition(s.getPosition() - 4)
            var subdoc = initBsonDocument(s.readStr(ds))
            return doc(name.string, subdoc)
        of BsonKindArray:
            let ds: int32 = stream.readInt32()
            s.setPosition(s.getPosition() - 4)
            var subdoc = initBsonDocument(s.readStr(ds))
            var subarr = initBsonArray()
            subarr.valueArray = subdoc.valueDocument
            return doc(name.string, subarr)
        of BsonKindUndefined:
            return doc(name.string, undefined())
        of BsonKindOid:
            let valueOid: Oid = cast[Oid](s.readStr(12).cstring)
            return doc(name.string, valueOid)
        of BsonKindBool:
            return doc(name.string, if s.readChar() == 0.char: false else: true)
        of BsonKindTimeUTC:
            let timeUTC: Bson = Bson(key: name, kind: BsonKindTimeUTC, valueTime: fromSeconds(s.readInt64().float64 / 1000))
            return doc(name.string, timeUTC)
        of BsonKindNull:
            return doc(name.string, null())
        of BsonKindInt32:
            return doc(name.string, s.readInt32())
        of BsonKindInt64:
            return doc(name.string, s.readInt64())
        of BsonKindMinimumKey:
            return doc(name.string, minkey())
        of BsonKindMaximumKey:
            return doc(name.string, maxkey())
        else:
            raise new(Exception)

    while stream.readChar() != 0.char:
        stream.setPosition(stream.getPosition() - 1)
        document = parseBson(stream, document)

    return document

when isMainModule:
    echo "Testing nimongo/bson.nim module..."
    let oid = genOid()
    var bdoc: Bson = initBsonDocument()(
        "balance", 1000.23)(
        "name", "John")(
        "someId", oid)(
        "someTrue", true)(
        "surname", "Smith")(
        "someNull", null())(
        "minkey", minkey())(
        "maxkey", maxkey())(
        "undefined", undefined())(
        "subdoc", initBsonDocument()(
            "salary", 500
        )(
        "array", @["hello", "wold"]
        )
    )
    echo bdoc
    let bbytes = bdoc.bytes()
    let recovered = initBsonDocument(bbytes)
    echo "RECOVERED: ", recovered
