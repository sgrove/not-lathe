module Component = {
  @module("react-basic-error-boundary") @react.component
  external make: (
    ~children: React.element,
    ~fallback: Js.Nullable.t<Js.Exn.t> => React.element,
    ~onError: Js.Nullable.t<Js.Exn.t> => unit,
  ) => React.element = "default"
}

@react.component
let make = (~fallback, ~onError, ~children) =>
  <Component
    fallback={maybeError => fallback(maybeError->Js.Nullable.toOption)}
    onError={maybeError => onError(maybeError->Js.Nullable.toOption)}>
    children
  </Component>
