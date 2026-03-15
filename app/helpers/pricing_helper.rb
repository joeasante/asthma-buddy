# frozen_string_literal: true

module PricingHelper
  def pricing_check_icon(premium: false)
    css_class = premium ? "pricing-check pricing-check--premium" : "pricing-check"
    tag.svg(class: css_class, width: 16, height: 16, viewBox: "0 0 16 16", fill: "none", aria_hidden: true) do
      tag.path(d: "M2.5 8l3.5 3.5 7-7", stroke: "currentColor", stroke_width: 2, stroke_linecap: "round", stroke_linejoin: "round")
    end
  end
end
