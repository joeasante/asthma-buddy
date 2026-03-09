---
title: "Chart.js bar chart invisible bar due to Y-axis floor auto-scaling"
date: "2026-03-08"
category: "ui-bugs"
tags: ["chart.js", "data-visualization", "peak-flow", "stimulus", "rails"]
symptoms:
  - "A peak flow bar (520 L/min) is completely invisible on the chart while another bar (550 L/min) renders correctly"
  - "Multiple readings on the same day produce overlapping bars — taller bars hide shorter ones"
  - "Switching from ISO date strings to short day names causes duplicate x-axis labels across multi-week views"
affected_files:
  - "app/javascript/controllers/chart_controller.js"
  - "app/controllers/dashboard_controller.rb"
  - "app/controllers/peak_flow_readings_controller.rb"
  - "app/assets/stylesheets/charts.css"
severity: "high"
related_docs:
  - "docs/solutions/ui-bugs/turbo-hotwire-dom-targeting-and-frame-rendering.md"
---

# Chart.js bar chart invisible bar due to Y-axis floor auto-scaling

## Symptoms

- A specific peak flow reading (520 L/min, logged 07/03/2026 at 14:12) was **completely invisible** on both the dashboard and history page bar charts. Another reading (550 L/min, 08/03/2026) displayed correctly.
- Confirmed via `rails runner` that both readings were present in the database and correctly included in the JSON passed to the chart.
- The chart rendered without errors — the bar existed but had zero pixel height.

## Root Cause

Three compounding issues:

### 1. Y-axis floor set exactly at minimum data value (primary bug)

`charts.css` constrains the canvas to `max-height: 200px`. With `beginAtZero: false`, Chart.js auto-scales the Y-axis and sets the floor at the **exact minimum data value** in the dataset. When the lowest reading is 520 L/min and the axis floor is 520, the bar for that reading spans from 520 to 520 — zero pixels tall. It renders on the canvas but is invisible.

The 550 bar was visible because it was 30 units above the floor.

### 2. Multiple readings per day produce overlapping bars

When multiple readings exist on the same date, Chart.js plots each as a separate bar with an identical x-axis label. The bars stack at the same horizontal position — the tallest bar renders on top, covering shorter bars completely.

### 3. Short day names produce duplicate x-axis labels in multi-week views

Switching from ISO date strings (`"2026-03-07"`) to short weekday names (`"Sat"`) means any 30-day view contains 4+ identical `"Sat"` labels. Chart.js treats identical labels as the same category, causing bar misalignment and visual confusion.

## Investigation Steps

1. Ran `rails runner` to confirm both readings (520 and 550) were in the database for the correct user — ✅ both present
2. Confirmed `in_date_range` scope included March 7 in the query window — ✅ correct
3. Confirmed the JSON passed to the `data-chart-data-value` attribute contained both readings — ✅ correct
4. Inspected `charts.css` — found `max-height: 200px` on `.chart-canvas`
5. Traced Chart.js behaviour with `beginAtZero: false` + constrained canvas height — identified zero-height bar as root cause

## Solution

### Fix 1 — Explicit Y-axis minimum with buffer (`chart_controller.js`)

```javascript
// Bar chart — each bar coloured by zone (dashboard 7-day + history page)
renderPeakFlowZonesChart() {
  const data = this.dataValue

  // Set Y-axis minimum well below the lowest value so every bar has visible height.
  // Without this, Chart.js sets the floor exactly at the minimum data value,
  // making the shortest bar render with zero pixel height.
  const minValue = Math.min(...data.map(d => d.value))
  const yMin = Math.max(0, Math.floor(minValue * 0.85 / 50) * 50)

  this.chart = new Chart(this.element, {
    // ...
    options: {
      scales: {
        y: {
          min: yMin,   // ← replaces `beginAtZero: false`
          ticks: { callback: v => `${v}` },
          grid:  { color: "rgba(0,0,0,0.05)" }
        }
      }
    }
  })
}
```

**How `yMin` is calculated:**
- Take 85% of the minimum data value → creates 15% breathing room
- Round down to the nearest 50 → gives a clean axis label
- Clamp to 0 → never negative for physiological data
- Example: min=520 → 520 × 0.85 = 442 → floor to nearest 50 = **400**
- Both the 520 bar (height 120 units) and 550 bar (height 150 units) are now clearly visible

### Fix 2 — Aggregate chart data to one bar per day, server-side

Applied to both `dashboard_controller.rb` and `peak_flow_readings_controller.rb`:

