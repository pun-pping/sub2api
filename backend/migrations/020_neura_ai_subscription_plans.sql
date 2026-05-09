-- Subscription Plans Table
CREATE TABLE IF NOT EXISTS subscription_plans (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    monthly_tokens BIGINT NOT NULL,
    qps_limit INT NOT NULL DEFAULT 10,
    support_level VARCHAR(50) NOT NULL DEFAULT 'basic', -- basic, email, priority
    is_annual BOOLEAN DEFAULT FALSE,
    annual_price DECIMAL(10, 2),
    annual_discount DECIMAL(5, 2), -- 年付折扣百分比
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Subscriptions Table
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    plan_id BIGINT NOT NULL,
    tokens_used BIGINT DEFAULT 0,
    tokens_limit BIGINT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, paused, expired, cancelled
    renewal_order_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(id)
);

-- Token Consumption Logs (for tracking and analytics)
CREATE TABLE IF NOT EXISTS token_consumption_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    model VARCHAR(100) NOT NULL,
    platform VARCHAR(50) NOT NULL, -- claude, gpt, gemini
    input_tokens BIGINT NOT NULL,
    output_tokens BIGINT NOT NULL,
    total_tokens BIGINT NOT NULL,
    cost_cny DECIMAL(10, 4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Referral Records (for referral rewards)
CREATE TABLE IF NOT EXISTS referral_records (
    id BIGSERIAL PRIMARY KEY,
    referrer_id BIGINT NOT NULL,
    referred_user_id BIGINT NOT NULL,
    reward_amount DECIMAL(10, 2),
    reward_tokens BIGINT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, completed, expired
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (referrer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (referred_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Coupons Table
CREATE TABLE IF NOT EXISTS coupons (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_type VARCHAR(50) NOT NULL, -- percentage, fixed_amount, tokens
    discount_value DECIMAL(10, 2) NOT NULL,
    max_uses INT DEFAULT -1, -- -1 means unlimited
    used_count INT DEFAULT 0,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Coupon Usage
CREATE TABLE IF NOT EXISTS user_coupon_usage (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    coupon_id BIGINT NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    order_id VARCHAR(100),
    discount_amount DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE
);

-- Additional Token Package Purchases
CREATE TABLE IF NOT EXISTS token_package_purchases (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    package_size BIGINT NOT NULL, -- 10000, 100000, 1000000
    package_price DECIMAL(10, 2) NOT NULL,
    tokens_remaining BIGINT NOT NULL,
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP + INTERVAL '90 days',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON user_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_token_consumption_logs_user_id ON token_consumption_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_token_consumption_logs_created_at ON token_consumption_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_token_package_purchases_user_id ON token_package_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_token_package_purchases_expires_at ON token_package_purchases(expires_at);
CREATE INDEX IF NOT EXISTS idx_referral_records_referrer_id ON referral_records(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_records_referred_user_id ON referral_records(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_is_active ON coupons(is_active);

-- Insert Default Subscription Plans for Neura AI
INSERT INTO subscription_plans (name, description, price, monthly_tokens, qps_limit, support_level, sort_order, is_active)
VALUES 
    ('基础版', '适合个人开发者和学生', 99.00, 1000000, 10, 'basic', 1, TRUE),
    ('专业版', '适合创业公司和中型项目', 299.00, 5000000, 20, 'email', 2, TRUE),
    ('高级版', '适合企业用户和大型项目', 599.00, 15000000, 50, 'priority', 3, TRUE)
ON CONFLICT DO NOTHING;

-- Insert Annual Plan Discount Version
INSERT INTO subscription_plans (name, description, price, monthly_tokens, qps_limit, support_level, is_annual, annual_price, annual_discount, sort_order, is_active)
VALUES 
    ('基础版-年付', '基础版年付计划', 999.00, 1000000, 10, 'basic', TRUE, 999.00, 16.00, 4, TRUE),
    ('专业版-年付', '专业版年付计划', 2999.00, 5000000, 20, 'email', TRUE, 2999.00, 17.00, 5, TRUE),
    ('高级版-年付', '高级版年付计划', 5999.00, 15000000, 50, 'priority', TRUE, 5999.00, 17.00, 6, TRUE)
ON CONFLICT DO NOTHING;

-- Insert Sample Coupons
INSERT INTO coupons (code, discount_type, discount_value, max_uses, valid_from, valid_until, description, is_active)
VALUES 
    ('WELCOME_50', 'percentage', 50.00, 100, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', '新用户首月5折优惠', TRUE),
    ('REFERRAL_10', 'percentage', 10.00, -1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '180 days', '推荐朋友优惠码', TRUE)
ON CONFLICT DO NOTHING;
