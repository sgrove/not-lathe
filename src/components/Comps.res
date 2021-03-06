//       className="border-l-4 border-blue-500 pl-2 mt-2 ml-2 text-gray-400"

let colors = {
  "gray-1": "#333333",
  "gray-2": "#4F4F4F",
  "gray-3": "#828282",
  "gray-4": "#BDBDBD",
  "gray-5": "#E0E0E0",
  "gray-6": "#F2F2F2",
  "gray-7": "#282B30",
  "gray-8": "#17191C",
  "gray-9": "#1D1F22",
  "gray-10": "#26292D",
  "gray-11": "#DFDFDF",
  "gray-12": "#171717",
  "gray-13": "#34373C",
  "gray-14": "#1b1d1f",
  "gray-15": "#282C31",
  "gray-16": "#2E3237",
  "gray-17": "#3B434B",
  "red": "#EB5757",
  "orange": "#F2994A",
  "yellow": "#F2C94C",
  "green-1": "#219653",
  "green-2": "#27AE60",
  "green-3": "#6FCF97",
  "green-4": "#1BBE83",
  "green-5": "#2FD0BD",
  "green-6": "#47FFC8",
  "green-7": "#17423D",
  "blue-1": "#2F80ED",
  "blue-2": "#2D9CDB",
  "blue-3": "#56CCF2",
  "brown-1": "#8B4D14",
  "purple-1": "#9B51E0",
  "purple-2": "#BB6BD9",
}

module Header = {
  let defaultStyle = {ReactDOMStyle.make(~color=colors["gray-6"], ())}

  @react.component
  let make = (~onClick=?, ~style=ReactDOMStyle.make(), ~children) => {
    <div ?onClick className="font-bold mx-2 p-2" style={ReactDOMStyle.combine(defaultStyle, style)}>
      {children}
    </div>
  }
}

module Button = {
  let defaultStyle = ReactDOMStyle.make()

  @react.component
  let make = (
    ~onClick=?,
    ~style=ReactDOMStyle.make(),
    ~className="",
    ~type_="button",
    ~children,
    ~disabled=?,
  ) => {
    <button
      type_
      ?onClick
      ?disabled
      style={ReactDOMStyle.combine(defaultStyle, style)}
      className={className ++ " og-primary-button active:outline-none focus:outline-none text-white text-sm py-2.5 px-5 rounded-md m-2"}>
      {children}
    </button>
  }
}

module Pre = {
  let defaultStyle = ReactDOMStyle.make(~backgroundColor=colors["gray-8"], ~maxHeight="150px", ())

  @react.component
  let make = (~children, ~className="", ~style=defaultStyle, ~selectAll=false) => {
    <pre
      className={className ++
      " my-2 mx-4 p-2 rounded-sm text-gray-200 overflow-scroll " ++ (selectAll ? "select-all" : "")}
      style={style}>
      {children}
    </pre>
  }
}

module Select = {
  let defaultStyle = ReactDOMStyle.make()

  @react.component
  let make = (
    ~children,
    ~disabled=?,
    ~className="comp-select",
    ~onChange=?,
    ~style=ReactDOMStyle.make(),
    ~value=?,
  ) => {
    <select ?value ?disabled ?onChange className style={ReactDOMStyle.combine(defaultStyle, style)}>
      {children}
    </select>
  }
}

let activeTabStyle = ReactDOMStyle.make(
  ~borderBottomWidth="3px",
  ~borderBottomColor=colors["blue-1"],
  (),
)

let inactiveTabStyle = ReactDOMStyle.make()

module Modal = {
  @react.component
  let make = (~children) => {
    <div
      style={ReactDOMStyle.make(~zIndex="9999", ())}
      className="flex items-center justify-center absolute left-0 bottom-0 w-full h-full bg-gray-800 bg-opacity-60">
      <div
        className="rounded-lg w-4/5 h-4/5"
        style={ReactDOMStyle.make(~backgroundColor=colors["gray-8"], ())}>
        <div className="flex flex-col p-1 h-full">
          <div className="flex h-full"> {children} </div>
        </div>
      </div>
    </div>
  }
}
