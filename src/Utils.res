let services = Js.Dict.fromArray([
  ("adroll", ("adroll.com", "Adroll")),
  ("box", ("box.com", "Box")),
  ("dev-to", ("dev.to", "Dev.to")),
  ("dribbble", ("dribbble.com", "Dribbble")),
  ("dropbox", ("dropbox.com", "Dropbox")),
  ("contentful", ("contentful.com", "Contentful")),
  ("eggheadio", ("eggheadio.com", "Egghead.io")),
  ("eventil", ("eventil.com", "Eventil")),
  ("facebook", ("facebook.com", "Facebook")),
  ("github", ("github.com", "GitHub")),
  ("gmail", ("gmail.com", "Gmail")),
  ("google", ("google.com", "Google")),
  ("google-ads", ("google-ads.com", "Google Ads")),
  ("google-analytics", ("google-analytics.com", "Google Analytics")),
  ("google-calendar", ("google-calendar.com", "Google Calendar")),
  ("google-compute", ("google-compute.com", "Google Compute")),
  ("google-docs", ("google-docs.com", "Google Docs")),
  ("google-search-console", ("google-search-console.com", "Google Search Console")),
  ("google-translate", ("google-translate.com", "Google Translate")),
  ("hubspot", ("hubspot.com", "Hubspot")),
  ("intercom", ("intercom.com", "Intercom")),
  ("mailchimp", ("mailchimp.com", "Mailchimp")),
  ("meetup", ("meetup.com", "Meetup")),
  ("netlify", ("netlify.com", "Netlify")),
  ("product-hunt", ("product-hunt.com", "Product Hunt")),
  ("quickbooks", ("quickbooks.com", "QuickBooks")),
  ("salesforce", ("salesforce.com", "Salesforce")),
  ("slack", ("slack.com", "Slack")),
  ("spotify", ("spotify.com", "Spotify")),
  ("stripe", ("stripe.com", "Stripe")),
  ("trello", ("trello.com", "Trello")),
  ("twilio", ("twilio.com", "Twilio")),
  ("twitter", ("twitter.com", "Twitter")),
  ("twitch-tv", ("twitch-tv.com", "Twitch")),
  ("ynab", ("ynab.com", "You Need a Budget")),
  ("youtube", ("youtube.com", "YouTube")),
  ("zeit", ("vercel.com", "Vercel")),
  ("zendesk", ("zendesk.com", "Zendesk")),
  ("airtable", ("airtable.com", "Airtable")),
  ("apollo", ("apollo.com", "Apollo")),
  ("brex", ("brex.com", "Brex")),
  ("bundlephobia", ("bundlephobia.com", "Bundlephobia")),
  ("clearbit", ("clearbit.com", "Clearbit")),
  ("cloudflare", ("cloudflare.com", "Cloudflare")),
  ("crunchbase", ("crunchbase.com", "Crunchbase")),
  ("fedex", ("fedex.com", "Fedex")),
  ("google-maps", ("google-maps.com", "Google Maps")),
  ("graphcms", ("graphcms.com", "GraphCMS")),
  ("immigration-graph", ("immigration-graph.com", "Immigration Graph")),
  ("logdna", ("logdna.com", "LogDNA")),
  ("mixpanel", ("mixpanel.com", "Mixpanel")),
  ("mux", ("mux.com", "Mux")),
  ("npm", ("npmjs.com", "Npm")),
  ("onegraph", ("onegraph.com", "OneGraph")),
  ("orbit", ("orbit.com", "Orbit")),
  ("open-collective", ("open-collective.com", "OpenCollective")),
  ("ups", ("ups.com", "UPS")),
  ("usps", ("usps.com", "USPS")),
  ("wordpress", ("wordpress.com", "Wordpress")),
  // Exceptions
  ("firebase", ("firebase.events", "Firebase")),
  ("rss", ("rss.com", "RSS")),
])

