-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    price DOUBLE NOT NULL
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    total_amount DOUBLE NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    price DOUBLE NOT NULL
);

-- Insert sample products
INSERT INTO products (product_code, name, category, price) VALUES
('PILL-001', 'Stealth Pills', 'Pharmaceuticals', 49.99),
('PILL-002', 'Sleep Aid', 'Pharmaceuticals', 29.99),
('WEED-001', 'Premium Cannabis', 'Herbal', 199.99),
('WEED-002', 'Hybrid Strain', 'Herbal', 159.99),
('MDMA-001', 'MDMA Powder', 'Stimulant', 299.99),
('MDMA-002', 'Ecstasy Tablets', 'Stimulant', 249.99),
('COCAINE-001', 'Pure Cocaine', 'Stimulant', 999.99),
('LSD-001', 'LSD Blotter', 'Psychedelic', 79.99),
('MUSH-001', 'Magic Mushrooms', 'Psychedelic', 119.99);

-- Insert sample orders
INSERT INTO orders (order_number, customer_id, total_amount, status, created_at) VALUES
('ORD-001', 'CUST-001', 99.98, 'PENDING', CURRENT_TIMESTAMP),
('ORD-002', 'CUST-002', 159.99, 'PROCESSING', CURRENT_TIMESTAMP);

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity) VALUES
(1, 1, 2),  -- Order 1, Stealth Pills x2
(1, 3, 1),  -- Order 1, Premium Cannabis x1
(2, 4, 1);  -- Order 2, Hybrid Strain x1
