/*
 * Primitive Cypher Grammar
 * ==========================
 *
 * Samples:
 *
 * MATCH (a) RETURN a
 */

{
  function combine(first, rest, combiners) {
    var result = first, i;

    for (i = 0; i < rest.length; i++) {
      result = combiners[rest[i][1]](result, rest[i][3]);
    }

    return result;
  }
}


Clause
  = "MATCH" _ pat:Pattern _ "RETURN" _ "a" {
    return "matching pattern:" + pat;
  }


Pattern
  = n:Node r:Relationship* { return n; }

Node
  = "(" nodeid:Identifier labels:Label* properties:JSobject? ")" { return { id:nodeid, labels:labels, properties:properties }; }


Relationship
  = backward:"<"? "-" relData:RelationshipData "-" forward:">"? path:Path { 
    var direction = "forward";
    if (backward) {
      if (forward) {
        direction = "both";
      } else {
        direction = "backward";
      }
    }
    relData.direction = direction;
    return [relData, path]; 
  }

RelationshipData
  = "[" nodeid:Identifier? type:Label properties:JSobject? "]" { return { id:nodeid, type:type, properties:properties }; }

Label
  = ":" id:Identifier { return id; }

Identifier
  = [a-zA-Z0-9]+ { return text(); }


/* ===== Cypher Variation of JSON ===== */

/* ----- 2. JSON Grammar ----- */

JSON_text
  = _ value:JSvalue _ { return value; }

begin_array     = _ "[" _
begin_JSobject    = _ "{" _
end_array       = _ "]" _
end_JSobject      = _ "}" _
name_separator  = _ ":" _
value_separator = _ "," _

/* ----- 3. Values ----- */

JSvalue
  = false
  / null
  / true
//  / JSobject
  / array
  / number
  / JSstring

false = "false" { return false; }
null  = "null"  { return null;  }
true  = "true"  { return true;  }

/* ----- 4. JSobjects ----- */

JSobject
  = begin_JSobject
    JSmembers:(
      first:JSmember
      rest:(value_separator m:JSmember { return m; })*
      {
        var result = {}, i;

        result[first.name] = first.value;

        for (i = 0; i < rest.length; i++) {
          result[rest[i].name] = rest[i].value;
        }

        return result;
      }
    )?
    end_JSobject
    { return JSmembers !== null ? JSmembers: {}; }

JSmember
  = name:(JSstring / Identifier ) name_separator value:JSvalue {
      return { name: name, value: value };
    }

/* ----- 5. Arrays ----- */

array
  = begin_array
    values:(
      first:JSvalue
      rest:(value_separator v:JSvalue { return v; })*
      { return [first].concat(rest); }
    )?
    end_array
    { return values !== null ? values : []; }

/* ----- 6. Numbers ----- */

number "number"
  = minus? int frac? exp? { return parseFloat(text()); }

decimal_point = "."
digit1_9      = [1-9]
e             = [eE]
exp           = e (minus / plus)? DIGIT+
frac          = decimal_point DIGIT+
int           = zero / (digit1_9 DIGIT*)
minus         = "-"
plus          = "+"
zero          = "0"

/* ----- 7. Strings ----- */

JSstring "string"
  = quotation_mark chars:char* quotation_mark { return chars.join(""); }

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape         = "\\"
quotation_mark = '"'
unescaped      = [\x20-\x21\x23-\x5B\x5D-\u10FFFF]

/* ----- Core ABNF Rules ----- */

/* See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4627). */
DIGIT  = [0-9]
HEXDIG = [0-9a-f]i


/* ===== Whitespace ===== */

_ "whitespace"
  = whitespace*

// Whitespace is undefined in the original JSON grammar, so I assume a simple
// conventional definition consistent with ECMA-262, 5th ed.
whitespace
  = [ \t\n\r]
