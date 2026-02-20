ALTER TABLE {{ asset }}
CLUSTER BY ({{ clustering_columns }})
