-- Create Database
CREATE DATABASE IF NOT EXISTS nanghalifinancial_db;
USE nanghalifinancial_db;

-- Users Table (for admin/staff)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role ENUM('admin', 'loan_officer', 'customer_service') DEFAULT 'loan_officer',
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Loan Products Table
CREATE TABLE loan_products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    min_amount DECIMAL(12,2) NOT NULL,
    max_amount DECIMAL(12,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    min_term_months INT NOT NULL,
    max_term_months INT NOT NULL,
    processing_fee_rate DECIMAL(5,2) DEFAULT 0,
    requirements TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers Table
CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    id_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other'),
    marital_status ENUM('single', 'married', 'divorced', 'widowed'),
    physical_address TEXT,
    employment_status ENUM('employed', 'self_employed', 'unemployed', 'student', 'retired'),
    monthly_income DECIMAL(12,2),
    employer_name VARCHAR(100),
    employment_duration_months INT,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Loan Applications Table
CREATE TABLE loan_applications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    application_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    loan_product_id INT NOT NULL,
    requested_amount DECIMAL(12,2) NOT NULL,
    requested_term_months INT NOT NULL,
    purpose TEXT,
    status ENUM('pending', 'under_review', 'approved', 'rejected', 'cancelled') DEFAULT 'pending',
    assigned_officer_id INT,
    application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    review_date TIMESTAMP NULL,
    decision_date TIMESTAMP NULL,
    rejection_reason TEXT,
    notes TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (loan_product_id) REFERENCES loan_products(id),
    FOREIGN KEY (assigned_officer_id) REFERENCES users(id)
);

-- Application Documents Table
CREATE TABLE application_documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    application_id INT NOT NULL,
    document_type ENUM('id_copy', 'payslip', 'bank_statement', 'proof_of_residence', 'employment_contract', 'business_registration', 'other'),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE,
    verification_notes TEXT,
    FOREIGN KEY (application_id) REFERENCES loan_applications(id) ON DELETE CASCADE
);

-- Approved Loans Table
CREATE TABLE approved_loans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    application_id INT UNIQUE NOT NULL,
    loan_number VARCHAR(20) UNIQUE NOT NULL,
    approved_amount DECIMAL(12,2) NOT NULL,
    approved_term_months INT NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    processing_fee DECIMAL(12,2) NOT NULL,
    disbursement_amount DECIMAL(12,2) NOT NULL,
    disbursement_date DATE,
    first_payment_date DATE,
    maturity_date DATE,
    status ENUM('active', 'completed', 'defaulted', 'written_off') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_by INT,
    FOREIGN KEY (application_id) REFERENCES loan_applications(id),
    FOREIGN KEY (approved_by) REFERENCES users(id)
);

-- Loan Repayment Schedule Table
CREATE TABLE repayment_schedule (
    id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    installment_number INT NOT NULL,
    due_date DATE NOT NULL,
    principal_amount DECIMAL(12,2) NOT NULL,
    interest_amount DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    status ENUM('pending', 'paid', 'overdue') DEFAULT 'pending',
    paid_date DATE NULL,
    paid_amount DECIMAL(12,2) DEFAULT 0,
    late_fee DECIMAL(12,2) DEFAULT 0,
    FOREIGN KEY (loan_id) REFERENCES approved_loans(id) ON DELETE CASCADE
);

-- Payments Table
CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    payment_reference VARCHAR(50) UNIQUE NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM('bank_transfer', 'cash', 'debit_order', 'mobile_money'),
    transaction_id VARCHAR(100),
    received_by INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES approved_loans(id),
    FOREIGN KEY (received_by) REFERENCES users(id)
);

-- Payment Allocation Table
CREATE TABLE payment_allocations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    payment_id INT NOT NULL,
    schedule_id INT NOT NULL,
    allocated_amount DECIMAL(12,2) NOT NULL,
    allocation_type ENUM('principal', 'interest', 'late_fee'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES repayment_schedule(id)
);

-- Contacts Table (for website contact form submissions)
CREATE TABLE contacts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('new', 'read', 'replied', 'closed') DEFAULT 'new',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- System Settings Table
CREATE TABLE system_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Audit Log Table
CREATE TABLE audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create Indexes for better performance
CREATE INDEX idx_loan_applications_customer_id ON loan_applications(customer_id);
CREATE INDEX idx_loan_applications_status ON loan_applications(status);
CREATE INDEX idx_loan_applications_application_date ON loan_applications(application_date);
CREATE INDEX idx_approved_loans_status ON approved_loans(status);
CREATE INDEX idx_repayment_schedule_due_date ON repayment_schedule(due_date);
CREATE INDEX idx_repayment_schedule_status ON repayment_schedule(status);
CREATE INDEX idx_payments_loan_id ON payments(loan_id);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);

