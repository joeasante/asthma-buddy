# Phase 14: Adherence Dashboard — Context

## Decisions (Locked)

- **Adherence logic**: Service object at `app/services/adherence_calculator.rb`. Given a medication and a date, returns `{taken: N, scheduled: N, status: :on_track | :missed | :no_schedule}`. Clean separation, easy to test.
- **History URL**: Top-level route `GET /adherence` with a dedicated `AdherenceController`. Linked from the dashboard adherence section. No nesting under dashboard.
- **Day toggle**: URL param `?days=30` (defaults to 7). Two link_to buttons with active state styling. Bookmarkable, simple controller param.

## Claude's Discretion

- Dashboard adherence card visual design (colour, layout of "N / N taken")
- Exact grid cell styling for the 7/30-day calendar (CSS grid vs. table)
- Turbo Frame usage within the page (if any)

## Deferred Ideas

- Push notifications for missed doses
- Per-medication adherence stats (streak, percentage)
- Adherence export / reporting
