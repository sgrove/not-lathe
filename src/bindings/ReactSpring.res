type springConfig = {
  @optional @ocaml.document(`spring mass`) mass: int,
  @optional @ocaml.document(`spring energetic load`) tension: int,
  @optional @ocaml.document(`spring resistence`) friction: int,
  @optional @ocaml.document(`when true, stops the spring once it overshoots its boundaries`)
  clamp: bool,
  @optional @ocaml.document(`precision`) precision: float,
  @optional @ocaml.document(`initial velocity`) velocity: int,
  @optional
  @ocaml.document(`if > than 0 will switch to a duration-based animation instead of spring physics, value should be indicated in milliseconds (e.g. duration: 250 for a duration of 250ms)`)
  duration: int,
}

type defaultConfigs = {
  default: springConfig,
  gentle: springConfig,
  wobbly: springConfig,
  stiff: springConfig,
  slow: springConfig,
  molasses: springConfig,
}

@module("react-spring") external config: defaultConfigs = "config"

@deriving(abstract)
type transition<'item, 'props> = {
  item: 'item,
  props: 'props,
  @optional
  key: int,
}

@deriving(abstract)
type lifeCycle<
  'initial,
  'from,
  'enter,
  'update,
  'leave,
  'trail,
  'unique,
  'reset,
  'onDestroyed,
  'ref,
> = {
  @optional @ocaml.document(`Initial (first time) base values, optional (can be null)`)
  initial: 'initial,
  @optional @ocaml.document(`Base values, optional`) from: 'from,
  @optional @ocaml.document(`Styles apply for entering elements`) enter: 'enter,
  @optional
  @ocaml.document(`Styles apply for updating elements (you can update the hook itself with new values)`)
  update: 'update,
  @optional @ocaml.document(`Styles apply for leaving elements`) leave: 'leave,
  @optional
  @ocaml.document(`Delay in ms before the animation starts, adds up for each enter/update and leave`)
  trail: 'trail,
  @optional
  @ocaml.document(`If this is true, items going in and out with the same key will be re-used`)
  unique: 'unique,
  @optional
  @ocaml.document(`Used in combination with "unique" and makes entering items start from scratch`)
  reset: 'reset,
  @optional @ocaml.document(`Called when objects have disappeared for good`)
  onDestroyed: 'onDestroyed,
  @optional ref: React.ref<'ref>,
  @optional config: springConfig,
}

@module("react-spring")
external useTransition: (
  'value,
  option<array<'item>>,
  lifeCycle<'initial, 'from, 'enter, 'update, 'leave, 'trail, 'unique, 'reset, 'onDestroyed, 'ref>,
) => array<transition<'value, 'props>> = "useTransition"

@module("react-spring") external useChain: array<React.ref<'t>> => unit = "useChain"

module Animated = {
  @module("react-spring") @scope("animated") @react.component
  external make: (~style: ReactDOMStyle.t, ~key: 'key, ~children: React.element) => React.element =
    "div"
}
