module OneGraphChainViewerFragment = %relay(`
  fragment ChainViewer_oneGraphAppPackageChain on OneGraphAppPackageChain {
    id
    name
    description
    libraryScript {
      filename
      language
      concurrentSource
      textualSource
    }
    createdAt
    updatedAt
    actions {
      id
      name
      description
      graphQLOperation
      privacy
      script {
        filename
        language
        concurrentSource
        textualSource
      }
    }
  }`)

@react.component
let make = (
  ~onCreateChain,
  ~onInspectChain,
  ~onEditChain,
  ~onDeleteChain,
  ~onEditPackage,
  ~onPublishPackageToNpm,
  ~onPublishPackageToGitHub,
  ~oneGraphAppPackageRef,
) => {
  let chain = OneGraphChainViewerFragment.use(oneGraphAppPackageRef)

  open React

  let (state, setState) = useState(() => {None})

  <div> {chain.name->string} </div>
}
