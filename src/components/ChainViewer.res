module OneGraphChainViewerFragment = %relay(`
  fragment ChainViewer_chain on OneGraphAppPackageChain {
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
      graphqlOperation
      privacy
      script {
        filename
        language
        concurrentSource
        textualSource
      }
    }
  }`)

module Subscription = %relay(`
subscription ChainViewer_Subscription($chainId: String!) {
  oneGraph {
    studioChainUpdate(input: { chainId: $chainId }) {
      chain {
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
          graphqlOperation
          privacy
          script {
            filename
            language
            concurrentSource
            textualSource
          }
        }
      }
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
