type v4

@module("uuid") external v4: unit => v4 = "v4"

@module("uuid") external validate: string => bool = "validate"

let parseExn = (s: string): v4 => {
  switch validate(s) {
  | false => raise(Failure("ParseExn"))
  | true => s->Obj.magic
  }
}

@send external toString: v4 => string = "toString"
