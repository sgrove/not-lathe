@module("react-json-view") @react.component
external make: (
  // This property contains your input JSON
  ~src: 'a,
  // Contains the name of your root node. Use null or false for no name.
  ~name: string=?,
  // RJV supports base-16 themes. Check out the list of supported themes in the demo. A custom "rjv-default" theme applies by default.
  ~theme: string=?,
  // Style attributes for react-json-view container. Explicit style attributes will override attributes provided by a theme.
  ~style: ReactDOMStyle.t=?,
  // Style of expand/collapse icons. Accepted values are "circle", triangle" or "square".
  ~iconStyle: string=?,
  // Set the indent-width for nested objects
  ~indentWidth: int=?,
  // When set to true, all nodes will be collapsed by default. Use an int value to collapse at a particular depth.
  ~collapsed: bool=?,
  // When an int value is assigned, strings will be cut off at that length. Collapsed strings are followed by an ellipsis. String content can be expanded and collapsed by clicking on the string value.
  ~collapseStringsAfterLength: int=?,
  // Callback function to provide control over what objects and arrays should be collapsed by default. An object is passed to the callback containing name, src, type ("array" or "object") and namespace.
  ~shouldCollapse: 'field => unit=?,
  // When an int value is assigned, arrays will be displayed in groups by count of the value. Groups are displayed with bracket notation and can be expanded and collapsed by clicking on the brackets.
  ~groupArraysAfterLength: int=?,
  // When prop is not false, the user can copy objects and arrays to clipboard by clicking on the clipboard icon. Copy callbacks are supported.
  ~enableClipboard: string => unit=?,
  // When set to true, objects and arrays are labeled with size
  ~displayObjectSize: bool=?,
  // When set to true, data type labels prefix values
  ~displayDataTypes: bool=?,
  // When a callback function is passed in, edit functionality is enabled. The callback is invoked before edits are completed. Returning false from onEdit will prevent the change from being made. see: onEdit docs
  //   ~onEdit: edit => unit=?,
  // When a callback function is passed in, add functionality is enabled. The callback is invoked before additions are completed. Returning false from onAdd will prevent the change from being made. see: onAdd docs
  //   ~onAdd: add => unit=?,
  // Sets the default value to be used when adding an item to json
  // ~defaultValue: string |number |bool |array |object=?,
  // When a callback function is passed in, delete functionality is enabled. The callback is invoked before deletions are completed. Returning false from onDelete will prevent the change from being made. see: onDelete docs
  //   ~onDelete: delete => unit=?,
  // When a function is passed in, clicking a value triggers the onSelect method to be called.
  //   ~onSelect: select => unit=?,
  // set to true to sort object keys
  ~sortKeys: bool=?,
  // set to false to remove quotes from keys (eg. "name": vs. name:)
  ~quotesOnKeys: bool=?,
  // Custom message for validation failures to onEdit, onAdd, or onDelete callbacks
  ~validationMessage: string=?,
  // When set to true, the index of the elements prefix values
  ~displayArrayKey: bool=?,
) => React.element = "default"
