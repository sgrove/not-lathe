@val external \"import": string => 'a = "import"

@module("react")
external lazy_: (unit => Js.Promise.t<'a>) => 'a = "lazy"
