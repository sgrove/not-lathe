module Header = {
  @react.component
  let make = (~onClick=?, ~children) => {
    <div ?onClick className="border-l-4 border-blue-500 pl-2 mt-2 ml-2 text-gray-400">
      {children}
    </div>
  }
}
