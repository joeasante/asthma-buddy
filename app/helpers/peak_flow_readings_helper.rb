# frozen_string_literal: true

module PeakFlowReadingsHelper
  # Returns an HTML-safe flash message with a coloured zone badge (for Turbo Stream responses).
  # Uses content_tag so arguments are individually escaped — safe even if zone values ever change.
  def zone_flash_message(reading)
    return "Reading saved \u2014 set your personal best to see your zone." if reading.zone.nil?

    label = content_tag(:span,
                        "#{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)",
                        class: "zone-label zone-label--#{reading.zone}")
    safe_join([ "Reading saved \u2014 ", label, "." ])
  end

  # Returns a plain-text flash message (for HTML redirect notices, which are stored in the session
  # as strings and lose html_safe marking across requests).
  def zone_flash_message_text(reading)
    return "Reading saved \u2014 set your personal best to see your zone." if reading.zone.nil?

    "Reading saved \u2014 #{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)."
  end
end
