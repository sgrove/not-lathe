module NpmPackageFragment = %relay(`
  fragment PackageInfo_npmPackage on NpmPackage {
    name
    description
    id
    downloads {
      lastMonth {
        downloadCount: count
      }
    }
  }
  `)

@react.component
let make = (~npmPackage) => {
  let npmPackage = NpmPackageFragment.use(npmPackage)

  open React
  <>
    <h1> {npmPackage.name->Belt.Option.getWithDefault("<No name>")->string} </h1>
    <p> {npmPackage.description->Belt.Option.getWithDefault("")->string} </p>
    <Comps.Pre> {npmPackage->Debug.JSON.stringify->string} </Comps.Pre>
  </>
}
