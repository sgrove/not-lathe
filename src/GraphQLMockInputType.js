import {
  parse,
  parseType,
  print,
  isWrappingType,
  visit,
  visitWithTypeInfo,
  TypeInfo,
  isListType,
  isNonNullType,
  isObjectType,
  isInputObjectType,
  getNamedType,
  isEnumType,
  isScalarType,
  isUnionType,
  isInterfaceType,
  typeFromAST,
} from "graphql";

import React from "react";

export function mockInputType(schema, schemaType) {
  let scalarGenerators = {
    String: () => "Hello",
    ID: () => "some_id",
    Int: () => 42,
    Float: () => 3.14159,
    Boolean: () => true,
    JSON: () => ({ json: true }),
  };

  if (isInputObjectType(schemaType)) {
    let fields = Object.values(schemaType.getFields());
    let fieldValuePairs = Object.values(fields).map((field) => {
      let baseType = getNamedType(field.type);
      let fakedValue = mockInputType(schema, baseType);
      return [field.name, fakedValue === undefined ? null : fakedValue];
    });

    return Object.fromEntries(fieldValuePairs);
  } else if (isScalarType(schemaType)) {
    let generator = scalarGenerators[schemaType.name];

    return generator ? generator() : null;
  } else if (isEnumType(schemaType)) {
    let value = schemaType.getValues()[0].value;
    return value;
  }
}

export function mockOperationVariables(schema, operationDefinition) {
  let variables = (operationDefinition.variableDefinitions || []).map(
    (varDef) => {
      let name = varDef.variable.name.value;
      let printedType = print(varDef.type).replace(/[!\[\]]*/g, "");
      let parsedType = parseType(printedType);
      let schemaType = mockedSchema.getType(parsedType.name.value);
      let value = mockInputType(schema, schemaType);
      return [name, value];
    }
  );

  return Object.fromEntries(variables);
}

export function mockOperationDocVariables(schema, operationDoc) {
  let operationVariables = (operationDoc.definitions || [])
    .filter((def) => def.kind === "OperationDefinition")
    .map((operationDefinition) => {
      let variables = mockOperationVariables(schema, operationDefinition);

      return [operationDefinition.name?.value || "Untitled", variables];
    });

  return Object.fromEntries(operationVariables);
}

export function typeScriptForOperationHelper(schema, schemaType) {
  let scalarGenerators = {
    String: () => "Hello",
    ID: () => "some_id",
    Int: () => 42,
    Float: () => 3.14159,
    Boolean: () => true,
    JSON: () => ({ json: true }),
  };

  if (isInputObjectType(schemaType)) {
    let fields = Object.values(schemaType.getFields());
    let fieldValuePairs = Object.values(fields).map((field) => {
      let baseType = getNamedType(field.type);
      let fakedValue = mockInputType(schema, baseType);
      return [field.name, fakedValue === undefined ? null : fakedValue];
    });

    return Object.fromEntries(fieldValuePairs);
  } else if (isScalarType(schemaType)) {
    let generator = scalarGenerators[schemaType.name];

    return generator ? generator() : null;
  } else if (isEnumType(schemaType)) {
    let value = schemaType.getValues()[0].value;
    return value;
  }
}

export function listCount(gqlType) {
  let inspectedType = gqlType;

  let listCount = 0;

  let totalCount = 0;
  while (isWrappingType(inspectedType)) {
    if (isListType(inspectedType)) {
      listCount = listCount + 1;
    }

    totalCount = totalCount + 1;

    if (totalCount > 30) {
      return -99;
    }

    inspectedType = inspectedType.ofType;
  }

  return listCount;
}

let basicToTypeScript = (type, nesting) => {
  let base = type;
  let i = nesting;
  while (i > 0) {
    i = i - 1;
    base = [base];
  }

  return base;
};

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

export const namedPathOfAncestors = (ancestors) =>
  (ancestors || []).reduce((acc, next) => {
    if (Array.isArray(next)) {
      return acc;
    }
    switch (next.kind) {
      case "Field":
        return [...acc, next.name.value];
      case "InlineFragment":
        return [...acc, `$inlineFragment.${next.typeCondition.name.value}`];
      case "Argument":
        return [...acc, `$arg.${next.name.value}`];
      default:
        return acc;
    }
  }, []);

