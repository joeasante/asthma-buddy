# Phase 25: Clinical Intelligence

**Status:** Planned
**Created:** 2026-03-13
**Depends on:** Phase 24 (Admin & Observability)

---

## Goal

Turn raw tracking data into interpreted insight. Right now the app shows numbers — this phase makes those numbers mean something. Three features, each addressing a specific gap vs. clinical tracking tools (Apple Health, Dexcom Clarity, MyChart):

1. **Dashboard Intelligence** — a one-sentence interpretation of this week's data; a 2×/week reliever threshold warning; a personal best aging alert.
2. **"Prepare for Appointment" view** — a printable one-page summary of the last 30 days for GP consultations.

## Why This Matters

A person with asthma opens the app, sees "avg 430 L/min this week" and a chart — and has no idea if that's good or bad relative to their history. Every clinical tracking tool addresses this with an interpretation layer. This is the single highest-value UX addition possible without changing the data model.

The GP appointment feature addresses the other core use case: patients arrive at appointments without data. A printable summary that takes 10 seconds to generate could meaningfully change clinical conversations.

## Clinical Grounding

- **GINA guidelines** define reliever use >2×/week (excluding pre-exercise) as a marker of uncontrolled asthma. The 2×/week threshold is not invented — it is the most cited clinical threshold in asthma management and is what GPs look for.
- **Personal best decay**: peak flow personal best values change as lung function changes with age, fitness, treatment, or disease progression. A 3-year-old personal best may produce artificially low or high zone calculations. Flagging this is standard practice in peak flow management tools.
- **Trend direction** (improving/stable/worsening) is computable from two weeks of data and is far more informative than a single value.

---

## Success Criteria

1. The dashboard "This Week" section displays a one-sentence interpretation: e.g. "Your average this week is in the Yellow zone — 12% below your best. Your reliever usage is within the safe range."
2. If the user used their reliever more than twice in the current week, a callout appears on the dashboard: "You've used your reliever X times this week — above the 2×/week GINA threshold. Worth mentioning to your GP."
3. If the user's personal best was set more than 18 months ago, a non-intrusive nudge appears on the Peak Flow page: "Your personal best was set over N months ago. If your lung function has changed, updating it will keep your zone readings accurate."
4. A user can navigate to `/appointment-summary` and see a print-optimised one-page summary of the last 30 days: peak flow trend (zone-coded), symptom count by severity, reliever use frequency, active medications, and recent health events.
5. The appointment summary page has a print button and renders correctly when printed (CSS `@media print` rules applied).
6. No new database queries are introduced for features 1–3 — all data is computed from variables already loaded by `DashboardController#index`.

---

## Plans

### Plan 25-01: Dashboard Intelligence

**Goal:** Interpret this week's data with a sentence; surface the GINA 2×/week reliever threshold; flag stale personal best.

#### A. Trend Interpretation Sentence

The "This Week" section (`dash-week-section`) already shows stat cards (readings count, avg, symptoms). Add a single interpretation sentence beneath the stats:

**Logic (in `DashboardController`, no new queries):**
```ruby
@week_interpretation = build_week_interpretation(
  avg: @week_avg,
  avg_zone: @week_avg_zone,
  personal_best: @personal_best&.value,
  reading_count: @week_reading_count,
  symptom_count: @week_symptom_count
)
```

