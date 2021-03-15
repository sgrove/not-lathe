// module Link = Next.Link

// module Navigation = {
//   @react.component
//   let make = () =>
//     <nav className="p-2 h-12 flex bg-black border-gray-200 justify-between items-center text-sm">
//       <Link href="/">
//         <a className="flex items-center w-1/3">
//           <span className="text-xl ml-2 align-middle font-semibold text-white">
//             {React.string("OneThat")}
//           </span>
//         </a>
//       </Link>
//       <div className="flex w-2/3 justify-end" />
//     </nav>
// }

@react.component
let make = (~children) => {
  let minWidth = ReactDOMRe.Style.make(~minWidth="20rem", ())
  <div style=minWidth className="flex lg:justify-center">
    <div className="w-full text-gray-900 font-base">
      // <Navigation />
      <main className=""> children </main>
    </div>
  </div>
}
