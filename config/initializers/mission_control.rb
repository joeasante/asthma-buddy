# frozen_string_literal: true

# Mission Control – Jobs configuration.
# Session-based auth via Admin::BaseController handles access control,
# so Basic Auth is disabled (it doesn't work over plain HTTP on non-localhost).
MissionControl::Jobs.base_controller_class = "Admin::BaseController"
MissionControl::Jobs.http_basic_auth_enabled = false