export function typeScriptDefinitionObjectForOperation(
  schema,
  operationDefinition
) {
  let values = [];
  let typeInfo = new TypeInfo(schema);

  let scalarMap = {
    String: "string",
    ID: "string",
    Int: "number",
    Float: "number",
    Boolean: "boolean",
  };

  var typeMap = {};

  visit(
    operationDefinition,
    visitWithTypeInfo(typeInfo, {
      Field: {
        leave: (node, key, parent, path, ancestors) => {
          let name = node.alias || node.name.value;
          let namedPath = [...namedPathOfAncestors(ancestors), name];
          let gqlType = typeInfo.getType();
          let namedType = getNamedType(gqlType);
          let nestingLevel = listCount(gqlType);

          let isObject = isObjectType(namedType);

          if (isObject) return;

          let basicType = scalarMap[namedType.name] || "any";

          let tsType = basicToTypeScript(basicType, nestingLevel);

          setIn(typeMap, namedPath, tsType);
        },
      },
    })
  );

  return { data: typeMap, errors: ["any"] };
}
export function typeScriptForOperation(schema, operationDefinition) {
  let typeMap = typeScriptDefinitionObjectForOperation(
    schema,
    operationDefinition
  );

  let valueHelper = (value) => {
    if (typeof value === "string") {
      return value;
    } else if (Array.isArray(value)) {
      let subType = valueHelper(value[0]);
      return `Array<${subType}>`;
    } else if (typeof value === "object") {
      let fields = objectHelper(value);
      return `{
    ${fields.join(", ")}
}`;
    }
  };

  function objectHelper(obj) {
    return Object.entries(obj).map(([name, value]) => {
      let tsType = valueHelper(value);
      return `"${name}": ${tsType}`;
    });
  }

  let fields = objectHelper(typeMap).join(", ");

  return `{${fields}}`;
}

export default function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

export function typeScriptSignatureForOperation(schema, operationDefinition) {
  let types = typeScriptForOperation(schema, operationDefinition);

  let name = operationDefinition.name.value;

  return `export type ${capitalizeFirstLetter(name)}Payload = ${types}`;
}

export function typeScriptSignatureForOperations(schema, name, operations) {
  let entries = operations.map((operationDefinition) => {
    let types = typeScriptForOperation(schema, operationDefinition);

    let name = operationDefinition.name.value;

    return [name, types];
  });

  let objectType = Object.fromEntries(entries);

  let tsTypes = JSON.stringify(objectType);

  return `export type ${name} = ${JSON.stringify(tsTypes)}`;
}

export function typeScriptForGraphQLType(schema, gqlType) {
  let scalarMap = {
    String: "string",
    ID: "string",
    Int: "number",
    Float: "number",
    Boolean: "boolean",
  };

  if (isListType(gqlType)) {
    let subType = typeScriptForGraphQLType(schema, gqlType.ofType);
    return `Array<${subType}>`;
  } else if (isObjectType(gqlType) || isInputObjectType(gqlType)) {
    let fields = Object.values(gqlType.getFields()).map((field) => {
      let nullable = !isNonNullType(field.type);
      let type = typeScriptForGraphQLType(schema, field.type);

      return `"${field.name}"${nullable ? "?" : ""}: ${type}`;
    });

    return `{${fields.join(", ")}}`;
  } else if (isWrappingType(gqlType)) {
    return typeScriptForGraphQLType(schema, gqlType.ofType);
  } else if (isEnumType(gqlType)) {
    let values = gqlType.getValues();

    let enums = values.map((enumValue) => `"${enumValue.value}"`);

    return enums.join(" | ");
  } else {
    let namedType = getNamedType(gqlType);
    let basicType = scalarMap[namedType.name] || "any";

    return basicType;
  }
}

export function typeScriptSignatureForOperationVariables(
  variableNames,
  schema,
  operationDefinition
) {
  let variables = (operationDefinition.variableDefinitions || [])
    .map((variableDefinition) => {
      let variableName = variableDefinition.variable.name.value;

      return variableNames.includes(variableName)
        ? [variableName, variableDefinition]
        : null;
    })
    .filter(Boolean);

  let typesObject = variables.map(([varName, varDef]) => {
    let printedType = print(varDef.type);
    let parsedType = parseType(printedType);
    let gqlType = typeFromAST(schema, parsedType);
    let tsType = typeScriptForGraphQLType(schema, gqlType);

    return [varName, tsType];
  });

  let typeFields = typesObject
    .map(([name, tsType]) => `"${name}": ${tsType}`)
    .join(", ");

  let types = `{${typeFields}}`;

  return types === "" ? "null" : types;
}

