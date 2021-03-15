let capitalizeFirstLetter: string => string = %raw(`function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}`)

let distinctStrings: array<string> => array<string> = %raw("function(arr) {
return [...(new Set(arr))]
}")

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
