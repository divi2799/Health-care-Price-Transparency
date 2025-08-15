-- Create the database
CREATE DATABASE IF NOT EXISTS health1;
USE health1;

-- Temporarily disable safe updates for data loading
SET SQL_SAFE_UPDATES = 0;

-- Add hospital identifiers to source table
ALTER TABLE hospital_charges_MGH 
ADD COLUMN hospital_id VARCHAR(10),
ADD COLUMN hospital_name VARCHAR(255);

ALTER TABLE hospital_charges_BWFH 
ADD COLUMN hospital_id VARCHAR(10),
ADD COLUMN hospital_name VARCHAR(255);

ALTER TABLE hospital_charges_BMC 
ADD COLUMN hospital_id VARCHAR(10),
ADD COLUMN hospital_name VARCHAR(255);

ALTER TABLE hospital_charges_NWH 
ADD COLUMN hospital_id VARCHAR(10),
ADD COLUMN hospital_name VARCHAR(255);

ALTER TABLE hospital_charges_NH_WDH 
ADD COLUMN hospital_id VARCHAR(10),
ADD COLUMN hospital_name VARCHAR(255);


-- Update hospital identifiers
UPDATE hospital_charges_MGH SET 
    hospital_id = 'MA-2168', 
    hospital_name = 'Massachusetts General Hospital (MGH)';

UPDATE hospital_charges_BWFH SET 
    hospital_id = 'MA-2048', 
    hospital_name = 'Brigham and Women''s Faulkner Hospital (BWFH)';

UPDATE hospital_charges_BMC SET 
    hospital_id = 'MA-V112', 
    hospital_name = 'Boston Medical Center (BMC)';

UPDATE hospital_charges_NWH SET 
    hospital_id = 'MA-2075',
    hospital_name = 'Newton-Wellesley Hospital (NWH)';

UPDATE hospital_charges_NH_WDH SET 
    hospital_id = 'NH-00010',
    hospital_name = 'Wentworth Douglass Hospital(NH-WDH)';

    

-- Create normalized tables 
DROP TABLE IF EXISTS Charge;
DROP TABLE IF EXISTS Payer;
DROP TABLE IF EXISTS Code;
DROP TABLE IF EXISTS Hospital;

CREATE TABLE Hospital (
    hospital_id VARCHAR(10) PRIMARY KEY,
    hospital_name VARCHAR(255) NOT NULL
);

CREATE TABLE Payer (
    payer_id INT PRIMARY KEY AUTO_INCREMENT,
    payer_name VARCHAR(255) NOT NULL,
    plan_name VARCHAR(255),
    hospital_id VARCHAR(10),
    INDEX (payer_name, plan_name),
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);

CREATE TABLE Code (
    code_id INT PRIMARY KEY AUTO_INCREMENT,
    code_2 VARCHAR(255) NOT NULL,
    code_2_type VARCHAR(255),
    description TEXT,
    INDEX (code_2)
);

CREATE TABLE Charge (
    charge_id INT PRIMARY KEY AUTO_INCREMENT,
    hospital_id VARCHAR(10) NOT NULL,
    code_id INT NOT NULL,
    payer_id INT,
    standard_charge_gross DECIMAL(12,2),
    standard_charge_discounted_cash DECIMAL(12,2),
    standard_charge_negotiated_dollar DECIMAL(12,2),
    standard_charge_negotiated_percentage DECIMAL(5,2),
    standard_charge_negotiated_algorithm TEXT,
    estimated_amount DECIMAL(12,2),
    standard_charge_min DECIMAL(12,2),
    standard_charge_max DECIMAL(12,2),
    standard_charge_methodology TEXT,
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id),
    FOREIGN KEY (payer_id) REFERENCES Payer(payer_id),
    FOREIGN KEY (code_id) REFERENCES Code(code_id)
);

-- Populate Hospital table 
INSERT INTO Hospital (hospital_id, hospital_name)
SELECT  hospital_id, hospital_name 
FROM (
    SELECT hospital_id, hospital_name FROM hospital_charges_MGH
    UNION
    SELECT hospital_id, hospital_name FROM hospital_charges_BWFH
    UNION
    SELECT hospital_id, hospital_name FROM hospital_charges_BMC
    UNION 
    SELECT hospital_id, hospital_name FROM hospital_charges_NWH
    UNION 
    SELECT hospital_id, hospital_name FROM hospital_charges_NH_WDH
) AS combined_hospitals;