function PreviewForAst({ requestId, schema, ast, onCopy }) {
  let baseGqlType =
    ast.kind === "OperationDefinition"
      ? ast.operation === "query"
        ? schema.getQueryType()
        : ast.operation === "mutation"
        ? schema.getMutationType()
        : ast.operation === "subscription"
        ? schema.getSubscriptionType()
        : null
      : ast.kind === "FragmentDefinition"
      ? schema.getType(ast.typeCondition.name.value)
      : null;

  if (!baseGqlType) {
    return null;
  }

  let helper = (selection, path, parentGqlType) => {
    let parentNamedType =
      getNamedType(parentGqlType) || getNamedType(parentGqlType.type);

    let alias = selection.alias;

    let name = selection.name.value;

    let field = parentNamedType.getFields()[name];
    let gqlType = field?.type;
    let namedType = getNamedType(gqlType);
    let isNullable = !isNonNullType(gqlType);

    let isList =
      isListType(gqlType) || (!isNullable && isListType(gqlType.ofType));

    let isObjectLike =
      isObjectType(namedType) ||
      isUnionType(namedType) ||
      isInterfaceType(namedType);

    let keySelection = selection.alias || name;

    let listAccessor = isList ? "[0]" : "";

    let key = `${keySelection}${listAccessor}`;

    let fullPath = [...path, key];

    let sub = selection.selectionSet?.selections
      .map((selection) => {
        if (selection.kind === "Field") {
          return helper(selection, fullPath, namedType);
        } else if (selection.kind === "InlineFragment") {
          null;
        }

        return null;
      })
      .filter(Boolean);

    let mock = isScalarType(namedType)
      ? JSON.stringify(mockInputType(schema, namedType))
      : isObjectLike
      ? "{}"
      : "";

    let listMock = isList ? `[${mock}]` : mock;

    let finalMock = (mock || "") === "" ? "" : ` // ${listMock}`;

    return (
      <div key={alias || name} style={{ paddingLeft: "10px" }}>
        <span
          style={{ cursor: "copy" }}
          onClick={() => onCopy(fullPath)}
          className="hover:bg-blue-700"
        >
          {name}
          <span style={{ color: "gray" }}>{finalMock}</span>
        </span>
        {sub}
      </div>
    );
  };

  let selections = ast.selectionSet?.selections;

  let sub = selections.map((selection) => {
    return helper(selection, [requestId, "data"], baseGqlType);
  });

  return sub;
}

export function GraphQLPreview({ requestId, schema, definition, onCopy }) {
  return (
    <div
      style={{ textAlign: "left", overflow: "scroll", fontFamily: "monospace" }}
    >
      <PreviewForAst
        requestId={requestId}
        ast={definition}
        schema={schema}
        onCopy={onCopy}
      />
    </div>
  );
}

