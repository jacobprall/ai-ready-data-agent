ALTER TABLE {{ asset }}
MODIFY COLUMN {{ field }}
SET TAG {{ tag_name }} = '{{ tag_value }}'
