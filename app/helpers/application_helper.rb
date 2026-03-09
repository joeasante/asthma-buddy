# frozen_string_literal: true

module ApplicationHelper
  # Returns the CSS class string for a nav link, adding --active when the
  # current request path matches the given path.
  def nav_link_class(path)
    current_page?(path) ? "nav-link nav-link--active" : "nav-link"
  end

  # Returns aria-current="page" value when on the given path, nil otherwise.
  def nav_current(path)
    current_page?(path) ? "page" : nil
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
