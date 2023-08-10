export function InvalidUpstreamIPv4Display(inState) {
  const status = document.getElementById('UpstreamIPv4Error')
  if ( status ) {
    if ( inState !== false ) {
      status.textContent = ''

      return null
    } else {
      status.textContent = 'Invalid IPv4 address!'

      return 'Invalid IPv4 address!'
    }
  } else {
    console.log( 'Could not get status for upstream IPv4 address error display!' )
  }

  return null
}