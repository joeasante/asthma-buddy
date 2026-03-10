# frozen_string_literal: true

# Restrict ActionText/Lexxy sanitization to prevent user-controlled CSS and
# embedded resources in medical notes.
#
# Lexxy adds "style" to allowed_attributes and "embed" to allowed_tags.
# Both open exfiltration and content-injection vectors in a health app.
# This hook runs after ActionText has been fully initialized.

ActiveSupport.on_load(:action_text_content) do
  ActionText::ContentHelper.allowed_attributes&.delete("style")
  ActionText::ContentHelper.allowed_tags&.delete("embed")
end
