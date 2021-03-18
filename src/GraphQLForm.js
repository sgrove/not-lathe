import * as GraphQL from "graphql";
import * as React from "react";

const {
  isListType,
  isEnumType,
  getNamedType,
  isInputObjectType,
  isScalarType,
  typeFromAST,
  parse,
  parseType,
  GraphQLObjectType,
  visit,
  print,
  printSchema,
  isWrappingType,
  visitWithTypeInfo,
  TypeInfo,
} = GraphQL;

let labelClassname = "m-0";

export const updateFormVariables = (setFormVariables, path, coerce) => {
  const setIn = (object, path, value) => {
    if (path.length === 1) {
      if (value === null) {
        delete object[path[0]];
      } else {
        object[path[0]] = value;
      }
    } else {
      if ([undefined, null].indexOf(object[path[0]]) > -1) {
        object[path[0]] = typeof path[1] === "number" ? [] : {};
      }
      setIn(object[path[0]], path.slice(1), value);
    }
    return object;
  };

  const formInputHandler = (event) => {
    // We parse the form input, coerce it to the correct type, and then update the form variables
    const rawValue = event.target.value;
    // We take a blank input to mean \`null\`
    const value = rawValue === "" ? null : rawValue;
    setFormVariables((oldFormVariables) => {
      const newValue = setIn(oldFormVariables, path, coerce(value));
      return { ...newValue };
    });
  };

  return formInputHandler;
};

export const formInput = (schema, def, setFormVariables, options) => {
  const name = def.variable.name.value;

  function helper(path, type, subfield) {
    const isList = isListType(type);

    const namedType = getNamedType(type);
    const isEnum = isEnumType(namedType);
    const isObject =
      isInputObjectType(namedType) || GraphQL.isObjectType(namedType);
    const isScalar = isScalarType(namedType);

    const subfieldName = subfield && subfield.name;
    let subDataEl;

    if (isList) {
      return helper([...path, 0], namedType);
    } else if (isObject) {
      // $FlowFixMe: we check this with `isObject` already
      const subFields = namedType.getFields();

      if (!subFields) {
        return "MISSING_SUBFIELDS";
      }

      const subFieldEls = Object.keys(subFields).map((fieldName) => {
        const currentField = subFields[fieldName];

        const subPath = [...path, fieldName];
        const currentFieldInput = helper(
          subPath,
          currentField.type,
          currentField
        );

        return (
          <div key={fieldName}>
            <label
              key={fieldName}
              className={options?.labelClassname ?? labelClassname}
              htmlFor={subPath.join("-")}
            >
              .{fieldName}
            </label>
            {currentFieldInput}
          </div>
        );
      });

      return (
        <div>
          <fieldset className="ml-2 mt-0 mb-0 border-l border-gray-500">
            {subFieldEls}
          </fieldset>
        </div>
      );
    } else if (isScalar) {
      let coerceFn;
      let inputAttrs;

      // $FlowFixMe: we check this with `isScalar` already
      switch (namedType.name) {
        case "String":
          coerceFn = (value) => value;
          inputAttrs = [
            ["type", "text"],
            ["className", options?.inputClassName],
          ];
          break;
        case "Float":
          coerceFn = (value) => {
            try {
              return parseFloat(value);
            } catch (e) {
              return 0.0;
            }
          };
          inputAttrs = [
            ["type", "number"],
            ["step", "0.1"],
          ];
          break;
        case "Int":
          coerceFn = (value) => {
            try {
              return parseInt(value, 10);
            } catch (e) {
              return 0;
            }
          };
          inputAttrs = [
            ["type", "number"],
            ["className", options?.inputClassName],
          ];
          break;
        case "Boolean":
          coerceFn = (value) => value === "true";
          inputAttrs = [
            ["type", "checkbox"],
            [
              "className",
              options?.checkboxClassName ||
                "toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer",
            ],
          ];
          break;
        case "JSON":
          coerceFn = (value) => {
            try {
              return JSON.parse(value);
            } catch (e) {
              return null;
            }
          };
          inputAttrs = [
            ["type", "text"],
            ["className", options?.inputClassName],
          ];
          break;

        default:
          coerceFn = (value) => value;
          inputAttrs = [
            ["type", "text"],
            ["className", options?.inputClassName],
          ];
          break;
      }

      const updateFunction = updateFormVariables(
        setFormVariables,
        path,
        coerceFn
      );

      let finalInputAttrs = Object.fromEntries(
        inputAttrs
          .map(([key, value]) => (!!value ? [key, value] : null))
          .filter(Boolean)
      );

      subDataEl = (
        <div
          key={path.join("-")}
          className="relative text-lg bg-transparent text-gray-800"
        >
          <div className="flex items-center ml-2 mr-2 border-b border-gray-500">
            <input
              id={path.join("-")}
              onChange={updateFunction}
              {...finalInputAttrs}
              className="bg-transparent border-none px-2 leading-tight focus:outline-none text-white"
              type="text"
              placeholder={namedType.name}
            />
          </div>
        </div>
      );
    } else if (isEnum) {
      const updateFunction = updateFormVariables(
        setFormVariables,
        path,
        (value) => value
      );
      const selectOptions = namedType
        // $FlowFixMe: we check this with `isEnum` already
        .getValues()
        .map((gqlEnum) => {
          const enumValue = gqlEnum.value;
          const enumDescription = !!gqlEnum.description
            ? `: ${gqlEnum.description}`
            : "";
          return (
            <option key={enumValue} value={enumValue}>
              {gqlEnum.name}
              {enumDescription}
            </option>
          );
        });

      subDataEl = (
        <select
          className="ml-2 mr-2 m-0 pt-0 pb-0 pl-4 pr-8 w-full rounded-sm"
          id={path.join("-")}
          onChange={updateFunction}
          key={path.join("-")}
        >
          {selectOptions}
        </select>
      );
    } else {
      window.unknownDef = def;
      return "UNKNOWN_GRAPHQL_TYPE_FOR_INPUT";
    }

    return subDataEl;
  }

  const hydratedType = typeFromAST(schema, def.type);
  if (!hydratedType) {
    console.warn("\tCould not hydrate type for ", def.type);
    return null;
  }
  // const required = isNonNullType(hydratedType);

  const formEl = helper([name], hydratedType);

  return (
    <div key={def.variable.name.value}>
      <label className={options?.labelClassname ?? labelClassname}>
        ${def.variable.name.value}
      </label>
      {formEl}
    </div>
  );
};
