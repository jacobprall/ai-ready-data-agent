UPDATE {{ asset }}
SET {{ field }} = {{ default_value }}
WHERE {{ field }} IS NULL