-- Insert Default Loan Products
INSERT INTO loan_products (name, description, min_amount, max_amount, interest_rate, min_term_months, max_term_months, processing_fee_rate, requirements) VALUES
('Personal Loan', 'Flexible personal loans for various needs', 5000.00, 50000.00, 40.00, 3, 36, 2.00, 'Valid ID, Recent payslips, Bank statements, Proof of residence'),
('Salary Advance', 'Quick salary-based loans', 1000.00, 10000.00, 35.00, 1, 3, 1.50, 'Valid ID, Employment contract, Recent payslips'),
('Emergency Loan', 'Fast loans for emergency situations', 2000.00, 20000.00, 45.00, 3, 12, 2.50, 'Valid ID, Proof of emergency, Bank statements'),
('Short-Term Loan', 'Short-term financial solutions', 3000.00, 25000.00, 38.00, 3, 12, 2.00, 'Valid ID, Recent payslips, Bank statements'),
('SME Loan', 'Business loans for small and medium enterprises', 10000.00, 200000.00, 30.00, 6, 36, 3.00, 'Business registration, Financial statements, Bank statements, Business plan');

-- Insert Default Admin User
INSERT INTO users (username, email, password_hash, full_name, role, phone) VALUES
('admin', 'admin@nkfinacials.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'System Administrator', 'admin', '+264 81 864 4104');

-- Insert System Settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('company_name', 'NANGHALI YA KAFITA Financial Services CC', 'Company full name'),
('company_phone', '+264 81 864 4104', 'Main company phone number'),
('company_email', 'info@nkfinacials.com', 'Main company email'),
('company_address', 'Windhoek, Namibia', 'Company physical address'),
('office_hours', 'Mon - Fri: 8:00 AM - 5:00 PM, Sat: 9:00 AM - 1:00 PM', 'Office operating hours'),
('whatsapp_number', '+264818644104', 'WhatsApp contact number'),
('default_currency', 'NAD', 'Default currency for the system'),
('loan_approval_threshold', '50000', 'Maximum amount for automatic approval'),
('late_payment_fee', '200', 'Late payment penalty fee'),
('max_loan_amount_multiplier', '3', 'Maximum loan amount as multiple of monthly income');

-- Create Views for Reporting
CREATE VIEW loan_application_summary AS
SELECT 
    la.application_number,
    c.full_name AS customer_name,
    c.phone AS customer_phone,
    lp.name AS loan_product,
    la.requested_amount,
    la.requested_term_months,
    la.status,
    la.application_date
FROM loan_applications la
JOIN customers c ON la.customer_id = c.id
JOIN loan_products lp ON la.loan_product_id = lp.id;

CREATE VIEW active_loans_summary AS
SELECT 
    al.loan_number,
    c.full_name AS customer_name,
    c.phone AS customer_phone,
    lp.name AS loan_product,
    al.approved_amount,
    al.approved_term_months,
    al.interest_rate,
    al.disbursement_date,
    al.status
FROM approved_loans al
JOIN loan_applications la ON al.application_id = la.id
JOIN customers c ON la.customer_id = c.id
JOIN loan_products lp ON la.loan_product_id = lp.id
WHERE al.status = 'active';

CREATE VIEW payment_performance AS
SELECT 
    al.loan_number,
    c.full_name,
    rs.installment_number,
    rs.due_date,
    rs.total_amount,
    rs.status,
    rs.paid_date,
    rs.paid_amount
FROM repayment_schedule rs
JOIN approved_loans al ON rs.loan_id = al.id
JOIN loan_applications la ON al.application_id = la.id
JOIN customers c ON la.customer_id = c.id;

-- Stored Procedures
DELIMITER //

-- Procedure to calculate loan repayment schedule
CREATE PROCEDURE GenerateRepaymentSchedule(
    IN p_loan_id INT,
    IN p_principal DECIMAL(12,2),
    IN p_interest_rate DECIMAL(5,2),
    IN p_term_months INT,
    IN p_first_payment_date DATE
)
BEGIN
    DECLARE v_installment_number INT DEFAULT 1;
    DECLARE v_monthly_interest_rate DECIMAL(10,8);
    DECLARE v_monthly_payment DECIMAL(12,2);
    DECLARE v_due_date DATE;
    DECLARE v_remaining_principal DECIMAL(12,2) DEFAULT p_principal;
    
    SET v_monthly_interest_rate = p_interest_rate / 100 / 12;
    
    -- Calculate monthly payment using annuity formula
    SET v_monthly_payment = ROUND(
        (p_principal * v_monthly_interest_rate * POW(1 + v_monthly_interest_rate, p_term_months)) / 
        (POW(1 + v_monthly_interest_rate, p_term_months) - 1),
        2
    );
    
    SET v_due_date = p_first_payment_date;
    
    WHILE v_installment_number <= p_term_months DO
        INSERT INTO repayment_schedule (loan_id, installment_number, due_date, principal_amount, interest_amount, total_amount)
        VALUES (
            p_loan_id,
            v_installment_number,
            v_due_date,
            ROUND(v_monthly_payment - (v_remaining_principal * v_monthly_interest_rate), 2),
            ROUND(v_remaining_principal * v_monthly_interest_rate, 2),
            v_monthly_payment
        );
        
        SET v_remaining_principal = v_remaining_principal - (v_monthly_payment - (v_remaining_principal * v_monthly_interest_rate));
        SET v_installment_number = v_installment_number + 1;
        SET v_due_date = DATE_ADD(v_due_date, INTERVAL 1 MONTH);
    END WHILE;
END//

-- Procedure to process loan application approval
CREATE PROCEDURE ApproveLoanApplication(
    IN p_application_id INT,
    IN p_approved_amount DECIMAL(12,2),
    IN p_approved_term INT,
    IN p_approved_by INT
)
BEGIN
    DECLARE v_loan_number VARCHAR(20);
    DECLARE v_processing_fee DECIMAL(12,2);
    DECLARE v_disbursement_amount DECIMAL(12,2);
    DECLARE v_interest_rate DECIMAL(5,2);
    DECLARE v_first_payment_date DATE;
    
    -- Generate unique loan number
    SET v_loan_number = CONCAT('NYL', YEAR(CURDATE()), LPAD(FLOOR(RAND() * 10000), 4, '0'));
    
    -- Get loan product interest rate
    SELECT lp.interest_rate, lp.processing_fee_rate INTO v_interest_rate, v_processing_fee
    FROM loan_applications la
    JOIN loan_products lp ON la.loan_product_id = lp.id
    WHERE la.id = p_application_id;
    
    SET v_processing_fee = ROUND(p_approved_amount * (v_processing_fee / 100), 2);
    SET v_disbursement_amount = p_approved_amount - v_processing_fee;
    SET v_first_payment_date = DATE_ADD(CURDATE(), INTERVAL 1 MONTH);
    
    -- Update application status
    UPDATE loan_applications 
    SET status = 'approved', decision_date = NOW()
    WHERE id = p_application_id;
    
    -- Create approved loan record
    INSERT INTO approved_loans (
        application_id, loan_number, approved_amount, approved_term_months, 
        interest_rate, processing_fee, disbursement_amount, 
        disbursement_date, first_payment_date, maturity_date, approved_by
    ) VALUES (
        p_application_id, v_loan_number, p_approved_amount, p_approved_term,
        v_interest_rate, v_processing_fee, v_disbursement_amount,
        CURDATE(), v_first_payment_date, DATE_ADD(v_first_payment_date, INTERVAL (p_approved_term - 1) MONTH), p_approved_by
    );
    
    -- Generate repayment schedule
    CALL GenerateRepaymentSchedule(LAST_INSERT_ID(), p_approved_amount, v_interest_rate, p_approved_term, v_first_payment_date);
    
END//

DELIMITER ;

-- Create Triggers for Audit Log
DELIMITER //

CREATE TRIGGER audit_loan_applications_update
    AFTER UPDATE ON loan_applications
    FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            NEW.assigned_officer_id,
            'STATUS_CHANGE',
            'loan_applications',
            NEW.id,
            JSON_OBJECT('status', OLD.status),
            JSON_OBJECT('status', NEW.status)
        );
    END IF;
