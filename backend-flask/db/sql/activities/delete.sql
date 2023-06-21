DELETE FROM activities
WHERE expires_at < now();