const services = [
  {
    friendlyServiceName: "Adroll",
    service: "ADROLL",
    slug: "adroll",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "adroll",
  },
  {
    friendlyServiceName: "Box",
    service: "BOX",
    slug: "box",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "box",
  },
  {
    friendlyServiceName: "Dev.to",
    service: "DEV_TO",
    slug: "dev-to",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: true,
    simpleSlug: "devto",
  },
  {
    friendlyServiceName: "Dribbble",
    service: "DRIBBBLE",
    slug: "dribbble",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "dribbble",
  },
  {
    friendlyServiceName: "Dropbox",
    service: "DROPBOX",
    slug: "dropbox",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "dropbox",
  },
  {
    friendlyServiceName: "Contentful",
    service: "CONTENTFUL",
    slug: "contentful",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "contentful",
  },
  {
    friendlyServiceName: "Egghead.io",
    service: "EGGHEADIO",
    slug: "eggheadio",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "eggheadio",
  },
  {
    friendlyServiceName: "Eventil",
    service: "EVENTIL",
    slug: "eventil",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "eventil",
  },
  {
    friendlyServiceName: "Facebook",
    service: "FACEBOOK",
    slug: "facebook",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "facebook",
  },
  {
    friendlyServiceName: "GitHub",
    service: "GITHUB",
    slug: "github",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "github",
  },
  {
    friendlyServiceName: "Gmail",
    service: "GMAIL",
    slug: "gmail",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "gmail",
  },

  {
    friendlyServiceName: "Google Ads",
    service: "GOOGLE_ADS",
    slug: "google-ads",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googleads",
  },
  {
    friendlyServiceName: "Google Analytics",
    service: "GOOGLE_ANALYTICS",
    slug: "google-analytics",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googleanalytics",
  },
  {
    friendlyServiceName: "Google Calendar",
    service: "GOOGLE_CALENDAR",
    slug: "google-calendar",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googlecalendar",
  },
  {
    friendlyServiceName: "Google Compute",
    service: "GOOGLE_COMPUTE",
    slug: "google-compute",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googlecompute",
  },
  {
    friendlyServiceName: "Google Docs",
    service: "GOOGLE_DOCS",
    slug: "google-docs",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googledocs",
  },
  {
    friendlyServiceName: "Google Search Console",
    service: "GOOGLE_SEARCH_CONSOLE",
    slug: "google-search-console",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googlesearchconsole",
  },
  {
    friendlyServiceName: "Google Translate",
    service: "GOOGLE_TRANSLATE",
    slug: "google-translate",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "googletranslate",
  },
  {
    friendlyServiceName: "Google",
    service: "GOOGLE",
    slug: "google",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: true,
    simpleSlug: "google",
  },
  {
    friendlyServiceName: "Hubspot",
    service: "HUBSPOT",
    slug: "hubspot",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "hubspot",
  },
  {
    friendlyServiceName: "Intercom",
    service: "INTERCOM",
    slug: "intercom",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "intercom",
  },
  {
    friendlyServiceName: "Mailchimp",
    service: "MAILCHIMP",
    slug: "mailchimp",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "mailchimp",
  },
  {
    friendlyServiceName: "Meetup",
    service: "MEETUP",
    slug: "meetup",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "meetup",
  },
  {
    friendlyServiceName: "Netlify",
    service: "NETLIFY",
    slug: "netlify",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "netlify",
  },
  {
    friendlyServiceName: "Product Hunt",
    service: "PRODUCT_HUNT",
    slug: "product-hunt",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: true,
    simpleSlug: "producthunt",
  },
  {
    friendlyServiceName: "QuickBooks",
    service: "QUICKBOOKS",
    slug: "quickbooks",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "quickbooks",
  },
  {
    friendlyServiceName: "Salesforce",
    service: "SALESFORCE",
    slug: "salesforce",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "salesforce",
  },
  {
    friendlyServiceName: "Slack",
    service: "SLACK",
    slug: "slack",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "slack",
  },
  {
    friendlyServiceName: "Spotify",
    service: "SPOTIFY",
    slug: "spotify",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "spotify",
  },
  {
    friendlyServiceName: "Stripe",
    service: "STRIPE",
    slug: "stripe",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "stripe",
  },
  {
    friendlyServiceName: "Trello",
    service: "TRELLO",
    slug: "trello",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "trello",
  },
  {
    friendlyServiceName: "Twilio",
    service: "TWILIO",
    slug: "twilio",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "twilio",
  },
  {
    friendlyServiceName: "Twitter",
    service: "TWITTER",
    slug: "twitter",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "twitter",
  },
  {
    friendlyServiceName: "Twitch",
    service: "TWITCH_TV",
    slug: "twitch-tv",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "twitchtv",
  },
  {
    friendlyServiceName: "You Need a Budget",
    service: "YNAB",
    slug: "ynab",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "ynab",
  },
  {
    friendlyServiceName: "YouTube",
    service: "YOUTUBE",
    slug: "youtube",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "youtube",
  },
  {
    friendlyServiceName: "Vercel",
    service: "ZEIT",
    slug: "zeit",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "zeit",
  },
  {
    friendlyServiceName: "Zendesk",
    service: "ZENDESK",
    slug: "zendesk",
    supportsCustomServiceAuth: true,
    supportsOauthLogin: true,
    simpleSlug: "zendesk",
  },
  {
    friendlyServiceName: "Airtable",
    service: "AIRTABLE",
    slug: "airtable",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "airtable",
  },
  {
    friendlyServiceName: "Apollo",
    service: "APOLLO",
    slug: "apollo",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "apollo",
  },
  {
    friendlyServiceName: "Brex",
    service: "BREX",
    slug: "brex",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "brex",
  },
  {
    friendlyServiceName: "Bundlephobia",
    service: "BUNDLEPHOBIA",
    slug: "bundlephobia",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "bundlephobia",
  },
  {
    friendlyServiceName: "Clearbit",
    service: "CLEARBIT",
    slug: "clearbit",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "clearbit",
  },
  {
    friendlyServiceName: "Cloudflare",
    service: "CLOUDFLARE",
    slug: "cloudflare",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "cloudflare",
  },
  {
    friendlyServiceName: "Crunchbase",
    service: "CRUNCHBASE",
    slug: "crunchbase",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "crunchbase",
  },
  {
    friendlyServiceName: "Fedex",
    service: "FEDEX",
    slug: "fedex",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "fedex",
  },
  {
    friendlyServiceName: "Google Maps",
    service: "GOOGLE_MAPS",
    slug: "google-maps",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "googlemaps",
  },
  {
    friendlyServiceName: "GraphCMS",
    service: "GRAPHCMS",
    slug: "graphcms",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "graphcms",
  },
  {
    friendlyServiceName: "Immigration Graph",
    service: "IMMIGRATION_GRAPH",
    slug: "immigration-graph",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "immigrationgraph",
  },
  {
    friendlyServiceName: "LogDNA",
    service: "LOGDNA",
    slug: "logdna",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "logdna",
  },
  {
    friendlyServiceName: "Mixpanel",
    service: "MIXPANEL",
    slug: "mixpanel",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "mixpanel",
  },
  {
    friendlyServiceName: "Mux",
    service: "MUX",
    slug: "mux",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "mux",
  },
  {
    friendlyServiceName: "Npm",
    service: "NPM",
    slug: "npm",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "npm",
  },
  {
    friendlyServiceName: "OneGraph",
    service: "ONEGRAPH",
    slug: "onegraph",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "onegraph",
  },
  {
    friendlyServiceName: "Orbit",
    service: "ORBIT",
    slug: "orbit",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "orbit",
  },
  {
    friendlyServiceName: "OpenCollective",
    service: "OPEN_COLLECTIVE",
    slug: "open-collective",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "opencollective",
  },
  {
    friendlyServiceName: "UPS",
    service: "UPS",
    slug: "ups",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "ups",
  },
  {
    friendlyServiceName: "USPS",
    service: "USPS",
    slug: "usps",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "usps",
  },
  {
    friendlyServiceName: "Wordpress",
    service: "WORDPRESS",
    slug: "wordpress",
    supportsCustomServiceAuth: false,
    supportsOauthLogin: false,
    simpleSlug: "wordpress",
  },
];