-- Populate Payer table 
INSERT INTO Payer (payer_name, plan_name, hospital_id)
SELECT 
    h.payer_name, 
    h.plan_name,
    h.hospital_id
FROM (
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_MGH
    UNION
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_BWFH
    UNION
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_BMC
    UNION
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_NWH
    UNION
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_NH_WDH
) AS h
WHERE h.payer_name IS NOT NULL;

-- Populate Code table 
INSERT INTO Code (code_2, code_2_type, description)
SELECT
    code_2, 
    code_2_type, 
    description
FROM (
    SELECT code_2, code_2_type, description FROM hospital_charges_MGH
    UNION
    SELECT code_2, code_2_type, description FROM hospital_charges_BWFH
    UNION
    SELECT code_2, code_2_type, description FROM hospital_charges_BMC
    UNION
    SELECT code_2, code_2_type, description FROM hospital_charges_NWH
    UNION
    SELECT code_2, code_2_type, description FROM hospital_charges_NH_WDH
) AS c
WHERE code_2 IS NOT NULL;

-- Populate Charge table 
-- Before running your large INSERT, increase these timeout settings:
SET GLOBAL wait_timeout = 600;
SET GLOBAL interactive_timeout = 600;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;

-- First batch: Insert records from MGH
INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_MGH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name 
    AND src.plan_name = p.plan_name 
    AND src.hospital_id = p.hospital_id;

-- Second batch: Insert records from BWFH
INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_BWFH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name 
    AND src.plan_name = p.plan_name 
    AND src.hospital_id = p.hospital_id;

-- Third batch: Insert records from BMC
INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_BMC src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name 
    AND src.plan_name = p.plan_name 
    AND src.hospital_id = p.hospital_id;
    
-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 0;
-- NWH DATA INSERTION

INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_NWH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name 
    AND src.plan_name = p.plan_name 
    AND src.hospital_id = p.hospital_id;
    
-- NH_WDH DATA INSERTION


INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_NH_WDH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name 
    AND src.plan_name = p.plan_name 
    AND src.hospital_id = p.hospital_id;
    



-- Insert hospital records
INSERT INTO Hospital (hospital_id, hospital_name)
SELECT DISTINCT hospital_id, hospital_name
FROM (
    SELECT hospital_id, hospital_name FROM hospital_charges_WA_MAHT
    UNION
    SELECT hospital_id, hospital_name FROM hospital_charges_MA_TMC
) AS new_hospitals
WHERE hospital_id IS NOT NULL;

-- Insert new payer and plan combinations
INSERT INTO Payer (payer_name, plan_name, hospital_id)
SELECT DISTINCT payer_name, plan_name, hospital_id
FROM (
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_WA_MAHT
    UNION
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_MA_TMC
) AS new_payers
WHERE payer_name IS NOT NULL;

-- Insert new codes and descriptions
INSERT INTO Code (code_2, code_2_type, description)
SELECT DISTINCT code_2, code_2_type, description
FROM (
    SELECT code_2, code_2_type, description FROM hospital_charges_WA_MAHT
    UNION
    SELECT code_2, code_2_type, description FROM hospital_charges_MA_TMC
) AS new_codes
WHERE code_2 IS NOT NULL;

-- Insert records from WA MAHT
INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_WA_MAHT src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name 
    AND src.plan_name = p.plan_name 
    AND src.hospital_id = p.hospital_id;
 

