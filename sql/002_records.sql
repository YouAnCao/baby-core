-- Records table
-- Stores all baby tracking records (feeding, diaper changes, etc.)
CREATE TABLE IF NOT EXISTS records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    record_type TEXT NOT NULL, -- 'feeding', 'diaper', 'other'
    record_time DATETIME NOT NULL, -- Actual time of the event
    details TEXT NOT NULL, -- JSON field containing type-specific data
    notes TEXT, -- Optional notes
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL, -- Soft delete timestamp (v1.1+)
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_records_user_id ON records(user_id);
CREATE INDEX IF NOT EXISTS idx_records_record_time ON records(record_time);
CREATE INDEX IF NOT EXISTS idx_records_type ON records(record_type);
CREATE INDEX IF NOT EXISTS idx_records_user_time ON records(user_id, record_time DESC);
CREATE INDEX IF NOT EXISTS idx_records_deleted_at ON records(deleted_at);
CREATE INDEX IF NOT EXISTS idx_records_user_deleted ON records(user_id, deleted_at);

-- Details JSON structure examples:
-- Feeding: {"method": "breast_left|breast_right|bottle", "duration_minutes": 15, "amount_ml": 30}
-- Diaper: {"has_urine": true, "urine_amount": "少量|普通|大量", "has_stool": true, "stool_amount": "少量|普通|大量"}

