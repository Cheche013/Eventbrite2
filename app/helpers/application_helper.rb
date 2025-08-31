module ApplicationHelper
  # Safely render an image. If the asset is missing in Propshaft load path,
  # fall back to an alternate path or external URL to avoid hard errors.
  def safe_image_tag(primary, fallback: nil, **options)
    image_tag(primary, **options)
  rescue StandardError
    return image_tag(fallback, **options) if fallback.present?
    # If no fallback provided, render a transparent 1x1 gif to avoid raising.
    data_uri = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=='
    image_tag(data_uri, **options)
  end
end