INSERT INTO Charge (
    hospital_id,
    code_id,
    payer_id,
    standard_charge_gross,
    standard_charge_discounted_cash,
    standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage,
    standard_charge_negotiated_algorithm,
    estimated_amount,
    standard_charge_min,
    standard_charge_max,
    standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_MA_TMC src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p 
  ON src.payer_name = p.payer_name 
 AND src.plan_name = p.plan_name 
 AND src.hospital_id = p.hospital_id;

select * from hospital_charges_MA_TMC;

-- Verification queries (as in original)
SELECT COUNT(*) AS hospital_count FROM Hospital;
SELECT COUNT(*) AS payer_count FROM Payer;
SELECT COUNT(*) AS code_count FROM Code;
SELECT COUNT(*) AS charge_count FROM Charge;

select * from Hospital;





select * from hospital_charges_NWH;





-- Create and use the database
CREATE DATABASE IF NOT EXISTS health1;
USE health1;

-- Disable safe updates
SET SQL_SAFE_UPDATES = 0;

-- Add hospital_id and hospital_name to all source tables
-- (Manual column addition recommended due to MySQL limitations)
-- Replace IF NOT EXISTS with stored procedure logic if needed
ALTER TABLE hospital_charges_MGH ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);
ALTER TABLE hospital_charges_BWFH ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);
ALTER TABLE hospital_charges_BMC ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);
ALTER TABLE hospital_charges_NWH ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);
ALTER TABLE hospital_charges_NH_WDH ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);
ALTER TABLE hospital_charges_WA_MAH ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);
ALTER TABLE hospital_charges_MA_TMC ADD COLUMN hospital_id VARCHAR(10), ADD COLUMN hospital_name VARCHAR(255);

-- Update hospital identifiers
UPDATE hospital_charges_MGH SET hospital_id = 'MA-2168', hospital_name = 'Massachusetts General Hospital (MGH)';
UPDATE hospital_charges_BWFH SET hospital_id = 'MA-2048', hospital_name = 'Brigham and Women''s Faulkner Hospital (BWFH)';
UPDATE hospital_charges_BMC SET hospital_id = 'MA-V112', hospital_name = 'Boston Medical Center (BMC)';
UPDATE hospital_charges_NWH SET hospital_id = 'MA-2075', hospital_name = 'Newton-Wellesley Hospital (NWH)';
UPDATE hospital_charges_NH_WDH SET hospital_id = 'NH-00010', hospital_name = 'Wentworth Douglass Hospital (NH-WDH)';
UPDATE hospital_charges_WA_MAH SET hospital_id = 'WA-0042', hospital_name = 'MultiCare Allenmore Hospital (MAHT),Tacoma General Hospital';
UPDATE hospital_charges_MA_TMC SET hospital_id = 'MA-2299', hospital_name = 'Tufts Medical Center (TMC)';

-- Drop normalized tables if they exist
DROP TABLE IF EXISTS Charge, Payer, Code, Hospital;

-- Create normalized tables
CREATE TABLE Hospital (
    hospital_id VARCHAR(10) PRIMARY KEY,
    hospital_name VARCHAR(255) NOT NULL
);

CREATE TABLE Payer (
    payer_id INT PRIMARY KEY AUTO_INCREMENT,
    payer_name VARCHAR(255) NOT NULL,
    plan_name VARCHAR(255),
    hospital_id VARCHAR(10),
    INDEX (payer_name, plan_name),
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);

CREATE TABLE Code (
    code_id INT PRIMARY KEY AUTO_INCREMENT,
    code_2 VARCHAR(255) NOT NULL,
    code_2_type VARCHAR(255),
    description TEXT,
    INDEX (code_2)
);

CREATE TABLE Charge (
    charge_id INT PRIMARY KEY AUTO_INCREMENT,
    hospital_id VARCHAR(10) NOT NULL,
    code_id INT NOT NULL,
    payer_id INT,
    standard_charge_gross DECIMAL(12,2),
    standard_charge_discounted_cash DECIMAL(12,2),
    standard_charge_negotiated_dollar DECIMAL(12,2),
    standard_charge_negotiated_percentage DECIMAL(5,2),
    standard_charge_negotiated_algorithm TEXT,
    estimated_amount DECIMAL(12,2),
    standard_charge_min DECIMAL(12,2),
    standard_charge_max DECIMAL(12,2),
    standard_charge_methodology TEXT,
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id),
    FOREIGN KEY (payer_id) REFERENCES Payer(payer_id),
    FOREIGN KEY (code_id) REFERENCES Code(code_id)
);

-- Populate Hospital table
INSERT INTO Hospital (hospital_id, hospital_name)
SELECT DISTINCT hospital_id, hospital_name FROM (
    SELECT hospital_id, hospital_name FROM hospital_charges_MGH
    UNION SELECT hospital_id, hospital_name FROM hospital_charges_BWFH
    UNION SELECT hospital_id, hospital_name FROM hospital_charges_BMC
    UNION SELECT hospital_id, hospital_name FROM hospital_charges_NWH
    UNION SELECT hospital_id, hospital_name FROM hospital_charges_NH_WDH
    UNION SELECT hospital_id, hospital_name FROM hospital_charges_WA_MAH
    UNION SELECT hospital_id, hospital_name FROM hospital_charges_MA_TMC
) AS hospitals;

