-- AI Analysis table
-- Stores AI-generated analysis results (prepared for future use)
CREATE TABLE IF NOT EXISTS ai_analysis (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    analysis_date DATE NOT NULL, -- Date for which analysis was performed
    prompt TEXT NOT NULL, -- Prompt sent to AI
    data_summary TEXT NOT NULL, -- JSON summary of data sent to AI
    ai_response TEXT NOT NULL, -- AI's analysis and recommendations
    ai_provider TEXT NOT NULL, -- 'gemini', 'gpt', etc.
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_analysis_user_id ON ai_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_date ON ai_analysis(analysis_date DESC);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_user_date ON ai_analysis(user_id, analysis_date DESC);

