class GoogleMaps

  def self.initial_zoom
    NOOSFERO_CONF['googlemaps_initial_zoom'] || 4
  end

  def self.js_api_key
    NOOSFERO_CONF['googlemaps_js_api_key']
  end

  def self.static_api_key
    NOOSFERO_CONF['googlemaps_static_api_key']
  end

end
