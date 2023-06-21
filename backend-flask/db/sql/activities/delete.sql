DELETE FROM activities
WHERE expires_at < NOW() - INTERVAL '12 HOURS';