import { Handle } from "react-flow-renderer";

const customNodeStyles = {
  background: "#9CA8B3",
  color: "#FFF",
  padding: 10,
};

const CustomNodeComponent = ({ data }) => {
  return (
    <div style={customNodeStyles}>
      <div>{data.label}</div>
    </div>
  );
};

export default CustomNodeComponent;
