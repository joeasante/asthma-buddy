// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "lexxy"

// Force favicon refresh on every Turbo navigation.
// Turbo's head merge disrupts <link rel="icon"> tags; the only reliable
// fix is to remove them all and re-add fresh on each turbo:load.
document.addEventListener("turbo:load", () => {
  document.querySelectorAll('link[rel="icon"], link[rel="apple-touch-icon"]').forEach(el => el.remove())

  const favicons = [
    { rel: "icon", href: "/favicon.ico", sizes: "any" },
    { rel: "icon", href: "/icon.svg?v=2", type: "image/svg+xml" },
    { rel: "icon", href: "/icon.png?v=2", type: "image/png" },
    { rel: "apple-touch-icon", href: "/icon.png?v=2" }
  ]
  favicons.forEach(({ rel, href, type, sizes }) => {
    const link = document.createElement("link")
    link.rel = rel
    link.href = href
    if (type) link.type = type
    if (sizes) link.sizes = sizes
    document.head.appendChild(link)
  })
})
