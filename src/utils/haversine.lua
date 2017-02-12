return function (lng1, lat1, lng2, lat2, r)
  r = r or 1

  local k_lng = math.sin((lng2-lng1)/2)
  local k_lat = math.sin((lat2-lat1)/2)

  local a = k_lat * k_lat
          + k_lng * k_lng * math.cos(lat1) * math.cos(lat2)

  return 2 * math.atan(math.sqrt(a), math.sqrt(1-a)) * r
end