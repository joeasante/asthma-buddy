// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "lexxy"

// Re-assert favicon after every Turbo navigation.
// Turbo's head merge can briefly drop <link rel="icon"> tags, causing
// browsers to revert to a cached or default favicon.
document.addEventListener("turbo:render", () => {
  const icons = [
    { rel: "icon", href: "/icon.png?v=2", type: "image/png" },
    { rel: "icon", href: "/icon.svg?v=2", type: "image/svg+xml" },
    { rel: "apple-touch-icon", href: "/icon.png?v=2" }
  ]
  icons.forEach(({ rel, href, type }) => {
    if (!document.querySelector(`link[href="${href}"]`)) {
      const link = document.createElement("link")
      link.rel = rel
      link.href = href
      if (type) link.type = type
      document.head.appendChild(link)
    }
  })
})
