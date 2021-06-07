module Fragment = %relay(`
  fragment PackageList_oneGraphApp on OneGraphApp {
    packages {
      id
      ...PackageViewer_package
    }
  }
`)

@react.component
let make = (~oneGraphApp, ~authTokensRef, ~schema) => {
  let oneGraphApp = Fragment.use(oneGraphApp)

  open React
  <>
    {oneGraphApp.packages
    ->Belt.Array.map(package => {
      <li key={package.id}>
        <PackageViewer
          onCreateChain={i => Js.log2("OnCreateChain", i)}
          onInspectChain={i => Js.log2("onInspectChain", i)}
          onEditChain={(~chain, ~trace) => Js.log3("onEditChain", chain, trace)}
          onDeleteChain={i => Js.log2("onDeleteChain", i)}
          onEditPackage={i => Js.log2("onEditPackage", i)}
          onPublishPackageToNpm={(~npmAuth as i) => Js.log2("onPublishPackageToNpm", i)}
          onPublishPackageToGitHub={(~gitHubOAuthToken as i) =>
            Js.log2("onPublishPackageToGitHub", i)}
          oneGraphAppPackageRef={package.fragmentRefs}
          authTokensRef={authTokensRef}
          schema
        />
      </li>
    })
    ->array}
    <br />
  </>
}
