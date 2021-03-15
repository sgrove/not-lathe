import createEngine, {
  DiagramModel,
  DefaultNodeModel,
  DefaultPortModel,
  RightAngleLinkFactory,
  LinkModel,
  RightAngleLinkModel,
} from "@projectstorm/react-diagrams";
import {
  Action,
  ActionEvent,
  InputType,
} from "@projectstorm/react-canvas-core";

// When new link is created by clicking on port the RightAngleLinkModel needs to be returned.
export class RightAnglePortModel extends DefaultPortModel {
  createLinkModel(factory) {
    return new RightAngleLinkModel();
  }
}

export class CustomClickAction extends Action {
  constructor(options = {}) {
    options = {
      keyCodes: [46, 8],
      ...options,
    };
    super({
      type: InputType.MOUSE_UP,
      fire: ({ event }) => {
        console.log("Got a mouse down: ", options.onClick);

        options.onClick &&
          options.onClick.contents &&
          options.onClick.contents(event, this.engine);
        // if (options.keyCodes.indexOf(event.event.keyCode) !== -1) {
        //   const selectedEntities = this.engine.getModel().getSelectedEntities();
        //   if (selectedEntities.length > 0) {
        //     const confirm = window.confirm("Are you sure you want to delete?");

        //     if (confirm) {
        //       _.forEach(selectedEntities, (model) => {
        //         // only delete items which are not locked
        //         if (!model.isLocked()) {
        //           model.remove();
        //         }
        //       });
        //       this.engine.repaintCanvas();
        //     }
        //   }
        // }
      },
    });
  }
}
