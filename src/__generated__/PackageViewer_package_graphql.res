/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type enum_OneGraphServiceEnum = private [>
    | #ADROLL
    | #AIRTABLE
    | #APOLLO
    | #BOX
    | #BREX
    | #BUNDLEPHOBIA
    | #CLEARBIT
    | #CLOUDFLARE
    | #CONTENTFUL
    | #CRUNCHBASE
    | #DEV_TO
    | #DISCORD
    | #DRIBBBLE
    | #DROPBOX
    | #EGGHEADIO
    | #EVENTIL
    | #FACEBOOK
    | #FEDEX
    | #FIREBASE
    | #GITHUB
    | #GMAIL
    | #GOOGLE
    | #GOOGLE_ADS
    | #GOOGLE_ANALYTICS
    | #GOOGLE_CALENDAR
    | #GOOGLE_COMPUTE
    | #GOOGLE_DOCS
    | #GOOGLE_MAPS
    | #GOOGLE_SEARCH_CONSOLE
    | #GOOGLE_TRANSLATE
    | #GRAPHCMS
    | #HUBSPOT
    | #IMMIGRATION_GRAPH
    | #INTERCOM
    | #LOGDNA
    | #MAILCHIMP
    | #MEETUP
    | #MIXPANEL
    | #MUX
    | #NETLIFY
    | #NPM
    | #ONEGRAPH
    | #OPEN_COLLECTIVE
    | #ORBIT
    | #PRODUCT_HUNT
    | #QUICKBOOKS
    | #SALESFORCE
    | #SLACK
    | #SPOTIFY
    | #STRIPE
    | #TRELLO
    | #TWILIO
    | #TWITCH_TV
    | #TWITTER
    | #UPS
    | #USPS
    | #WORDPRESS
    | #YNAB
    | #YOUTUBE
    | #ZEIT
    | #ZENDESK
    ]
  
  type enum_OneGraphServiceEnum_input = [
    | #ADROLL
    | #AIRTABLE
    | #APOLLO
    | #BOX
    | #BREX
    | #BUNDLEPHOBIA
    | #CLEARBIT
    | #CLOUDFLARE
    | #CONTENTFUL
    | #CRUNCHBASE
    | #DEV_TO
    | #DISCORD
    | #DRIBBBLE
    | #DROPBOX
    | #EGGHEADIO
    | #EVENTIL
    | #FACEBOOK
    | #FEDEX
    | #FIREBASE
    | #GITHUB
    | #GMAIL
    | #GOOGLE
    | #GOOGLE_ADS
    | #GOOGLE_ANALYTICS
    | #GOOGLE_CALENDAR
    | #GOOGLE_COMPUTE
    | #GOOGLE_DOCS
    | #GOOGLE_MAPS
    | #GOOGLE_SEARCH_CONSOLE
    | #GOOGLE_TRANSLATE
    | #GRAPHCMS
    | #HUBSPOT
    | #IMMIGRATION_GRAPH
    | #INTERCOM
    | #LOGDNA
    | #MAILCHIMP
    | #MEETUP
    | #MIXPANEL
    | #MUX
    | #NETLIFY
    | #NPM
    | #ONEGRAPH
    | #OPEN_COLLECTIVE
    | #ORBIT
    | #PRODUCT_HUNT
    | #QUICKBOOKS
    | #SALESFORCE
    | #SLACK
    | #SPOTIFY
    | #STRIPE
    | #TRELLO
    | #TWILIO
    | #TWITCH_TV
    | #TWITTER
    | #UPS
    | #USPS
    | #WORDPRESS
    | #YNAB
    | #YOUTUBE
    | #ZEIT
    | #ZENDESK
    ]
  
  type rec fragment_chains = {
    id: string,
    name: string,
    authToken: option<fragment_chains_authToken>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ChainViewer_chain | #ChainEditor_chain]>
  }
   and fragment_chains_authToken = {
    obscuredToken: string,
    name: option<string>,
    userAuths: array<fragment_chains_authToken_userAuths>,
  }
   and fragment_chains_authToken_userAuths = {
    service: enum_OneGraphServiceEnum,
  }
  
  
  type fragment = {
    description: option<string>,
    id: string,
    name: string,
    version: string,
    chains: array<fragment_chains>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"description":{"n":""},"chains":{"f":""},"chains_authToken":{"n":""},"chains_authToken_name":{"n":""}}}`
    )
  
  let fragmentConverterMap = ()
  let convertFragment = v => v->RescriptRelay.convertObj(
    fragmentConverter, 
    fragmentConverterMap, 
    Js.undefined
  )
}
type t
type fragmentRef
external getFragmentRef:
  RescriptRelay.fragmentRefs<[> | #PackageViewer_package]> => fragmentRef = "%identity"


module Utils = {
  @@ocaml.warning("-33")
  open Types
  external oneGraphServiceEnum_toString:
  enum_OneGraphServiceEnum => string = "%identity"
  external oneGraphServiceEnum_input_toString:
  enum_OneGraphServiceEnum_input => string = "%identity"
}
type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PackageViewer_package",
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "description",
      "storageKey": null
    },
    (v0/*: any*/),
    (v1/*: any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "version",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "OneGraphAppPackageChain",
      "kind": "LinkedField",
      "name": "chains",
      "plural": true,
      "selections": [
        (v0/*: any*/),
        (v1/*: any*/),
        {
          "alias": null,
          "args": null,
          "concreteType": "OneGraphAccessToken",
          "kind": "LinkedField",
          "name": "authToken",
          "plural": false,
          "selections": [
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "obscuredToken",
              "storageKey": null
            },
            (v1/*: any*/),
            {
              "alias": null,
              "args": null,
              "concreteType": "OneGraphUserAuth",
              "kind": "LinkedField",
              "name": "userAuths",
              "plural": true,
              "selections": [
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "service",
                  "storageKey": null
                }
              ],
              "storageKey": null
            }
          ],
          "storageKey": null
        },
        {
          "args": null,
          "kind": "FragmentSpread",
          "name": "ChainViewer_chain"
        },
        {
          "args": null,
          "kind": "FragmentSpread",
          "name": "ChainEditor_chain"
        }
      ],
      "storageKey": null
    }
  ],
  "type": "OneGraphAppPackage",
  "abstractKey": null
};
})() `)


