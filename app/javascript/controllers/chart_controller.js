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
  return {
    green:  { bar: mild,     barAlpha: toRgba(mild,     0.85) },
    yellow: { bar: moderate, barAlpha: toRgba(moderate, 0.85) },
    red:    { bar: severe,   barAlpha: toRgba(severe,   0.85) },
    none:   { bar: "#94a3b8", barAlpha: "rgba(148, 163, 184, 0.85)" }
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

export default class extends Controller {
  static values = {
    type: String,
    data: Array,
    personalBest: Number,
    healthEvents: Array
  }

  connect() {
    if (!this.typeValue || !this.dataValue?.length) return

    if (this.typeValue === "symptoms") {
      this.renderSymptomsChart()
    } else if (this.typeValue === "peakflow") {
      this.renderPeakFlowChart()
    } else if (this.typeValue === "peakflow-zones") {
      this.renderPeakFlowZonesChart()
    } else if (this.typeValue === "peakflow-bands") {
      this.renderPeakFlowBandsChart()
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
    this.element.parentElement?.querySelectorAll(".chart-event-badge").forEach(el => el.remove())
  }

  // Stacked bar chart — symptoms by severity per day
  renderSymptomsChart() {
    const data   = this.dataValue
    const labels = data.map(d => toDayLabel(d.date))
    const zc     = zoneColors()

    this.chart = new Chart(this.element, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Mild",     data: data.map(d => d.mild     || 0), backgroundColor: zc.green.barAlpha,  borderColor: zc.green.bar,  borderWidth: 1.5 },
          { label: "Moderate", data: data.map(d => d.moderate || 0), backgroundColor: zc.yellow.barAlpha, borderColor: zc.yellow.bar, borderWidth: 1.5 },
          { label: "Severe",   data: data.map(d => d.severe   || 0), backgroundColor: zc.red.barAlpha,    borderColor: zc.red.bar,    borderWidth: 1.5 }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: "bottom",
            labels: { boxWidth: 12, padding: 16, font: { size: 12 } }
          }
        },
        scales: {
          x: { stacked: true, grid: { display: false }, ticks: { font: { size: 12 } } },
          y: { stacked: true, beginAtZero: true, ticks: { stepSize: 1, font: { size: 12 } }, grid: { color: "rgba(0,0,0,0.05)" } }
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

    this.chart = new Chart(this.element, {
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

  // Line chart with filled zone bands behind it — dashboard 7-day view.
  // Three filled datasets (red/yellow/green bands) sit beneath the readings line.
  // Avoids the annotation plugin — uses chart.js native fill between datasets.
  renderPeakFlowBandsChart() {
    const data   = this.dataValue
    const pb     = this.personalBestValue || 0
    const labels = data.map(d => toDayLabel(d.date))
    const values = data.map(d => d.value)
    const zc     = zoneColors()

    // Zone thresholds derived from personal best
    const redTop    = pb > 0 ? Math.round(pb * 0.5)  : null
    const yellowTop = pb > 0 ? Math.round(pb * 0.8)  : null
    const ceiling   = pb > 0 ? Math.max(Math.round(pb * 1.3), Math.max(...values) + 60) : null

    // Point colour per reading based on zone
    const pointColors = data.map(d => (zc[d.zone] || zc.none).bar)

    const datasets = []

    if (pb > 0) {
      // Red band: from y=0 up to 50% PB
      datasets.push({
        data:            labels.map(() => redTop),
        fill:            "origin",
        backgroundColor: "rgba(220, 38, 38, 0.08)",
        borderWidth:     0,
        pointRadius:     0,
        tension:         0
      })
      // Yellow band: from redTop up to 80% PB
      datasets.push({
        data:            labels.map(() => yellowTop),
        fill:            "-1",
        backgroundColor: "rgba(217, 119, 6, 0.08)",
        borderWidth:     0,
        pointRadius:     0,
        tension:         0
      })
      // Green band: from yellowTop up to ceiling
      datasets.push({
        data:            labels.map(() => ceiling),
        fill:            "-1",
        backgroundColor: "rgba(22, 163, 74, 0.08)",
        borderWidth:     0,
        pointRadius:     0,
        tension:         0
      })
    }

    // Readings line — always the last dataset
    const lineDatasetIndex = datasets.length
    datasets.push({
      label:               "Peak Flow (L/min)",
      data:                values,
      borderColor:         cssVar("--teal-600"),
      backgroundColor:     "transparent",
      pointBackgroundColor: pb > 0 ? pointColors : cssVar("--teal-600"),
      pointBorderColor:    pb > 0 ? pointColors : cssVar("--teal-600"),
      pointRadius:         4,
      pointHoverRadius:    6,
      tension:             0.3,
      fill:                false,
      borderWidth:         2
    })

    const minValue = Math.min(...values)
    const yMin     = pb > 0 ? 0 : Math.max(0, Math.floor(minValue * 0.85 / 50) * 50)
    const yMax     = pb > 0 ? ceiling : undefined

    const healthEvents = this.healthEventsValue || []

    // Build a lookup from date string ("YYYY-MM-DD") to chart x-axis label ("Day D")
    // so we can map event dates to x positions on the chart.
    const dateLabelMap = {}
    data.forEach(d => { dateLabelMap[d.date] = toDayLabel(d.date) })

    const markerPlugin = {
      id: "healthEventMarkers",
      afterDraw(chart) {
        if (!healthEvents.length) return

        const ctx    = chart.ctx
        const xAxis  = chart.scales.x
        const yAxis  = chart.scales.y
        const top    = yAxis.top
        const bottom = yAxis.bottom

        healthEvents.forEach(event => {
          const label = dateLabelMap[event.date]
          if (!label) return  // event date not in current chart window

          const xPos = xAxis.getPixelForValue(label)
          if (xPos === undefined || isNaN(xPos)) return

          const color = eventMarkerColor(event.css_modifier)

          ctx.save()

          // Vertical dashed line only — label is rendered as a DOM badge
          ctx.beginPath()
          ctx.setLineDash([4, 3])
          ctx.strokeStyle = color
          ctx.lineWidth   = 1.5
          ctx.globalAlpha = 0.75
          ctx.moveTo(xPos, top)
          ctx.lineTo(xPos, bottom)
          ctx.stroke()

          ctx.restore()
        })
      }
    }

    this.chart = new Chart(this.element, {
      type: "line",
      data: { labels, datasets },
      plugins: [markerPlugin],
      options: {
        responsive: true,
        onResize: () => { this.positionEventBadges() },
        plugins: {
          legend: { display: false },
          tooltip: {
            filter: item => item.datasetIndex === lineDatasetIndex,
            callbacks: { label: ctx => `${ctx.raw} L/min` }
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
    const wrapper      = this.element.parentElement

    // Clear stale badges before (re)positioning
    wrapper.querySelectorAll(".chart-event-badge").forEach(el => el.remove())
    if (!healthEvents.length) return

    const canvas   = this.element
    const xAxis    = this.chart.scales.x
    const chartTop = this.chart.chartArea.top

    // chartTop is in canvas device-pixel coordinates; convert to CSS pixels
    const cssChartTop = (chartTop / canvas.height) * canvas.offsetHeight

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
      badge.style.top             = `${cssChartTop + 8}px`
      badge.style.backgroundColor = eventMarkerColor(event.css_modifier)

      wrapper.appendChild(badge)
    })
  }

  // Bar chart — each bar coloured by zone (dashboard 7-day + history page)
  renderPeakFlowZonesChart() {
    const data         = this.dataValue
    const labels       = data.map(d => toDayLabel(d.date))
    const zc           = zoneColors()
    const barColors    = data.map(d => (zc[d.zone] || zc.none).barAlpha)
    const borderColors = data.map(d => (zc[d.zone] || zc.none).bar)

    // Set Y-axis minimum well below the lowest value so every bar has visible height.
    // Without this, Chart.js can set the floor exactly at the minimum data value,
    // making the shortest bar render with zero height.
    const minValue = Math.min(...data.map(d => d.value))
    const yMin = Math.max(0, Math.floor(minValue * 0.85 / 50) * 50)

    this.chart = new Chart(this.element, {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            label:            "Peak Flow (L/min)",
            data:             data.map(d => d.value),
            backgroundColor:  barColors,
            borderColor:      borderColors,
            borderWidth:      2,
            borderRadius:     4,
            borderSkipped:    false
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: ctx => `${ctx.raw} L/min`
            }
          }
        },
        scales: {
          y: {
            min:   yMin,
            ticks: { callback: v => `${v}` },
            grid:  { color: "rgba(0,0,0,0.05)" }
          },
          x: { grid: { display: false } }
        }
      }
    })
  }
}
