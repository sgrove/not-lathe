type category = Connections

type videoTutorialLink = {
  title: string,
  oneLineDescription: string,
  link: string,
  category: category,
}

let shortConnectionTutorial = {
  title: "Basic Connections Example",
  link: "https://www.youtube.com/watch?v=p23PbQ-6uqM",
  oneLineDescription: "Hold on option/alt and the click to drag to connect one block to another ",
  category: Connections,
}

let scriptConnectionTutorial = {
  title: "Script Connections Example",
  link: "https://youtu.be/WLYCOQpaYeA?t=78",
  oneLineDescription: "Option-drag a block into your script function to create a new variable",
  category: Connections,
}

let videoTutorials = [shortConnectionTutorial, scriptConnectionTutorial]
