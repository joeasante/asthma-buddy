# frozen_string_literal: true

module MfaHelper
  def mfa_qr_svg(provisioning_uri)
    qr = RQRCode::QRCode.new(provisioning_uri)
    qr.as_svg(
      module_size: 4,
      use_path: true,
      fill: "ffffff",
      color: "000000",
      viewbox: true
    )
  end
end
