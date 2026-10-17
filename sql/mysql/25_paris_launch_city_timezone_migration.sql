ALTER TABLE city
  ADD COLUMN time_zone VARCHAR(64) NOT NULL DEFAULT 'UTC' AFTER name;

UPDATE city
SET time_zone = CASE
  WHEN region = 'CN' THEN 'Asia/Shanghai'
  WHEN region = 'EU' AND code = 'PAR' THEN 'Europe/Paris'
  WHEN region = 'EU' AND code = 'BER' THEN 'Europe/Berlin'
  ELSE 'UTC'
END;

UPDATE city
SET status = CASE WHEN code = 'PAR' THEN 1 ELSE 0 END
WHERE region = 'EU';

-- Keep the booking's original local-time interpretation when city metadata changes.
ALTER TABLE reservation
  ADD COLUMN time_zone VARCHAR(64) NOT NULL DEFAULT '' AFTER reserve_time;

UPDATE reservation r
JOIN shop s ON s.id = r.shop_id
JOIN city c ON c.id = s.city_id AND c.region = s.region
SET r.time_zone = c.time_zone
WHERE r.time_zone = '';
