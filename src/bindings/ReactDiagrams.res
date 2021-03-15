type engine
type node
type port
type link
type model
type layoutEngine

@module("@projectstorm/react-diagrams")
external createEngine: unit => engine = "default"

module Engine = {
  type factoryBank
  type actionEventBus
  module LinkFactory = {
    type t

    @send external registerFactory: (factoryBank, t) => unit = "registerFactory"
  }

  module Dagre = {
    type dagreGraphOptions = {
      rankdir: string,
      ranker: string,
      marginx: float,
      marginy: float,
      ranksep: float,
      edgesep: float,
      nodesep: float,
    }

    type options = {
      includeLinks: bool,
      graph: dagreGraphOptions,
    }

    @module("@projectstorm/react-diagrams") @new
    external createEngine: options => layoutEngine = "DagreEngine"

    @send external redistribute: (layoutEngine, model) => unit = "redistribute"
    @send external getModel: engine => model = "getModel"
    @send external getSelectedEntities: model => Js.t<'a> = "getSelectedEntities"
  }

  module ActionEventBus = {
    type action

    @module("./ReactDiagramsBridge.js") @new
    external customClickAction: {"onClick": ref<(ReactEvent.Mouse.t, engine) => unit>} => action =
      "CustomClickAction"

    @send external registerAction: (actionEventBus, action) => unit = "registerAction"
  }

  @send external setModel: (engine, model) => unit = "setModel"
  @send external getLinkFactories: engine => factoryBank = "getLinkFactories"
  @send external getActionEventBus: engine => actionEventBus = "getActionEventBus"
  @send external repaintCanvas: engine => unit = "repaintCanvas"
}

module DefaultLinkModel = {
  type options = {
    name: string,
    color: string,
  }

  @module("@projectstorm/react-diagrams") @new
  external make: options => node = "DefaultLinkModel"
}

module RightAngleLinkModel = {
  type options = {
    name: string,
    color: string,
  }

  @module("@projectstorm/react-diagrams") @new
  external make: options => port = "RightAngleLinkModel"
}

module Port = {
  type options

  @get external getOptions: port => options = "options"

  @set external setClassName: (options, string) => unit = "className"
}
@module("@projectstorm/react-diagrams") @new
external rightAngleLinkFactory: unit => Engine.LinkFactory.t = "RightAngleLinkFactory"

@module("./ReactDiagramsBridge.js") @new
external rightAnglePortModel: (bool, string, string) => port = "RightAnglePortModel"

module DefaultNodeModel = {
  type options = {
    name: string,
    color: string,
  }

  @module("@projectstorm/react-diagrams") @new
  external make: options => node = "DefaultNodeModel"
}

@send external addOutPort: (node, string) => port = "addOutPort"
@send external addPort: (node, port) => port = "addPort"
@send external addInPort: (node, string) => port = "addInPort"
@send external setPosition: (node, float, float) => unit = "setPosition"
@send external link: (port, port) => link = "link"

module Link = {
  type alignment = [#TOP | #BOTTOM | #LEFT | #RIGHT]

  type options = {
    alignment: alignment,
    width: int,
    color: string,
    selectedColor: string,
  }

  @send external getOptions: port => options = "getOptions"

  @set external setAlignment: (options, alignment) => unit = "alignment"
  @set external setWidth: (options, int) => unit = "width"
  @set external setColor: (options, string) => unit = "color"
  @set external setSelectedColor: (options, string) => unit = "selectedColor"

  @send external addLabel: (link, string) => unit = "addLabel"
}

module Canvas = {
  @module("@projectstorm/react-canvas-core") @react.component
  external make: (
    ~engine: engine,
    ~className: string=?,
    ~style: ReactDOMStyle.t=?,
  ) => React.element = "CanvasWidget"
}

module DiagramModel = {
  type options = unit

  @module("@projectstorm/react-diagrams") @new
  external make: options => model = "DiagramModel"

  @send @variadic external addAll: (model, array<'diagramThing>) => unit = "addAll"
}

type t = {
  engine: engine,
  model: model,
  layoutEngine: layoutEngine,
}

module InputType = {
  type t
}

@module("@projectstorm/react-canvas-core") external inputType: InputType.t = "InputType"
