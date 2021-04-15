let useLeadingDebounce = (value, delay) => {
  open React
  // State and setters for debounced value
  let (debouncedValue, setDebouncedValue) = useState(() => value)
  let (afterSleep, setAfterSleep) = useState(() => true)

  useEffect2(() => {
    let shouldInvoke = afterSleep

    switch shouldInvoke {
    | false => ()
    | true =>
      setDebouncedValue(_ => value)
      setAfterSleep(_ => false)
    }

    // Update debounced value after delay
    let handler = Js.Global.setTimeout(() => {
      setDebouncedValue(_ => value)
      setAfterSleep(_ => true)
    }, delay)
    // Cancel the timeout if value changes (also on delay change or unmount)
    // This is how we prevent debounced value from updating if value is changed ...
    // .. within the delay period. Timeout gets cleared and restarted.
    Some(
      () => {
        Js.Global.clearTimeout(handler)
      },
    )
  }, (value, delay)) // Only re-call effect if value or delay changes

  debouncedValue
}