```ruby
@chart_data = base_relation
  .reorder(recorded_at: :asc)
  .limit(500)
  .pluck(:recorded_at, :value, :zone)
  .map { |ts, v, z| { date: ts.to_date.to_s, value: v, zone: z } }
  .group_by { |d| d[:date] }
  .map { |_date, readings| readings.max_by { |r| r[:value] } }  # best reading per day
  .sort_by { |d| d[:date] }
```

Shows the **daily best (maximum) reading** — the clinically relevant metric for peak flow monitoring. Individual readings remain visible in the reading rows below the chart.

### Fix 3 — Compound day labels: "Sat 7" not "Sat" (`chart_controller.js`)

```javascript
// Uses noon UTC to avoid timezone boundary issues.
// Day-of-month included so labels are unique across multi-week views.
function toDayLabel(dateStr) {
  const d = new Date(dateStr + "T12:00:00Z")
  const weekday = d.toLocaleDateString("en-GB", { weekday: "short" })
  const day = d.getUTCDate()
  return `${weekday} ${day}`
}
```

Result: `"Sat 7"`, `"Sat 14"`, `"Sat 21"` — unambiguous across any date range.

## Prevention

### Rules for Chart.js bar charts in this codebase

1. **Never use `beginAtZero: false` alone.** Always pair with an explicit `min` computed from the data. Comment why.
2. **Aggregate to one data point per x-axis label server-side.** Do not let Chart.js receive multiple data points for the same label — it will overlap them silently.
3. **Use compound date labels for any view spanning more than 7 days.** Bare weekday names (`"Mon"`, `"Sat"`) are ambiguous beyond one week. Use `"Mon 2"`, `"Sat 7"` format.
4. **Always implement `disconnect()` calling `chart.destroy()`.** Prevents memory leaks and stale state on Turbo navigations.
5. **Stacked bar charts must use `beginAtZero: true`.** The symptoms chart is correct — never remove this.

### Chart.js gotchas

| Gotcha | Impact | Mitigation |
|--------|--------|-----------|
| `beginAtZero: false` sets floor at `min(data)` | Shortest bar → zero height → invisible | Always set explicit `min` with buffer |
| Multiple points per label overlap silently | Taller bars obscure shorter ones | Aggregate at the data layer |
| Short day names repeat in multi-week views | Bars misaligned, ambiguous | Use "Day DD" compound format |
| Missing `chart.destroy()` on disconnect | Memory leaks, stale Turbo renders | Always destroy in `disconnect()` |
| `borderSkipped: false` on all 4 sides | Can look cluttered with many bars | Intentional here for visual definition; document if changed |

### Y-axis buffer reference table

| Min reading (L/min) | `yMin` produced |
|---------------------|----------------|
| 50                  | 0              |
| 150                 | 100            |
| 300                 | 250            |
| 400                 | 300            |
| 520                 | 400            |
| 600                 | 500            |
| 750                 | 600            |
| 900                 | 750            |

### Code review checklist for new Chart.js charts

- [ ] Bar chart has explicit `min` set from data — not `beginAtZero: false` alone
- [ ] Data aggregated to one point per label before passing to chart
- [ ] Date labels include day-of-month if view spans more than 7 days
- [ ] `disconnect()` calls `chart.destroy()`
- [ ] Stacked charts use `beginAtZero: true`
- [ ] Non-obvious config settings have inline comments explaining why

## Test Cases

```ruby
# test/models/peak_flow_reading_test.rb

test "chart aggregation picks highest reading when multiple exist on same day" do
  user = users(:verified_user)
  date = 1.day.ago.beginning_of_day
  r1 = PeakFlowReading.create!(user: user, value: 450, recorded_at: date + 8.hours)
  r2 = PeakFlowReading.create!(user: user, value: 520, recorded_at: date + 12.hours)
  r3 = PeakFlowReading.create!(user: user, value: 480, recorded_at: date + 16.hours)

  chart_data = [r1, r2, r3]
    .map { |r| { date: r.recorded_at.to_date.to_s, value: r.value } }
    .group_by { |d| d[:date] }
    .map { |_date, readings| readings.max_by { |r| r[:value] } }

  assert_equal 1, chart_data.length
  assert_equal 520, chart_data.first[:value]
end

test "yMin calculation is always strictly below minimum data value" do
  [50, 150, 300, 520, 750, 900].each do |min_val|
    y_min = [0, (min_val * 0.85 / 50).floor * 50].max
    assert y_min < min_val, "yMin=#{y_min} must be < min_val=#{min_val}"
  end
end

test "yMin for 520 L/min is 400" do
  y_min = [0, (520 * 0.85 / 50).floor * 50].max
  assert_equal 400, y_min
end
```
