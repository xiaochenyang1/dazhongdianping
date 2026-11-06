/** Start a browser attachment download; this does not certify that the user saved it. */
export function saveDownload(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  try {
    anchor.href = url
    anchor.download = fileName
    document.body.appendChild(anchor)
    anchor.click()
  } finally {
    anchor.remove()
    // Allow the browser to consume the URL before revoking it.
    window.setTimeout(() => URL.revokeObjectURL(url), 1000)
  }
}
