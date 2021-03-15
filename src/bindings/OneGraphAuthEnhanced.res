include OneGraphAuth

type service =
  | Egghead
  | GitHub

let stringOfService = service =>
  switch service {
  | Egghead => "eggheadio"
  | GitHub => "github"
  }
