type addMocksToSchemaOptions = {schema: GraphQLJs.schema}

@module("@graphql-tools/mock")
external addMocksToSchema: addMocksToSchemaOptions => GraphQLJs.schema = "addMocksToSchema"
