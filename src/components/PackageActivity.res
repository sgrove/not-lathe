module PackageActivitySubscription = %relay(`
  subscription PackageActivity2Subscription {
    npm {
      allPublishActivity {
        package {
          __typename
          ...PackageInfo_npmPackage
        }
      }
    }
  }
`)

@react.component
let make = () => {
  let relayEnv = RescriptRelay.useEnvironmentFromContext()

  let (subscriptionData, setSubscriptionData) = React.useState(() => None)
  let (subscriptionEventCount, setSubscriptionEventCount) = React.useState(() => 0)

  React.useEffect0(() => {
    let disposable: RescriptRelay.Disposable.t = PackageActivitySubscription.subscribe(
      ~environment=relayEnv,
      ~variables=(),
      ~onNext=response => {
        setSubscriptionData(_ => Some(response))
        setSubscriptionEventCount(count => count + 1)
      },
      (),
    )

    /* Clean up/dispose of the subscription if we're unmounted */
    Some(() => disposable->RescriptRelay.Disposable.dispose)
  })

  open React

  <>
    {"PackageActivitySubscription_result: "->string}
    {switch subscriptionData {
    | None => "Waiting for a subscription event..."->string
    | Some({npm: {allPublishActivity: Some({package: {fragmentRefs: npmPackage}})}}) => <>
        <PackageInfo npmPackage />
      </>
    | Some(subscriptionData) =>
      {Js.log2("Sub event: ", subscriptionData)}

      <>
        {j`$subscriptionEventCount events received: `->string}
        <pre> {subscriptionData->Debug.JSON.stringify->string} </pre>
      </>
    }}
  </>
}
