# frozen_string_literal: true

class NormalizeDoubleEncodedTriggers < ActiveRecord::Migration[8.1]
  def up
    # A previous after_initialize bug caused triggers to be double-encoded:
    # the raw DB string "[]" was passed through JSON.dump again → '"[]"'.
    # This migration finds those rows and normalises them to single-encoded JSON.
    #
    # Post-deploy verification queries:
    #   SELECT COUNT(*) FROM symptom_logs WHERE triggers LIKE '"%';
    #   -- Expected: 0 (no double-encoded strings remain)
    #
    #   SELECT triggers, COUNT(*) FROM symptom_logs
    #   WHERE triggers IS NOT NULL AND triggers != '[]'
    #   GROUP BY triggers ORDER BY COUNT(*) DESC LIMIT 20;
    #   -- Inspect for unexpected non-JSON values
    SymptomLog.where.not(triggers: nil).find_each do |log|
      raw = log.read_attribute(:triggers)
      next unless raw.is_a?(String)

      begin
        parsed = JSON.parse(raw)
        # If the first parse returns a String (not an Array), it was double-encoded.
        next if parsed.is_a?(Array)

        normalised = JSON.parse(parsed)
        normalised = [] unless normalised.is_a?(Array)
        log.update_column(:triggers, JSON.dump(normalised))
      rescue JSON::ParserError => e
        Rails.logger.warn "[NormalizeDoubleEncodedTriggers] Unparseable triggers on SymptomLog##{log.id}: #{raw.inspect} — resetting to []. Error: #{e.message}"
        log.update_column(:triggers, "[]")
      end
    end
  end

  def down
    # Not reversible — data was already corrupted; we only fix forward.
    # rake db:rollback will silently succeed without changing any data.
  end
end