-- Populate Payer table
INSERT INTO Payer (payer_name, plan_name, hospital_id)
SELECT DISTINCT payer_name, plan_name, hospital_id FROM (
    SELECT payer_name, plan_name, hospital_id FROM hospital_charges_MGH
    UNION SELECT payer_name, plan_name, hospital_id FROM hospital_charges_BWFH
    UNION SELECT payer_name, plan_name, hospital_id FROM hospital_charges_BMC
    UNION SELECT payer_name, plan_name, hospital_id FROM hospital_charges_NWH
    UNION SELECT payer_name, plan_name, hospital_id FROM hospital_charges_NH_WDH
    UNION SELECT payer_name, plan_name, hospital_id FROM hospital_charges_WA_MAH
    UNION SELECT payer_name, plan_name, hospital_id FROM hospital_charges_MA_TMC
) AS payers
WHERE payer_name IS NOT NULL;

-- Populate Code table
INSERT INTO Code (code_2, code_2_type, description)
SELECT DISTINCT code_2, code_2_type, description FROM (
    SELECT code_2, code_2_type, description FROM hospital_charges_MGH
    UNION SELECT code_2, code_2_type, description FROM hospital_charges_BWFH
    UNION SELECT code_2, code_2_type, description FROM hospital_charges_BMC
    UNION SELECT code_2, code_2_type, description FROM hospital_charges_NWH
    UNION SELECT code_2, code_2_type, description FROM hospital_charges_NH_WDH
    UNION SELECT code_2, code_2_type, description FROM hospital_charges_WA_MAH
    UNION SELECT code_2, code_2_type, description FROM hospital_charges_MA_TMC
) AS codes
WHERE code_2 IS NOT NULL;


-- Increase timeouts for long-running queries
SET GLOBAL wait_timeout = 6000;
SET GLOBAL interactive_timeout = 6000;
SET GLOBAL net_read_timeout = 6000;
SET GLOBAL net_write_timeout = 6000;
SET SESSION max_allowed_packet = 1073741824; -- 1GB to handle large queries if needed



-- Helper macro for Charge insertions
-- Repeat this pattern for each source table:
-- Replace "hospital_charges_MGH" with other source tables accordingly
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_MGH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;

-- Repeat the above INSERT INTO Charge block for each hospital table:
-- hospital_charges_BWFH, 
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_BWFH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;
-- hospital_charges_BMC,
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_BMC src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;
-- hospital_charges_NWH,
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_NWH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;
-- hospital_charges_NH_WDH, 
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_NH_WDH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;
-- hospital_charges_WA_MAH,
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_WA_MAH src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;
-- hospital_charges_MA_TMC
INSERT INTO Charge (
    hospital_id, code_id, payer_id, standard_charge_gross,
    standard_charge_discounted_cash, standard_charge_negotiated_dollar,
    standard_charge_negotiated_percentage, standard_charge_negotiated_algorithm,
    estimated_amount, standard_charge_min, standard_charge_max, standard_charge_methodology
)
SELECT 
    src.hospital_id,
    c.code_id,
    p.payer_id,
    src.standard_charge_gross,
    src.standard_charge_discounted_cash,
    src.standard_charge_negotiated_dollar,
    src.standard_charge_negotiated_percentage,
    src.standard_charge_negotiated_algorithm,
    src.estimated_amount,
    src.standard_charge_min,
    src.standard_charge_max,
    src.standard_charge_methodology
FROM hospital_charges_MA_TMC src
JOIN Code c ON src.code_2 = c.code_2
LEFT JOIN Payer p ON src.payer_name = p.payer_name AND src.plan_name = p.plan_name AND src.hospital_id = p.hospital_id;
-- Final validation
SELECT COUNT(*) AS hospital_count FROM Hospital;
SELECT COUNT(*) AS payer_count FROM Payer;
SELECT COUNT(*) AS code_count FROM Code;
SELECT COUNT(*) AS charge_count FROM Charge;
SELECT * FROM Hospital;


