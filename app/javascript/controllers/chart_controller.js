import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

// Read zone colours from CSS custom properties so charts always match the rest of the UI.
function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}

function toRgba(hex, alpha) {
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

function zoneColors() {
  const mild     = cssVar("--severity-mild")
  const moderate = cssVar("--severity-moderate")
  const severe   = cssVar("--severity-severe")
  const mildBg   = cssVar("--severity-mild-bg")
  const modBg    = cssVar("--severity-moderate-bg")
  const sevBg    = cssVar("--severity-severe-bg")
  return {
    green:  { bar: mild,      bg: mildBg, bandFill: toRgba(mildBg, 0.7) },
    yellow: { bar: moderate,  bg: modBg,  bandFill: toRgba(modBg,  0.7) },
    red:    { bar: severe,    bg: sevBg,  bandFill: toRgba(sevBg,  0.7) },
    none:   { bar: "#94a3b8", bg: "#f1f5f9", bandFill: "rgba(241,245,249,0.7)" }
  }
}

// Convert an ISO date string (YYYY-MM-DD) to "Day D" format (e.g. "Sat 7", "Sun 8").
// Uses noon UTC to avoid timezone boundary issues.
// Including the day-of-month makes every bar uniquely identifiable across multi-week views.
function toDayLabel(dateStr) {
  const d = new Date(dateStr + "T12:00:00Z")
  const weekday = d.toLocaleDateString("en-GB", { weekday: "short" })
  const day     = d.getUTCDate()
  return `${weekday} ${day}`
}

// Returns a stroke colour for a health event marker by its css_modifier.
// Uses hardcoded fallbacks — event colours are not in CSS vars.
function eventMarkerColor(cssModifier) {
  const map = {
    "hospital-visit":    "#dc2626",  // red
    "gp-appointment":    "#2563eb",  // blue
    "illness":           "#d97706",  // amber
    "medication-change": "#7c3aed",  // purple
    "other":             "#64748b"   // slate
  }
  return map[cssModifier] || "#64748b"
}

// Build a Chart.js inline plugin that draws illness shaded bands (beforeDraw)
// and vertical dashed lines (afterDraw) for all health event types.
function buildMarkerPlugin(healthEvents, dateLabelMap) {
  return {
    id: "healthEventMarkers",

    beforeDraw(chart) {
      const bandEvents = healthEvents.filter(e => !["gp_appointment", "medication_change"].includes(e.type) && e.end_date)
      if (!bandEvents.length) return

      const ctx   = chart.ctx
      const xAxis = chart.scales.x
      const yAxis = chart.scales.y

      bandEvents.forEach(event => {
        const startLabel = dateLabelMap[event.date]
        const endLabel   = dateLabelMap[event.end_date]
        if (!startLabel && !endLabel) return

        const xStart = startLabel ? xAxis.getPixelForValue(startLabel) : xAxis.left
        const xEnd   = endLabel   ? xAxis.getPixelForValue(endLabel)   : xAxis.right
        if (isNaN(xStart) || isNaN(xEnd)) return

        const halfTick = xAxis.ticks.length > 1
          ? (xAxis.right - xAxis.left) / (xAxis.ticks.length * 2)
          : 0

        ctx.save()
        ctx.fillStyle = "rgba(217, 119, 6, 0.10)"
        ctx.fillRect(xStart - halfTick, yAxis.top, (xEnd + halfTick) - (xStart - halfTick), yAxis.bottom - yAxis.top)
        ctx.restore()
      })
    },

    afterDraw(chart) {
      if (!healthEvents.length) return

      const ctx   = chart.ctx
      const xAxis = chart.scales.x
      const yAxis = chart.scales.y

      healthEvents.forEach(event => {
        const label = dateLabelMap[event.date]
        if (!label) return

        const xPos = xAxis.getPixelForValue(label)
        if (xPos === undefined || isNaN(xPos)) return

        const color = eventMarkerColor(event.css_modifier)
        ctx.save()
        ctx.beginPath()
        ctx.setLineDash([4, 3])
        ctx.strokeStyle = color
        ctx.lineWidth   = 1.5
        ctx.globalAlpha = 0.75
        ctx.moveTo(xPos, yAxis.top)
        ctx.lineTo(xPos, yAxis.bottom)
        ctx.stroke()
        ctx.restore()
      })
    }
  }
}

// Draw a horizontal dashed reference line at the personal best value.
// Renders a small "PB NNN" label at the right edge, above the line.
function buildPBLinePlugin(pb) {
  return {
    id: "pbLine",
    afterDraw(chart) {
      if (!pb || pb <= 0) return

      const ctx   = chart.ctx
      const xAxis = chart.scales.x
      const yAxis = chart.scales.y
      const y     = yAxis.getPixelForValue(pb)

      // Skip if the PB sits outside the visible chart area
      if (isNaN(y) || y < yAxis.top || y > yAxis.bottom) return

      ctx.save()

      // Dashed line spanning the full chart width
      ctx.beginPath()
      ctx.setLineDash([4, 3])
      ctx.strokeStyle = "rgba(100, 116, 139, 0.65)"
      ctx.lineWidth   = 1.5
      ctx.moveTo(xAxis.left, y)
      ctx.lineTo(xAxis.right, y)
      ctx.stroke()

      // Label: "PB NNN" just above the right end of the line
      ctx.setLineDash([])
      ctx.font         = "600 10px system-ui, -apple-system, sans-serif"
      ctx.fillStyle    = "rgba(71, 85, 105, 0.9)"
      ctx.textAlign    = "right"
      ctx.textBaseline = "bottom"
      ctx.fillText(`PB ${pb}`, xAxis.right, y - 3)

      ctx.restore()
    }
  }
}

export default class extends Controller {
  static values = {
    type: String,
    data: Array,
    personalBest: Number,
    healthEvents: Array
  }

  static targets = ["sessionBtn"]

  connect() {
    // Controller may live on a wrapper div or directly on the canvas.
    this.canvasEl = this.element.tagName === "CANVAS"
      ? this.element
      : this.element.querySelector("canvas")

    if (!this.typeValue || !this.dataValue?.length) return

    if (this.typeValue === "symptoms") {
      this.renderSymptomsChart()
    } else if (this.typeValue === "peakflow") {
      this.renderPeakFlowChart()
    } else if (this.typeValue === "peakflow-bands") {
      this.renderPeakFlowBandsChart()
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
    this.canvasEl?.parentElement?.querySelectorAll(".chart-event-badge").forEach(el => el.remove())
  }

  // Independent toggle: each pill controls its own series.
  // At least one series must remain visible — toggling the last active one is a no-op.
  toggleSeries({ params: { series } }) {
    if (!this.chart) return

    const clickedIndex = series === "morning" ? this.morningIndex : this.eveningIndex
    const otherIndex   = series === "morning" ? this.eveningIndex : this.morningIndex

    const clickedOn = this.chart.isDatasetVisible(clickedIndex)
    const otherOn   = this.chart.isDatasetVisible(otherIndex)

    // Prevent hiding the last visible series
    if (clickedOn && !otherOn) return

    if (clickedOn) {
      this.chart.hide(clickedIndex)
    } else {
      this.chart.show(clickedIndex)
    }

    this.syncSessionButtons()
  }

  // Keep aria-pressed on session buttons in sync with dataset visibility.
  syncSessionButtons() {
    if (!this.hasSessionBtnTarget) return
    this.sessionBtnTargets.forEach(btn => {
      const series  = btn.dataset.chartSeriesParam
      const index   = series === "morning" ? this.morningIndex : this.eveningIndex
      const visible = this.chart.isDatasetVisible(index)
      btn.setAttribute("aria-pressed", visible ? "true" : "false")
    })
  }

  // Bubble chart — each severity level is a horizontal swim lane.
  // x = date index, y = severity row (0 Mild / 1 Moderate / 2 Severe),
  // r scales with the day's count so denser days show a larger dot.
  renderSymptomsChart() {
    const data   = this.dataValue
    const labels = data.map(d => toDayLabel(d.date))
    const zc     = zoneColors()

    const rows = [
      { key: "mild",     y: 0, bg: zc.green.bg,  border: zc.green.bar  },
      { key: "moderate", y: 1, bg: zc.yellow.bg, border: zc.yellow.bar },
      { key: "severe",   y: 2, bg: zc.red.bg,    border: zc.red.bar    }
    ]

    const datasets = rows.map(({ key, y, bg, border }) => ({
      label:           key.charAt(0).toUpperCase() + key.slice(1),
      data:            data.reduce((acc, d, i) => {
        const count = d[key] || 0
        if (count > 0) acc.push({ x: i, y, r: Math.min(5 + count * 2, 14), count })
        return acc
      }, []),
      backgroundColor: bg,
      borderColor:     border,
      borderWidth:     1.5
    }))

    const yLabels = ["Mild", "Moderate", "Severe"]

    this.chart = new Chart(this.canvasEl, {
      type: "bubble",
      data: { datasets },
      options: {
        responsive: true,
        layout: { padding: { top: 4, bottom: 4 } },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: ctx => labels[ctx[0].raw.x] || "",
              label: ctx => {
                const { count } = ctx.raw
                return `${ctx.dataset.label}: ${count} log${count !== 1 ? "s" : ""}`
              }
            }
          }
        },
        scales: {
          x: {
            type:  "linear",
            min:   -0.5,
            max:   labels.length - 0.5,
            grid:  { display: false },
            ticks: {
              stepSize: 1,
              font:     { size: 12 },
              maxTicksLimit: 14,
              callback: val => Number.isInteger(val) ? (labels[val] || "") : ""
            }
          },
          y: {
            min:   -0.6,
            max:   2.6,
            grid:  { color: "rgba(0,0,0,0.05)" },
            ticks: {
              stepSize: 1,
              font:     { size: 12 },
              callback: val => yLabels[val] || ""
            }
          }
        }
      }
    })
  }

  // Line chart — peak flow trend over time
  renderPeakFlowChart() {
    const data       = this.dataValue
    const labels     = data.map(d => toDayLabel(d.date))
    const zc         = zoneColors()
    const pointColors = data.map(d => (zc[d.zone] || zc.none).bar)

    this.chart = new Chart(this.canvasEl, {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            label:              "Peak Flow (L/min)",
            data:               data.map(d => d.value),
            borderColor:        "#0d9488",
            backgroundColor:    "rgba(13, 148, 136, 0.08)",
            pointBackgroundColor: pointColors,
            pointBorderColor:   pointColors,
            pointRadius:        5,
            tension:            0.3,
            fill:               true
          }
        ]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: false, ticks: { callback: v => `${v}` } },
          x: { grid: { display: false } }
        }
      }
    })
  }

  // Line chart with filled zone bands — dashboard 7-day view.
  // Two lines (morning + evening) sit above three filled zone band datasets.
  // Avoids the annotation plugin — uses chart.js native fill between datasets.
  renderPeakFlowBandsChart() {
    const data   = this.dataValue
    const pb     = this.personalBestValue || 0
    const labels = data.map(d => toDayLabel(d.date))
    const zc     = zoneColors()

    // Separate morning / evening values (null when not recorded that session)
    const morningValues = data.map(d => d.morning ?? null)
    const eveningValues = data.map(d => d.evening ?? null)
    const allValues     = [...morningValues, ...eveningValues].filter(v => v !== null)
    if (!allValues.length) return

    // Zone thresholds derived from personal best
    const redTop    = pb > 0 ? Math.round(pb * 0.5) : null
    const yellowTop = pb > 0 ? Math.round(pb * 0.8) : null
    const ceiling   = pb > 0 ? Math.max(Math.round(pb * 1.3), Math.max(...allValues) + 60) : null

    // Point colours based on zone of each reading
    const morningColors = data.map(d => (zc[d.morning_zone] || zc.none).bar)
    const eveningColors = data.map(d => (zc[d.evening_zone] || zc.none).bar)

    const eveningColor = cssVar("--teal-600") || "#0d9488"

    const datasets = []

    if (pb > 0) {
      // Red band: from y=0 up to 50% PB
      datasets.push({
        data:            labels.map(() => redTop),
        fill:            "origin",
        backgroundColor: zc.red.bandFill,
        borderWidth:     0,
        pointRadius:     0,
        tension:         0
      })
      // Yellow band: from redTop up to 80% PB
      datasets.push({
        data:            labels.map(() => yellowTop),
        fill:            "-1",
        backgroundColor: zc.yellow.bandFill,
        borderWidth:     0,
        pointRadius:     0,
        tension:         0
      })
      // Green band: from yellowTop up to ceiling
      datasets.push({
        data:            labels.map(() => ceiling),
        fill:            "-1",
        backgroundColor: zc.green.bandFill,
        borderWidth:     0,
        pointRadius:     0,
        tension:         0
      })
    }

    // Morning line
    this.morningIndex = datasets.length
    datasets.push({
      label:                "Morning",
      data:                 morningValues,
      borderColor:          "#f59e0b",
      backgroundColor:      "#f59e0b",
      pointBackgroundColor: pb > 0 ? morningColors : "#f59e0b",
      pointBorderColor:     pb > 0 ? morningColors : "#f59e0b",
      pointRadius:          4,
      pointHoverRadius:     6,
      tension:              0.3,
      fill:                 false,
      borderWidth:          2,
      spanGaps:             false
    })

    // Evening line
    this.eveningIndex = datasets.length
    datasets.push({
      label:                "Evening",
      data:                 eveningValues,
      borderColor:          eveningColor,
      backgroundColor:      eveningColor,
      pointBackgroundColor: pb > 0 ? eveningColors : eveningColor,
      pointBorderColor:     pb > 0 ? eveningColors : eveningColor,
      pointRadius:          4,
      pointHoverRadius:     6,
      tension:              0.3,
      fill:                 false,
      borderWidth:          2,
      spanGaps:             false
    })

    const minValue = Math.min(...allValues)
    const yMin     = pb > 0 ? 0 : Math.max(0, Math.floor(minValue * 0.85 / 50) * 50)
    const yMax     = pb > 0 ? ceiling : undefined

    const healthEvents = this.healthEventsValue || []

    // Build a lookup from date string ("YYYY-MM-DD") to chart x-axis label ("Day D")
    // so we can map event dates to x positions on the chart.
    const dateLabelMap = {}
    data.forEach(d => { dateLabelMap[d.date] = toDayLabel(d.date) })

    const markerPlugin = buildMarkerPlugin(healthEvents, dateLabelMap)
    const pbPlugin     = buildPBLinePlugin(pb)

    this.chart = new Chart(this.canvasEl, {
      type: "line",
      data: { labels, datasets },
      plugins: [markerPlugin, pbPlugin],
      options: {
        responsive: true,
        onResize: () => { this.positionEventBadges() },
        layout: {
          // Reserve space above the chart area for event badge labels.
          padding: { top: healthEvents.length ? 26 : 4 }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            filter:    item => item.datasetIndex === this.morningIndex || item.datasetIndex === this.eveningIndex,
            callbacks: { label: ctx => `${ctx.dataset.label}: ${ctx.raw} L/min` }
          }
        },
        scales: {
          y: {
            min:   yMin,
            max:   yMax,
            ticks: { callback: v => `${v}`, font: { size: 12 } },
            grid:  { color: "rgba(0,0,0,0.05)" }
          },
          x: {
            grid:  { display: false },
            ticks: { font: { size: 12 } }
          }
        }
      }
    })

    this.positionEventBadges()
  }

  // Render health event labels as DOM badges positioned over the canvas.
  // DOM text is anti-aliased and styleable; canvas fillText at small sizes is blurry.
  // Called after chart creation and on every resize to keep positions in sync.
  positionEventBadges() {
    if (!this.chart) return

    const healthEvents = this.healthEventsValue || []
    const wrapper      = this.canvasEl.parentElement

    // Clear stale badges before (re)positioning
    wrapper.querySelectorAll(".chart-event-badge").forEach(el => el.remove())
    if (!healthEvents.length) return

    const canvas = this.canvasEl
    const xAxis  = this.chart.scales.x

    // Build date → axis label lookup
    const dateLabelMap = {}
    this.dataValue.forEach(d => { dateLabelMap[d.date] = toDayLabel(d.date) })

    healthEvents.forEach(event => {
      const axisLabel = dateLabelMap[event.date]
      if (!axisLabel) return

      const xPos = xAxis.getPixelForValue(axisLabel)
      if (xPos === undefined || isNaN(xPos)) return

      // xPos is in device-pixel coordinates; express as % of CSS width so the
      // badge aligns correctly regardless of devicePixelRatio
      const leftPct = (xPos / canvas.width) * 100

      const badge = document.createElement("span")
      badge.className         = "chart-event-badge"
      badge.textContent       = event.label
      badge.setAttribute("aria-label", `Health event: ${event.label}`)
      badge.style.left            = `${leftPct}%`
      badge.style.top             = "4px"  // sits in the layout.padding.top strip, above the data area
      badge.style.backgroundColor = eventMarkerColor(event.css_modifier)

      wrapper.appendChild(badge)
    })
  }

}