let serviceImageUrl = (~size=25, ~greyscale=false, service) => {
  let domain = services->Js.Dict.get(service)

  domain->Belt.Option.map(((domain, friendlyServiceName)) => (
    j`//logo.clearbit.com/${domain}?size=${size->string_of_int}${greyscale
        ? "greyscale=${greyscale->string_of_bool}"
        : ""}`,
    friendlyServiceName,
  ))
}

@val external prompt: (string, ~default: option<string>) => Js.Nullable.t<string> = "prompt"
@val external alert: string => unit = "alert"
@val external confirm: string => bool = "confirm"

module Window = {
  let scrollY: unit => option<int> = () => {
    %external(window)->Belt.Option.map((window: Dom.window) => Obj.magic(window)["scrollY"])
  }

  let locationOrigin: unit => option<string> = () => {
    %external(window)->Belt.Option.map((window: Dom.window) =>
      Obj.magic(window)["location"]["origin"]
    )
  }

  let addEventListener = (~event: string, ~handler): unit => {
    %external(window)->Belt.Option.forEach((window: Dom.window) =>
      Obj.magic(window)["addEventListener"](event, handler)
    )
  }

  let removeEventListener = (~event: string, ~handler): unit => {
    %external(window)->Belt.Option.forEach((window: Dom.window) =>
      Obj.magic(window)["removeEventListener"](event, handler)
    )
  }
}

module Date = {
  let timeAgo = (date: Js.Date.t): string => {
    let dateMs = date->Js.Date.getTime
    let now = Js.Date.now()

    switch now -. dateMs {
    | value if value < 30000. => "Just now"
    | value if value < 45000. => "30 seconds ago"
    | value if value < 60000. *. 60. =>
      let minutes = (value /. 60000.)->int_of_float->string_of_int
      j`${minutes} minutes ago`
    | value if value < 60000. *. 60. *. 24. =>
      let hours = (value /. (60000. *. 60.))->int_of_float->string_of_int
      j`${hours} hours ago`
    | value if value < 60000. *. 60. *. 24. *. 7. =>
      let days = (value /. (60000. *. 60. *. 24.))->int_of_float->string_of_int
      j`${days} days ago`
    | value if value < 60000. *. 60. *. 24. *. 30. =>
      let weeks = (value /. (60000. *. 60. *. 24. *. 7.))->int_of_float->string_of_int
      j`${weeks} weeks ago`
    | value if value < 60000. *. 60. *. 24. *. 30. *. 12. =>
      let months = (value /. (60000. *. 60. *. 24. *. 7. *. 30.))->int_of_float->string_of_int
      j`${months} months ago`
    | value =>
      let years =
        (value /. (60000. *. 60. *. 24. *. 7. *. 30. *. 12.0))->int_of_float->string_of_int
      j`${years} years ago`
    }
  }
}

module String = {
  let camelize: string => string = %raw(`function camelize(text) {
    return text.replace(/^([A-Z])|[\s-_]+(\w)/g, function(match, p1, p2, offset) {
        if (p2) return p2.toUpperCase();
        return p1.toLowerCase();        
    });
}`)

  let capitalizeFirstLetter: string => string = %raw(`function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}`)

  let distinctStrings: array<string> => array<string> = %raw("function(arr) {
return [...(new Set(arr))]
}")

  let safeNameRe = Js.Re.fromStringWithFlags("[^a-z0-9]", ~flags="gi")
  let safeName: string => string = string => {
    string->Js.String2.replaceByRe(safeNameRe, "")
  }

  let safeCamelize: string => string = string => {
    string->Js.String2.replaceByRe(safeNameRe, "_")->camelize
  }

  let replaceRange: (
    string,
    ~start: int,
    ~end: int,
    ~by: string,
  ) => string = %raw(`function replaceRange(s, start, end, substitute) {
    return s.substring(0, start) + substitute + s.substring(end);
}`)
}
