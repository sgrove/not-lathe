module Query = %relay(`
 query RelayTestQuery($name: String = "graphql") {
   npm {
     package(name: $name) {
       ...PackageInfo_npmPackage
       downloads {
         lastMonth {
           count
         }
       }
     }
   }
 }
`)

@react.component
let make = (~packageName: string) => {
  Js.log("Hi there!")
  open React
  let queryData = Query.use(~variables={name: Some(packageName)}, ())

  let message = switch queryData.npm.package {
  | Some({fragmentRefs: npmPackage, downloads: {lastMonth: Some({count})}}) => <>
      {j`Package downloads for ${packageName}: ${count->string_of_int}`->string}
      <PackageInfo npmPackage />
    </>
  | _ => "No package found"->string
  }

  <h1> {message} </h1>
}