Private method `build_week_interpretation`:
- If no readings: nil (don't show sentence)
- If zone = "green" and symptom_count == 0: "Your readings are all in the Green zone and no symptoms logged this week."
- If zone = "green" and symptom_count > 0: "Your readings are in the Green zone, but you logged #{symptom_count} symptom#{"s" if symptom_count > 1} this week."
- If zone = "yellow": "Your average this week (#{avg} L/min) is in the Yellow zone — #{pct_of_best}% of your personal best."
- If zone = "red": "Your average this week (#{avg} L/min) is in the Red zone. Consider reviewing your action plan with your GP."
- If personal_best nil: "#{reading_count} reading#{"s" if reading_count > 1} this week — set your personal best to see zone classifications."

Render in `dashboard/index.html.erb` beneath the `dash-stats` div:
```erb
<% if @week_interpretation %>
  <p class="dash-interpretation"><%= @week_interpretation %></p>
<% end %>
```

CSS: `.dash-interpretation { font-size: 0.875rem; color: var(--text-2); margin-top: var(--space-sm); font-style: italic; }`

#### B. 2×/Week Reliever Threshold Warning

**Logic (in `DashboardController`):**
```ruby
# Count distinct reliever dose logging events this week
# @reliever_medications is already loaded by DashboardVariables
reliever_ids = @reliever_medications.map { |m| m[:id] }
@week_reliever_doses = reliever_ids.any? ?
  Current.user.dose_logs
    .where(medication_id: reliever_ids)
    .where(recorded_at: week_start.beginning_of_day..Date.current.end_of_day)
    .count : 0
```

Note: this is one additional query. It is scoped and indexed by `(medication_id, recorded_at)`.

In the view, add to the dashboard between the illness banner and the status hero (or as a callout within the `dash-adherence` section):
```erb
<% if @week_reliever_doses > 2 %>
  <div class="dash-gina-warning" role="alert">
    <svg ...><!-- warning icon --></svg>
    <div>
      <strong>Reliever used <%= @week_reliever_doses %> times this week</strong>
      <p>Using your reliever more than twice a week may indicate your asthma isn't fully controlled. Worth discussing with your GP.</p>
    </div>
    <%= link_to "View usage →", reliever_usage_path, class: "dash-gina-warning-link" %>
  </div>
<% end %>
```

CSS: `.dash-gina-warning` — amber `--severity-moderate` left border, `--surface` background, flex row, similar to `dash-illness-banner` pattern.

#### C. Personal Best Aging Alert

In `peak_flow_readings/index.html.erb`, add beneath the personal best hero card:
```erb
<% if @current_personal_best && @current_personal_best.recorded_at < 18.months.ago %>
  <% months = ((Date.current - @current_personal_best.recorded_at.to_date) / 30).round %>
  <div class="pf-pb-age-notice" role="note">
    Your personal best was set <%= months %> months ago.
    If your lung function has changed, <%= link_to "updating it", profile_path %> will keep your zone readings accurate.
  </div>
<% end %>
```

CSS: `.pf-pb-age-notice` — muted text, `var(--text-3)`, `font-size: 0.8125rem`, subtle top border on the hero card. Non-intrusive; does not use a warning colour since it's informational, not urgent.

**Files touched:** `app/controllers/dashboard_controller.rb`, `app/views/dashboard/index.html.erb`, `app/views/peak_flow_readings/index.html.erb`, `app/assets/stylesheets/charts.css` or `peak_flow.css`, `test/controllers/dashboard_controller_test.rb`

---

### Plan 25-02: Prepare for Appointment View

**Goal:** A print-optimised one-page summary of the last 30 days for GP consultations.

**Tasks:**

1. **Route** — `get "/appointment-summary", to: "appointment_summaries#show", as: :appointment_summary`

2. **`AppointmentSummariesController#show`**:
   ```ruby
   def show
     user = Current.user
     period_start = 30.days.ago.to_date

     @personal_best = PersonalBestRecord.current_for(user)

     @readings = user.peak_flow_readings
       .where(recorded_at: period_start.beginning_of_day..)
       .order(:recorded_at)

     @reading_count  = @readings.count
     @avg            = @readings.average(:value)&.round
     @best_in_period = @readings.maximum(:value)
     @worst_in_period = @readings.minimum(:value)

     # Zone breakdown
     @zone_counts = @readings.group(:zone).count

     # Symptom summary
     @symptom_count  = user.symptom_logs.where(recorded_at: period_start..).count
     @severity_breakdown = user.symptom_logs.where(recorded_at: period_start..).group(:severity).count

     # Reliever use
     reliever_ids = user.medications.where(medication_type: :reliever, course: false).pluck(:id)
     @reliever_doses_total = user.dose_logs.where(medication_id: reliever_ids, recorded_at: period_start..).count

     # Active medications
     @active_medications = user.medications.where(course: false).order(:name)
     @active_courses = user.medications.active_courses.order(:ends_on)

     # Health events
     @health_events = user.health_events
       .where("recorded_at >= ? OR ended_at IS NULL", period_start)
       .order(:recorded_at)
   end
   ```

3. **View `app/views/appointment_summaries/show.html.erb`**:
   - Page header: "Appointment Summary" with date range subtitle ("Last 30 days: N Feb – N Mar 2026")
   - Print button: `<button onclick="window.print()" class="btn-secondary no-print">Print / Save as PDF</button>`
   - Sections:
     1. **Peak Flow** — personal best, period avg, best/worst, zone breakdown table (Green N days / Yellow N days / Red N days)
     2. **Symptoms** — total count, breakdown by severity
     3. **Reliever Use** — total doses in period, avg per week, vs 2×/week threshold
     4. **Medications** — list of active medications with type and dose
     5. **Health Events** — table of events in period (type, date, ongoing?)
   - Footer: "Generated by Asthma Buddy on [date]. Not a medical document — for reference only."

4. **Print CSS** — add `@media print` rules to `application.css` or a dedicated `appointment_summary.css`:
   ```css
   @media print {
     .bottom-nav, .top-nav, .no-print, .footer-app { display: none !important; }
     body { font-size: 11pt; color: #000; background: #fff; }
     .section-card { box-shadow: none; border: 1px solid #ccc; }
     a { color: inherit; text-decoration: none; }
     @page { margin: 1.5cm; }
   }
   ```

5. **Settings / Dashboard link** — add "Prepare for appointment →" link on the dashboard, beneath the "This Week" section or as a nav item.

6. **Tests** — controller tests: authenticated user gets 200; response includes correct period stats; unauthenticated redirects to login; no other user's data in the response.

**Files touched:** `config/routes.rb`, `app/controllers/appointment_summaries_controller.rb`, `app/views/appointment_summaries/show.html.erb`, `app/assets/stylesheets/application.css`, `app/views/dashboard/index.html.erb`, `test/controllers/appointment_summaries_controller_test.rb`
