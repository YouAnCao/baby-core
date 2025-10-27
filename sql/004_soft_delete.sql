-- Add soft delete support to records table
-- Add deleted_at column to track when a record was soft deleted
ALTER TABLE records ADD COLUMN deleted_at DATETIME DEFAULT NULL;

-- Create index for efficient queries on deleted_at
CREATE INDEX IF NOT EXISTS idx_records_deleted_at ON records(deleted_at);

-- Create index for combined queries (user_id + deleted_at)
CREATE INDEX IF NOT EXISTS idx_records_user_deleted ON records(user_id, deleted_at);

