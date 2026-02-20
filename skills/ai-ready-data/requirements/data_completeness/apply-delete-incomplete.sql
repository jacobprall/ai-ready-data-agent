DELETE FROM {{ asset }}
WHERE {{ field }} IS NULL
