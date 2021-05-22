type state = {mousePosition: (int, int)}

@send external getBoundingClientRect: Dom.element => Dom.domRect = "getBoundingClientRect"

@react.component
let make = (~source, ~onDragEnd, ~invert) => {
  open React

  let (state, setState) = useState(() => {
    let rect = Obj.magic(getBoundingClientRect(source))

    {
      mousePosition: (rect["x"] + rect["width"] / 2, rect["y"] + rect["height"] / 2),
    }
  })

  let onMouseMove = event => {
    let x = event["pageX"]
    let y = event["pageY"]
    setState(_oldState => {mousePosition: (x, y)})
  }

  let onMouseUp = event => {
    Debug.assignToWindowForDeveloperDebug(~name="mouseupevent", event)
    onDragEnd()
  }

  useEffect0(() => {
    %external(window)->Belt.Option.forEach(window => {
      window["document"]["addEventListener"]("mousemove", onMouseMove)
      window["document"]["addEventListener"]("mouseup", onMouseUp)
    })

    let cleanup = %external(window)->Belt.Option.map(window => {
      () => {
        window["document"]["removeEventListener"]("mousemove", onMouseMove)
        window["document"]["removeEventListener"]("mouseup", onMouseUp)
      }
    })

    cleanup
  })
  let (mouseX, mouseY) = state.mousePosition
  let (anchorX, anchorY) = {
    let rect = Obj.magic(getBoundingClientRect(source))

    let scrollY = Utils.Window.scrollY()->Belt.Option.getWithDefault(0)

    (rect["x"] + rect["width"] / 2, rect["y"] + rect["height"] / 2 + scrollY)
  }
  let nudge = 2

  let (startX, startY, endX, endY) = switch invert {
  | false => (anchorX, anchorY, mouseX - nudge, mouseY - nudge)
  | true => (mouseX - nudge, mouseY - nudge, anchorX, anchorY)
  }

  <div
    className="absolute w-full h-full pointer-events-none"
    style={ReactDOMStyle.make(~top="0px", ~left="0px", ~zIndex="9999", ~cursor="none", ())}
    onMouseMove={event => {
      let x = event->ReactEvent.Mouse.clientX
      let y = event->ReactEvent.Mouse.clientY
      setState(_oldState => {mousePosition: (x, y)})
    }}>
    <svg
      className="relative w-full h-full pointer-events-none"
      xmlns="http://www.w3.org/2000/svg"
      style={ReactDOMStyle.make(~top="0px", ~left="0px", ~zIndex="9999", ~cursor="none", ())}>
      <filter id="blurMe"> <feGaussianBlur in_="SourceGraphic" stdDeviation="5" /> </filter>
      <marker id="connectMarker" markerHeight="4" markerWidth="2" orient="auto" refX="0.1" refY="2">
        <path fill="green" d="M0 0v4l2-2z" />
      </marker>
      <line
        className="pointer-events-none"
        style={ReactDOMStyle.make(~cursor="none", ())}
        stroke={Comps.colors["green-6"]}
        strokeWidth="3"
        markerEnd="url(#connectMarker)"
        x1={startX->string_of_int}
        y1={startY->string_of_int}
        x2={endX->string_of_int}
        y2={endY->string_of_int}
      />
      <line
        style={ReactDOMStyle.make(~cursor="none", ())}
        stroke={Comps.colors["green-3"]}
        strokeWidth="3"
        className="moving-path pointer-events-none"
        markerEnd="url(#connectMarker)"
        // filter="url(#blurMe)"
        strokeDasharray={"50"}
        x1={startX->string_of_int}
        y1={startY->string_of_int}
        x2={endX->string_of_int}
        y2={endY->string_of_int}
      />
    </svg>
  </div>
}