export function gatherAllReferencedTypes(schema, query) {
  const types = new Set([]);
  const typeInfo = new TypeInfo(schema);
  visit(
    query,
    visitWithTypeInfo(typeInfo, {
      enter: (node) => {
        const typ = getNamedType(typeInfo.getType());
        if (typ) types.add(typ.name.toLocaleLowerCase().replace("oneme", ""));
      },
    })
  );

  return [...types];
}
export function gatherAllReferencedServices(schema, query) {
  const referencedTypes = gatherAllReferencedTypes(schema, query);

  const referencedServices = new Set([]);

  referencedTypes.forEach((typeName) => {
    services.forEach((service) => {
      if (typeName.startsWith(service.simpleSlug)) {
        referencedServices.add(service);
      }
    });
  });

  return [...referencedServices];
}

if (typeof window !== "undefined") {
  window.mockOperationVariables = mockOperationVariables;
  window.typeScriptForOperation = typeScriptForOperation;
  window.gatherAllReferencedServices = gatherAllReferencedServices;
  window.gatherAllReferencedTypes = gatherAllReferencedTypes;

  window.o = parse(`mutation ExecuteChainMutation(
    $webhookUrl: JSON!
    $chain: OneGraphQueryChainInput!
    $sheetId: JSON!
  ) {
    oneGraph {
      executeChain(
        input: {
          requests: [
            {
              id: "SlackReactionSubscription"
              operationName: "SlackReactionSubscription"
              variables: [
                { name: "webhookUrl", value: $webhookUrl }
              ]
            }
            {
              id: "AddToDocMutation"
              operationName: "AddToDocMutation"
              argumentDependencies: {
                name: "row"
                ifList: ALL
                fromRequestIds: ["SlackReactionSubscription"]
                functionFromScript: "getRow"
                ifMissing: SKIP
              }
              variables: { name: "sheetId", value: $sheetId }
            }
          ]
          script: "const a = true;"
        }
      ) {
        results {
          request {
            id
          }
          result
          argumentDependencies {
            name
            returnValues
            logs {
              level
              body
            }
            name
          }
        }
      }
    }
  }
  
  mutation AddToDocMutation(
    $sheetId: String!
    $row: [String!]!
  ) {
    google {
      sheets {
        appendValues(
          id: $sheetId
          valueInputOption: "USER_ENTERED"
          majorDimenson: "ROWS"
          range: "'Raw Data'!A1"
          values: [$row]
        ) {
          updates {
            spreadsheetId
            updatedRange
            updatedCells
            updatedData {
              values
            }
          }
        }
      }
    }
  }
  
  subscription SlackReactionSubscription(
    $webhookUrl: String!
  ) {
    slack(webhookUrl: $webhookUrl) {
      reactionAddedEvent {
        eventTime
        event {
          user {
            id
            name
          }
          eventTs
          reaction
          item {
            channel {
              name
            }
            message {
              permaLink
              user {
                id
                name
              }
              text
              ts
            }
          }
        }
      }
    }
  }`);
}