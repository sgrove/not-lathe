module Studio = {
  type t = {
    oneGraphAppId: string,
    persistQueryToken: string,
    chainAccessToken: option<string>,
  }
}

let isDev = false
