/* ===== Whitespace ===== */
/* Parseable examples

Nodes:
(a)                          // a simple named node 
(b {"name":"Bob"})           // a node with one property 
(cat:Animal)                 // a node with one label and no properties 
(dog:Animal {"name":"dog"})  // a node with both label and property 
(dinner:Spam:Egg:Chips {"foo":"bar","answer":42})  // several of each 

*/

{
  var graph = { nodes:{}, relationships:{} }

  function makeNode(name, labels, properties) {
    var newNode = {};
    if (name) newNode.name = name.join("");
    if (labels && labels.length > 0) newNode.labels = labels;
    if (properties) newNode.properties = properties;
    return newNode;
  }

  function makeRelationship(incoming, outgoing, data) {
    var newRelationship = {};
    if (incoming) newRelationship.direction = "incoming"
    else if (outgoing) newRelationship.direction = "outgoing";
    if (data) {
      if (data.properties) newRelationship.properties = data.properties;
      if (data.type) newRelationship.type = data.type;
    }
    return newRelationship;
  }

  function flatten(array) {
    var result = [], self = arguments.callee;
    array.forEach(function(item) {
      Array.prototype.push.apply(
        result,
        Array.isArray(item) ? self(item) : [item]
      );
    });
    return result;
  }

}

/* ===== Nodes ===== */

Node
  = "(" nodeid:Identifier properties:JSobject? ")" { return nodeid; }

Identifier
  = [a-zA-Z0-9]+ { return text(); }

/* ===== JSON ===== */

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
