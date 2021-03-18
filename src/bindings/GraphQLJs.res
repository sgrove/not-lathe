type schema
type graphqlType
type graphqlField
type graphqlFieldArg
type loc = {end: int, start: int}

type nameNode = {
  kind: string,
  value: string,
  loc: option<loc>,
}

type variable = {name: nameNode}

type variableType

type variableDefinition = {
  variable: variable,
  @as("type")
  typ: variableType,
}

type operationKind = [#query | #mutation | #subscription]
type definitionKind = [#query | #mutation | #subscription | #fragment]

type graphqlOperationDefinition = {
  name: nameNode,
  variableDefinitions: option<array<variableDefinition>>,
  operation: definitionKind,
}

type graphqlAst = {
  kind: string,
  definitions: array<graphqlOperationDefinition>,
}

type introspectionQueryResult

type queryResult = {
  data: Js.Undefined.t<Js.Json.t>,
  errors: Js.Undefined.t<array<Js.Json.t>>,
}

@module("graphql")
external graphql: (schema, string) => Js.Promise.t<queryResult> = "graphql"

@module("graphql")
external graphqlSync: (
  schema,
  string,
  option<'rootValue>,
  option<'sourceValue>,
  option<Js.Json.t>,
) => queryResult = "graphqlSync"

@module("graphql")
external getIntrospectionQuery: unit => string = "getIntrospectionQuery"

@module("graphql")
external buildClientSchema: introspectionQueryResult => schema = "buildClientSchema"

@module("graphql") external buildSchema: string => schema = "buildSchema"

@module("graphql") external printSchema: schema => string = "printSchema"
@module("graphql") external printAst: graphqlAst => string = "print"

@get external typeName: graphqlType => string = "name"

@bs.send
external getQueryType: schema => Js.Undefined.t<graphqlType> = "getQueryType"

@bs.send
external getType: (schema, string) => Js.Undefined.t<graphqlType> = "getType"

@module("graphql") external parseType: string => graphqlAst = "parseType"
@module("graphql") external parse: string => graphqlAst = "parse"

@get
external _typeOfType: graphqlType => Js.Undefined.t<graphqlType> = "type"

@get
external wrappedType: graphqlType => Js.Undefined.t<graphqlType> = "ofType"

let typeOfType = (typ: graphqlType) => typ->_typeOfType->Js.Undefined.toOption

@module("graphql") external isEnumType: graphqlType => bool = "isEnumType"
@module("graphql")
external isInputObjectType: graphqlType => bool = "isInputObjectType"
@module("graphql")
external isInterfaceType: graphqlType => bool = "isInterfaceType"
@module("graphql") external isLeafType: graphqlType => bool = "isLeafType"
@module("graphql")
external isNonNullType: graphqlType => bool = "isNonNullType"
@module("graphql")
external isObjectType: graphqlType => bool = "isObjectType"
@module("graphql")
external isRequiredInputField: graphqlType => bool = "isRequiredInputField"
@module("graphql")
external isScalarType: graphqlType => bool = "isScalarType"
@module("graphql")
external isUnionType: graphqlType => bool = "isUnionType"
@module("graphql")
external isWrappingType: graphqlType => bool = "isWrappingType"

let categorizeType = graphqlType =>
  isInputObjectType(graphqlType)
    ? #InputObject
    : switch isInterfaceType(graphqlType) {
      | true => #Interface
      | false =>
        isObjectType(graphqlType)
          ? #Object
          : switch isScalarType(graphqlType) {
            | true => #Scalar
            | false => #Unknown
            }
      }

@bs.send
external getObjectFields: graphqlType => Js.Dict.t<'field> = "getFields"

@module("graphql")
external getNamedType: graphqlType => graphqlType = "getNamedType"

@bs.send external printType: graphqlType => string = "toString"

@get external fieldName: graphqlField => string = "name"
@get external fieldType: graphqlField => graphqlType = "type"
@get
external fieldDescription: graphqlField => Js.Null_undefined.t<string> = "description"

let getFields = (typ: graphqlType): array<graphqlField> =>
  isObjectType(typ) ? typ->getObjectFields->Js.Dict.values : []

let getFieldByName = (typ: graphqlType, name: string): option<graphqlField> =>
  isObjectType(typ) ? typ->getObjectFields->Js.Dict.get(name) : None

@bs.send
external _schemaTypes: schema => Js.Dict.t<graphqlType> = "getTypeMap"

let schemaTypes = (schema: schema): array<graphqlType> => schema->_schemaTypes->Js.Dict.values

@get external fieldArgs: graphqlField => array<graphqlFieldArg> = "args"

@get external argName: graphqlFieldArg => string = "name"
@get external argType: graphqlFieldArg => graphqlType = "type"

let rec unwrapOutputType = (typ: graphqlType): option<graphqlType> =>
  isWrappingType(typ)
    ? typ->wrappedType->Js.Undefined.toOption->Belt.Option.flatMap(unwrapOutputType)
    : Some(typ)

@module("graphql") external visit: (graphqlAst, 'visitors) => graphqlAst = "visit"

module Mock = {
  let stripVariables = (ast: graphqlAst) => {
    ast->visit({
      "OperationDefinition": node => {
        node["variableDefinitions"] = []
        node
      },
      "Field": node => {
        node["arguments"] = []
        node
      },
      "enter": node => Js.log2("Node: ", node),
    })
  }

  @module("../GraphQLMockInputType.js")
  external mockOperationVariables: (schema, graphqlAst) => Js.Json.t = "mockOperationVariables"

  @module("../GraphQLMockInputType.js")
  external mockOperationDocVariables: (schema, graphqlAst) => Js.Dict.t<Js.Json.t> =
    "mockOperationDocVariables"

  @module("../GraphQLMockInputType.js")
  external typeScriptForOperation: (
    schema,
    graphqlOperationDefinition,
    ~fragmentDefinitions: Js.Dict.t<graphqlOperationDefinition>,
  ) => string = "typeScriptForOperation"

  @module("../GraphQLMockInputType.js")
  external typeScriptSignatureForOperations: (
    schema,
    string,
    array<graphqlOperationDefinition>,
    ~fragmentDefinitions: Js.Dict.t<graphqlOperationDefinition>,
  ) => string = "typeScriptSignatureForOperations"

  @module("../GraphQLMockInputType.js")
  external typeScriptSignatureForOperationVariables: (
    array<string>,
    schema,
    graphqlOperationDefinition,
  ) => string = "typeScriptSignatureForOperationVariables"

  @module("../GraphQLMockInputType.js")
  external gatherFragmentDefinitions: {"operationDoc": string} => Js.Dict.t<
    graphqlOperationDefinition,
  > = "gatherFragmentDefinitions"
}

let operationNames = (ast: graphqlAst) => {
  ast.definitions->Belt.Array.map(def => def.name.value)
}

/* module D = Decoders_bs.Decode

module AST = {
  type rec node =
    | ListType(listTypeNode)
    | NonNullType(nonNullTypeNode)
    | NamedType(namedTypeNode)
  and listTypeNode = {typ: node}
  and nonNullTypeNode = {typ: node}
  and namedTypeNode = {name: nameNode}
  and nameNode = {value: string}

  type definition = {name: nameNode}
  type document = {definitions: list<definition>}

  let nameNodeDecoder: D.decoder<nameNode> = {
    open D
    \">>="(field("value", string), value => succeed({value: value}))
  }

  let namedTypeNodeDecoder: D.decoder<node> = {
    open D
    \">>="(field("name", nameNodeDecoder), namedNode => succeed(NamedType({name: namedNode})))
  }

  let rec listTypeNodeDecoder: Lazy.t<D.decoder<node>> = {
    open D
    lazy \">>="(field("type", Lazy.force(nodeDecoder)), node => succeed(ListType({typ: node})))
  }
  and nonNullTypeNodeDecoder: Lazy.t<D.decoder<node>> = {
    open D
    lazy \">>="(field("type", Lazy.force(nodeDecoder)), node => succeed(NonNullType({typ: node})))
  }
  and nodeDecoder: Lazy.t<D.decoder<node>> = {
    open D
    lazy \">>="(field("kind", string), x =>
      switch x {
      | "ListType" => Lazy.force(listTypeNodeDecoder)
      | "NonNullType" => Lazy.force(listTypeNodeDecoder)
      | "NamedType" => namedTypeNodeDecoder
      | other => fail("Unrecognized JSON astNode kind: " ++ other)
      }
    )
  }

  let definitionNodeDecoder: D.decoder<definition> = {
    open D
    \">>="(field("name", nameNodeDecoder), nameNode => succeed({name: nameNode}))
  }

  let documentNodeDecoder: D.decoder<document> = {
    open D
    \">>="(field("definitions", list(definitionNodeDecoder)), definitionNodes =>
      succeed({definitions: definitionNodes})
    )
  }

  let json = "[[[[Boolean!]!]]]!"->parseType->Js.Json.stringifyAny->Belt.Option.getExn

  let parsedAst = D.decode_string(Lazy.force(nodeDecoder), json)
  Js.log2(
    "Recursize Parsed deep: ",
    switch parsedAst {
    | Ok(ast) => ast
    | Error(err) => D.string_of_error(err)->Obj.magic
    },
  )

  let json_ = `
type Example {
  id: String!
  age: Int!
  colors: [String!]
}
     `->parse

  let json = json_->Js.Json.stringifyAny->Belt.Option.getExn

  Js.log2("Raw input: ", json_)

  let parsedDoc = D.decode_string(documentNodeDecoder, json)
  Js.log2(
    "Full ast parsed: ",
    switch parsedAst {
    | Ok(ast) => ast
    | Error(err) => D.string_of_error(err)->Obj.magic
    },
  )

  let parseType = inputString => {
    let json = inputString->parseType->Js.Json.stringifyAny->Belt.Option.getExn

    D.decode_string(Lazy.force(nodeDecoder), json)
  }

  /* let example = */
  /* `ListType({ */
  /* kind: `ListType, */
  /* typ: */
  /* `NonNullType({ */
  /* kind: `NonNullType, */
  /* typ: { */
  /* `NamedType({ */
  /* kind: `NamedType, */
  /* name: { */
  /* kind: `Name, */
  /* value: "Boolean", */
  /* }, */
  /* }); */
  /* }, */
  /* }), */
  /* }); */
  let x = 10

  let rec getNamedType = (node: node) =>
    switch node {
    | ListType({typ})
    | NonNullType({typ}) =>
      getNamedType(typ)
    | NamedType({name: {value: name}}) => name
    }
}
*/
let exampleSdl = `
schema {
  query: Root
}

"""A single film."""
type Film implements Node {
  """The title of this film."""
  title: String

  """The episode number of this film."""
  episodeID: Int

  """The opening paragraphs at the beginning of this film."""
  openingCrawl: String

  """The name of the director of this film."""
  director: String

  """The name(s) of the producer(s) of this film."""
  producers: [String]

  """The ISO 8601 date format of film release at original creator country."""
  releaseDate: String
  speciesConnection(after: String, first: Int, before: String, last: Int): FilmSpeciesConnection
  starshipConnection(after: String, first: Int, before: String, last: Int): FilmStarshipsConnection
  vehicleConnection(after: String, first: Int, before: String, last: Int): FilmVehiclesConnection
  characterConnection(after: String, first: Int, before: String, last: Int): FilmCharactersConnection
  planetConnection(after: String, first: Int, before: String, last: Int): FilmPlanetsConnection

  """The ISO 8601 date format of the time that this resource was created."""
  created: String

  """The ISO 8601 date format of the time that this resource was edited."""
  edited: String

  """The ID of an object"""
  id: ID!
}

"""A connection to a list of items."""
type FilmCharactersConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [FilmCharactersEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  characters: [Person]
}

"""An edge in a connection."""
type FilmCharactersEdge {
  """The item at the end of the edge"""
  node: Person

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type FilmPlanetsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [FilmPlanetsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  planets: [Planet]
}

"""An edge in a connection."""
type FilmPlanetsEdge {
  """The item at the end of the edge"""
  node: Planet

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type FilmsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [FilmsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  films: [Film]
}

"""An edge in a connection."""
type FilmsEdge {
  """The item at the end of the edge"""
  node: Film

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type FilmSpeciesConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [FilmSpeciesEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  species: [Species]
}

"""An edge in a connection."""
type FilmSpeciesEdge {
  """The item at the end of the edge"""
  node: Species

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type FilmStarshipsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [FilmStarshipsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  starships: [Starship]
}

"""An edge in a connection."""
type FilmStarshipsEdge {
  """The item at the end of the edge"""
  node: Starship

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type FilmVehiclesConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [FilmVehiclesEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  vehicles: [Vehicle]
}

"""An edge in a connection."""
type FilmVehiclesEdge {
  """The item at the end of the edge"""
  node: Vehicle

  """A cursor for use in pagination"""
  cursor: String!
}

"""An object with an ID"""
interface Node {
  """The id of the object."""
  id: ID!
}

"""Information about pagination in a connection."""
type PageInfo {
  """When paginating forwards, are there more items?"""
  hasNextPage: Boolean!

  """When paginating backwards, are there more items?"""
  hasPreviousPage: Boolean!

  """When paginating backwards, the cursor to continue."""
  startCursor: String

  """When paginating forwards, the cursor to continue."""
  endCursor: String
}

"""A connection to a list of items."""
type PeopleConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PeopleEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  people: [Person]
}

"""An edge in a connection."""
type PeopleEdge {
  """The item at the end of the edge"""
  node: Person

  """A cursor for use in pagination"""
  cursor: String!
}

"""An individual person or character within the Star Wars universe."""
type Person implements Node {
  """The name of this person."""
  name: String

  """
  The birth year of the person, using the in-universe standard of BBY or ABY -
  Before the Battle of Yavin or After the Battle of Yavin. The Battle of Yavin is
  a battle that occurs at the end of Star Wars episode IV: A New Hope.
  """
  birthYear: String

  """
  The eye color of this person. Will be "unknown" if not known or "n/a" if the
  person does not have an eye.
  """
  eyeColor: String

  """
  The gender of this person. Either "Male", "Female" or "unknown",
  "n/a" if the person does not have a gender.
  """
  gender: String

  """
  The hair color of this person. Will be "unknown" if not known or "n/a" if the
  person does not have hair.
  """
  hairColor: String

  """The height of the person in centimeters."""
  height: Int

  """The mass of the person in kilograms."""
  mass: Float

  """The skin color of this person."""
  skinColor: String

  """A planet that this person was born on or inhabits."""
  homeworld: Planet
  filmConnection(after: String, first: Int, before: String, last: Int): PersonFilmsConnection

  """The species that this person belongs to, or null if unknown."""
  species: Species
  starshipConnection(after: String, first: Int, before: String, last: Int): PersonStarshipsConnection
  vehicleConnection(after: String, first: Int, before: String, last: Int): PersonVehiclesConnection

  """The ISO 8601 date format of the time that this resource was created."""
  created: String

  """The ISO 8601 date format of the time that this resource was edited."""
  edited: String

  """The ID of an object"""
  id: ID!
}

"""A connection to a list of items."""
type PersonFilmsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PersonFilmsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  films: [Film]
}

"""An edge in a connection."""
type PersonFilmsEdge {
  """The item at the end of the edge"""
  node: Film

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type PersonStarshipsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PersonStarshipsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  starships: [Starship]
}

"""An edge in a connection."""
type PersonStarshipsEdge {
  """The item at the end of the edge"""
  node: Starship

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type PersonVehiclesConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PersonVehiclesEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  vehicles: [Vehicle]
}

"""An edge in a connection."""
type PersonVehiclesEdge {
  """The item at the end of the edge"""
  node: Vehicle

  """A cursor for use in pagination"""
  cursor: String!
}

"""
A large mass, planet or planetoid in the Star Wars Universe, at the time of
0 ABY.
"""
type Planet implements Node {
  """The name of this planet."""
  name: String

  """The diameter of this planet in kilometers."""
  diameter: Int

  """
  The number of standard hours it takes for this planet to complete a single
  rotation on its axis.
  """
  rotationPeriod: Int

  """
  The number of standard days it takes for this planet to complete a single orbit
  of its local star.
  """
  orbitalPeriod: Int

  """
  A number denoting the gravity of this planet, where "1" is normal or 1 standard
  G. "2" is twice or 2 standard Gs. "0.5" is half or 0.5 standard Gs.
  """
  gravity: String

  """The average population of sentient beings inhabiting this planet."""
  population: Float

  """The climates of this planet."""
  climates: [String]

  """The terrains of this planet."""
  terrains: [String]

  """
  The percentage of the planet surface that is naturally occuring water or bodies
  of water.
  """
  surfaceWater: Float
  residentConnection(after: String, first: Int, before: String, last: Int): PlanetResidentsConnection
  filmConnection(after: String, first: Int, before: String, last: Int): PlanetFilmsConnection

  """The ISO 8601 date format of the time that this resource was created."""
  created: String

  """The ISO 8601 date format of the time that this resource was edited."""
  edited: String

  """The ID of an object"""
  id: ID!
}

"""A connection to a list of items."""
type PlanetFilmsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PlanetFilmsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  films: [Film]
}

"""An edge in a connection."""
type PlanetFilmsEdge {
  """The item at the end of the edge"""
  node: Film

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type PlanetResidentsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PlanetResidentsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  residents: [Person]
}

"""An edge in a connection."""
type PlanetResidentsEdge {
  """The item at the end of the edge"""
  node: Person

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type PlanetsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [PlanetsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  planets: [Planet]
}

"""An edge in a connection."""
type PlanetsEdge {
  """The item at the end of the edge"""
  node: Planet

  """A cursor for use in pagination"""
  cursor: String!
}

type Root {
  allFilms(after: String, first: Int, before: String, last: Int): FilmsConnection
  film(id: ID, filmID: ID!): Film
  allPeople(after: String, first: Int, before: String, last: Int): PeopleConnection
  person(id: ID, personID: ID): Person
  allPlanets(after: String, first: Int, before: String, last: Int): PlanetsConnection
  planet(id: ID, planetID: ID): Planet
  allSpecies(after: String, first: Int, before: String, last: Int): SpeciesConnection
  species(id: ID, speciesID: ID): Species
  allStarships(after: String, first: Int, before: String, last: Int): StarshipsConnection
  starship(id: ID, starshipID: ID): Starship
  allVehicles(after: String, first: Int, before: String, last: Int): VehiclesConnection
  vehicle(id: ID, vehicleID: ID): Vehicle

  """Fetches an object given its ID"""
  node(
    """The ID of an object"""
    id: ID!
  ): Node
}

"""A type of person or character within the Star Wars Universe."""
type Species implements Node {
  """The name of this species."""
  name: String

  """The classification of this species, such as "mammal" or "reptile"."""
  classification: String

  """The designation of this species, such as "sentient"."""
  designation: String

  """The average height of this species in centimeters."""
  averageHeight: Float

  """The average lifespan of this species in years, null if unknown."""
  averageLifespan: Int

  """
  Common eye colors for this species, null if this species does not typically
  have eyes.
  """
  eyeColors: [String]

  """
  Common hair colors for this species, null if this species does not typically
  have hair.
  """
  hairColors: [String]

  """
  Common skin colors for this species, null if this species does not typically
  have skin.
  """
  skinColors: [String]

  """The language commonly spoken by this species."""
  language: String

  """A planet that this species originates from."""
  homeworld: Planet
  personConnection(after: String, first: Int, before: String, last: Int): SpeciesPeopleConnection
  filmConnection(after: String, first: Int, before: String, last: Int): SpeciesFilmsConnection

  """The ISO 8601 date format of the time that this resource was created."""
  created: String

  """The ISO 8601 date format of the time that this resource was edited."""
  edited: String

  """The ID of an object"""
  id: ID!
}

"""A connection to a list of items."""
type SpeciesConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [SpeciesEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  species: [Species]
}

"""An edge in a connection."""
type SpeciesEdge {
  """The item at the end of the edge"""
  node: Species

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type SpeciesFilmsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [SpeciesFilmsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  films: [Film]
}

"""An edge in a connection."""
type SpeciesFilmsEdge {
  """The item at the end of the edge"""
  node: Film

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type SpeciesPeopleConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [SpeciesPeopleEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  people: [Person]
}

"""An edge in a connection."""
type SpeciesPeopleEdge {
  """The item at the end of the edge"""
  node: Person

  """A cursor for use in pagination"""
  cursor: String!
}

"""A single transport craft that has hyperdrive capability."""
type Starship implements Node {
  """The name of this starship. The common name, such as "Death Star"."""
  name: String

  """
  The model or official name of this starship. Such as "T-65 X-wing" or "DS-1
  Orbital Battle Station".
  """
  model: String

  """
  The class of this starship, such as "Starfighter" or "Deep Space Mobile
  Battlestation"
  """
  starshipClass: String

  """The manufacturers of this starship."""
  manufacturers: [String]

  """The cost of this starship new, in galactic credits."""
  costInCredits: Float

  """The length of this starship in meters."""
  length: Float

  """The number of personnel needed to run or pilot this starship."""
  crew: String

  """The number of non-essential people this starship can transport."""
  passengers: String

  """
  The maximum speed of this starship in atmosphere. null if this starship is
  incapable of atmosphering flight.
  """
  maxAtmospheringSpeed: Int

  """The class of this starships hyperdrive."""
  hyperdriveRating: Float

  """
  The Maximum number of Megalights this starship can travel in a standard hour.
  A "Megalight" is a standard unit of distance and has never been defined before
  within the Star Wars universe. This figure is only really useful for measuring
  the difference in speed of starships. We can assume it is similar to AU, the
  distance between our Sun (Sol) and Earth.
  """
  MGLT: Int

  """The maximum number of kilograms that this starship can transport."""
  cargoCapacity: Float

  """
  The maximum length of time that this starship can provide consumables for its
  entire crew without having to resupply.
  """
  consumables: String
  pilotConnection(after: String, first: Int, before: String, last: Int): StarshipPilotsConnection
  filmConnection(after: String, first: Int, before: String, last: Int): StarshipFilmsConnection

  """The ISO 8601 date format of the time that this resource was created."""
  created: String

  """The ISO 8601 date format of the time that this resource was edited."""
  edited: String

  """The ID of an object"""
  id: ID!
}

"""A connection to a list of items."""
type StarshipFilmsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [StarshipFilmsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  films: [Film]
}

"""An edge in a connection."""
type StarshipFilmsEdge {
  """The item at the end of the edge"""
  node: Film

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type StarshipPilotsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [StarshipPilotsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  pilots: [Person]
}

"""An edge in a connection."""
type StarshipPilotsEdge {
  """The item at the end of the edge"""
  node: Person

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type StarshipsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [StarshipsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  starships: [Starship]
}

"""An edge in a connection."""
type StarshipsEdge {
  """The item at the end of the edge"""
  node: Starship

  """A cursor for use in pagination"""
  cursor: String!
}

"""A single transport craft that does not have hyperdrive capability"""
type Vehicle implements Node {
  """
  The name of this vehicle. The common name, such as "Sand Crawler" or "Speeder
  bike".
  """
  name: String

  """
  The model or official name of this vehicle. Such as "All-Terrain Attack
  Transport".
  """
  model: String

  """The class of this vehicle, such as "Wheeled" or "Repulsorcraft"."""
  vehicleClass: String

  """The manufacturers of this vehicle."""
  manufacturers: [String]

  """The cost of this vehicle new, in Galactic Credits."""
  costInCredits: Float

  """The length of this vehicle in meters."""
  length: Float

  """The number of personnel needed to run or pilot this vehicle."""
  crew: String

  """The number of non-essential people this vehicle can transport."""
  passengers: String

  """The maximum speed of this vehicle in atmosphere."""
  maxAtmospheringSpeed: Int

  """The maximum number of kilograms that this vehicle can transport."""
  cargoCapacity: Float

  """
  The maximum length of time that this vehicle can provide consumables for its
  entire crew without having to resupply.
  """
  consumables: String
  pilotConnection(after: String, first: Int, before: String, last: Int): VehiclePilotsConnection
  filmConnection(after: String, first: Int, before: String, last: Int): VehicleFilmsConnection

  """The ISO 8601 date format of the time that this resource was created."""
  created: String

  """The ISO 8601 date format of the time that this resource was edited."""
  edited: String

  """The ID of an object"""
  id: ID!
}

"""A connection to a list of items."""
type VehicleFilmsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [VehicleFilmsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  films: [Film]
}

"""An edge in a connection."""
type VehicleFilmsEdge {
  """The item at the end of the edge"""
  node: Film

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type VehiclePilotsConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [VehiclePilotsEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  pilots: [Person]
}

"""An edge in a connection."""
type VehiclePilotsEdge {
  """The item at the end of the edge"""
  node: Person

  """A cursor for use in pagination"""
  cursor: String!
}

"""A connection to a list of items."""
type VehiclesConnection {
  """Information to aid in pagination."""
  pageInfo: PageInfo!

  """A list of edges."""
  edges: [VehiclesEdge]

  """
  A count of the total number of objects in this connection, ignoring pagination.
  This allows a client to fetch the first five objects by passing "5" as the
  argument to "first", then fetch the total count so it could display "5 of 83",
  for example.
  """
  totalCount: Int

  """
  A list of all of the objects returned in the connection. This is a convenience
  field provided for quickly exploring the API; rather than querying for
  "{ edges { node } }" when no edge data is needed, this field can be be used
  instead. Note that when clients like Relay need to fetch the "cursor" field on
  the edge to enable efficient pagination, this shortcut cannot be used, and the
  full "{ edges { node } }" version should be used instead.
  """
  vehicles: [Vehicle]
}

"""An edge in a connection."""
type VehiclesEdge {
  """The item at the end of the edge"""
  node: Vehicle

  """A cursor for use in pagination"""
  cursor: String!
}

type SpotifyTrack {
   id: String!
   name: String!
}
`

let getSubFields = (schema, typename) =>
  schema->getType(typename)->Js.Undefined.toOption->Belt.Option.map(root => root |> getFields)

let rootFields: (schema, 'a) => option<array<graphqlField>> = (schema, root) => {
  let fields = root->typeName->getSubFields(schema, _)
  fields
}

let install = %raw(`
function() {
     window.gql = Graphql
}
`)

// install()
