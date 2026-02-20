ALTER TABLE {{ asset }}
MODIFY COLUMN {{ field }}
SET MASKING POLICY {{ policy_name }}