END//

CREATE TRIGGER audit_loan_approval
    AFTER INSERT ON approved_loans
    FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, new_values)
    VALUES (
        NEW.approved_by,
        'LOAN_APPROVED',
        'approved_loans',
        NEW.id,
        JSON_OBJECT(
            'loan_number', NEW.loan_number,
            'amount', NEW.approved_amount,
            'term', NEW.approved_term_months
        )
    );
END//

DELIMITER ;

-- Sample Data for Testing
INSERT INTO customers (customer_code, id_number, full_name, email, phone, date_of_birth, gender, physical_address, employment_status, monthly_income, employer_name) VALUES
('CUST001', '8001011234567', 'John Shikongo', 'john.shikongo@email.com', '+264811234567', '1980-01-01', 'male', '123 Main Street, Windhoek', 'employed', 15000.00, 'Namibia Corp'),
('CUST002', '8505057654321', 'Maria Nghinamwaama', 'maria.n@email.com', '+264812345678', '1985-05-05', 'female', '456 Independence Ave, Windhoek', 'self_employed', 20000.00, 'Maria Trading'),
('CUST003', '9009091122334', 'Paulina Kambwela', 'paulina.k@email.com', '+264813456789', '1990-09-09', 'female', '789 Freedom Street, Windhoek', 'employed', 12000.00, 'Windhoek Enterprises');

-- Display table information
SHOW TABLES;

-- Display sample data counts
SELECT 
    (SELECT COUNT(*) FROM customers) as total_customers,
    (SELECT COUNT(*) FROM loan_applications) as total_applications,
    (SELECT COUNT(*) FROM approved_loans) as total_loans,
    (SELECT COUNT(*) FROM contacts) as total_contacts;