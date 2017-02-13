return function (point_a, point_b, fraction)
  fraction = fraction or 1/2

  local lng_a, lat_a = unpack(point_a)
  local lng_b, lat_b = unpack(point_b)

  local d = haversine(lng_a, lat_a, lng_b, lat_b)

  local A = math.sin(d * (1-fraction)) / math.sin(d)
  local B = math.sin(d * fraction) / math.sin(d)

  local x = A * math.cos(lat_a) * math.cos(lng_a)
          + B * math.cos(lat_b) * math.cos(lng_b)
  local y = A * math.cos(lat_a) * math.sin(lng_a)
          + B * math.cos(lat_b) * math.sin(lng_b)
  local z = A * math.sin(lat_a)
          + B * math.sin(lat_b)

  local lat_m = math.atan(z, math.sqrt(x*x + y*y))
  local lng_m = math.atan(y, x)

  local lat = math.deg(lat_m)
  local lng = math.deg(lng_m)

  return { lng, lat }
end