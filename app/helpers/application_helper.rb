# frozen_string_literal: true

module ApplicationHelper
  # True when the current request is at or within the given path.
  # Root path uses exact match to avoid matching everything.
  def nav_active?(path)
    path == root_path ? current_page?(path) : request.path.start_with?(path)
  end

  # Returns the CSS class string for a top nav link.
  def nav_link_class(path)
    nav_active?(path) ? "nav-link nav-link--active" : "nav-link"
  end

  # Returns the CSS class string for a bottom nav tab.
  def nav_tab_class(path)
    nav_active?(path) ? "bottom-nav-tab bottom-nav-tab--active" : "bottom-nav-tab"
  end

  # Returns aria-current="page" value when on the given path, nil otherwise.
  def nav_current(path)
    nav_active?(path) ? "page" : nil
  end

  # Returns a human-friendly label for a dose log timestamp.
  # Examples: "Today 8:00 AM", "Yesterday 9:00 PM", "3 Mar 10:30 AM"
  def dose_log_time_label(time)
    return "" unless time
    local = time.in_time_zone(Time.zone)
    today     = Time.zone.today
    yesterday = today - 1.day
    day_label = if local.to_date == today
      "Today"
    elsif local.to_date == yesterday
      "Yesterday"
    else
      local.strftime("%-d %b")
    end
    "#{day_label} #{local.strftime('%-I:%M %p')}"
  end
end
