import { Handle } from "react-flow-renderer";

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
  red: "#EB5757",
  orange: "#F2994A",
  yellow: "#F2C94C",
  "green-1": "#219653",
  "green-2": "#27AE60",
  "green-3": "#6FCF97",
  "green-4": "#1BBE83",
  "blue-1": "#2F80ED",
  "blue-2": "#2D9CDB",
  "blue-3": "#56CCF2",
  "purple-1": "#9B51E0",
  "purple-2": "#BB6BD9",
};

const customNodeStyles = {
  // background: colors["gray-9"],
  // color: "#FFF",
  // padding: 1,
  // borderRadius: "6px",
  // border: "1px solid white",
};

const CustomNodeComponent = ({ data }) => {
  return (
    <div
      className={"node-label"}
      // style={customNodeStyles}
    >
      <div>{data.label}</div>
    </div>
  );
};

export default CustomNodeComponent;
