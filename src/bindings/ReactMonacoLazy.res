type editor

@bs.send external layout: editor => unit = "layout"

type selection = {
  startLineNumber: int,
  startColumn: int,
  endLineNumber: int,
  endColumn: int,
}

@bs.send external setSelection: (editor, selection) => unit = "setSelection"

@bs.send external revealLine: (editor, int) => unit = "revealLine"

@bs.send external focus: editor => unit = "focus"

module Editor = {
  module type T = module type of BsReactMonaco.Editor
  /*
    Needed for BuckleScript to not import the original component:
    See https://github.com/BuckleScript/bucklescript/issues/3543
 */
  @val external component: module(T) = "undefined"

  /* Module annotation needed to make sure `make` has the same type as
   the original component */
  module Lazy: T = {
    /* Includes `makeProps` at the type level without adding `import` of the original component */
    include unpack(component)
    /* 100% unsafe due to `import` typedef :) but will be unified by the explicit type annotation above */
    let make = {
      open LazyImport
      lazy_(() => \"import"("react-monaco-editor"))
    }
    /* All bindings in the original component have to be added here (`makeProps`
       is external, so no need). Shadowing them here removes invalid access to
       undefined[1], undefined[n] in the resulting output */
    /* let default = make; */
  }
}

// module DiffViewer = {
//   module type T = module type of BsReactMonaco.DiffViewer
//   /*
//     Needed for BuckleScript to not import the original component:
//     See https://github.com/BuckleScript/bucklescript/issues/3543
//  */
//   @val external component: module(T) = "undefined"

//   /* Module annotation needed to make sure `make` has the same type as
//    the original component */
//   module Lazy: T = {
//     /* Includes `makeProps` at the type level without adding `import` of the original component */
//     include unpack(component)
//     /* 100% unsafe due to `import` typedef :) but will be unified by the explicit type annotation above */
//     let make = {
//       open LazyImport
//       lazy_(() => \"import"("react-monaco-editor"))
//     }
//     /* All bindings in the original component have to be added here (`makeProps`
//        is external, so no need). Shadowing them here removes invalid access to
//        undefined[1], undefined[n] in the resulting output */
//     /* let default = make; */
//   }
// }
