-- ===============================================
-- TRIGGER FUNCTION: set_subscription_status_and_update_company
-- Automatically sets Subscription_status based on EndDate.
-- Updates related Company's Status if no active subscriptions remain.
-- ===============================================

CREATE OR REPLACE FUNCTION set_subscription_status_and_update_company()
RETURNS TRIGGER AS $$
DECLARE
  active_count INT;
BEGIN
 
 -- Set Subscription_status based on EndDate
 
 IF NEW.EndDate < CURRENT_DATE THEN
    NEW.Subscription_status := 'Pasif';
  ELSE
    NEW.Subscription_status := 'Aktif';
  END IF;

  -- Count active subscriptions for the related company
 
 IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT COUNT(*) INTO active_count
    FROM Subscriptions
    WHERE CompanyID = NEW.CompanyID
      AND Subscription_status = 'Aktif';
  ELSE
   
   -- If DELETE, use OLD
   
   SELECT COUNT(*) INTO active_count
    FROM Subscriptions
    WHERE CompanyID = OLD.CompanyID
      AND Subscription_status = 'Aktif';
  END IF;

  -- Update Company Status
 
 IF active_count > 0 THEN
    UPDATE Companies
    SET Status = 'Aktif'
    WHERE CompanyID = COALESCE(NEW.CompanyID, OLD.CompanyID);
  ELSE
    UPDATE Companies
    SET Status = 'Pasif'
    WHERE CompanyID = COALESCE(NEW.CompanyID, OLD.CompanyID);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: trg_set_subscription_status_and_update_company
-- Runs AFTER INSERT/UPDATE/DELETE on Subscriptions


CREATE TRIGGER trg_set_subscription_status_and_update_company
AFTER INSERT OR UPDATE OR DELETE ON Subscriptions
FOR EACH ROW
EXECUTE FUNCTION set_subscription_status_and_update_company();



-- ===============================================
-- TRIGGER FUNCTION: Set Retention Days and End Date
-- Automatically sets RetentionDays and calculates RetentionEndDate
-- for an Invoice based on its related Company settings.
-- ===============================================

CREATE OR REPLACE FUNCTION set_retention_days()
RETURNS TRIGGER AS $$
BEGIN

  -- If there is a CompanyID, get RetentionDays from Companies table
  
  IF NEW.CompanyID IS NOT NULL THEN
    SELECT RetentionDays INTO NEW.RetentionDays
    FROM Companies
    WHERE CompanyID = NEW.CompanyID;

    -- Calculate RetentionEndDate based on InvoiceDate and RetentionDays
	
    NEW.RetentionEndDate := NEW.InvoiceDate + (NEW.RetentionDays || ' days')::interval;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Apply function BEFORE INSERT on Invoice


CREATE TRIGGER trg_set_retention_days
BEFORE INSERT ON Invoice
FOR EACH ROW
EXECUTE FUNCTION set_retention_days();


-- ===============================================
-- TABLE: Subscriptions_log
-- Stores a log entry whenever a subscription is added, updated, or deleted.
-- ===============================================

CREATE TABLE Subscriptions_log (
  SubscriptionLogID SERIAL PRIMARY KEY,        -- Auto-increment log ID
  SubscriptionID UUID,                         -- Related Subscription ID
  CompanyID UUID,                              -- Related Company ID
  ActionType VARCHAR(10),                      -- 'INSERT', 'UPDATE', 'DELETE'
  ActionDate TIMESTAMP DEFAULT now()           -- Timestamp when the action happened
);


-- TRIGGER FUNCTION: log_subscriptions
-- Automatically logs every INSERT, UPDATE, DELETE on Subscriptions table.


CREATE OR REPLACE FUNCTION log_subscriptions()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Subscriptions_log (SubscriptionID, CompanyID, ActionType, ActionDate)
  VALUES (
    COALESCE(NEW.SubscriptionID, OLD.SubscriptionID),
    COALESCE(NEW.CompanyID, OLD.CompanyID),
    TG_OP,   -- Operation type: 'INSERT', 'UPDATE', 'DELETE'
    now()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: trg_log_subscriptions
-- Calls log_subscriptions() AFTER INSERT, UPDATE, DELETE on Subscriptions table.


CREATE TRIGGER trg_log_subscriptions
AFTER INSERT OR UPDATE OR DELETE ON Subscriptions
FOR EACH ROW
EXECUTE FUNCTION log_subscriptions();


-- ===============================================
-- TABLE: Users_log
-- Stores a log record whenever a new user is added to the Users table.
-- ===============================================

CREATE TABLE Users_log (
  Userslog_id SERIAL PRIMARY KEY, -- Auto-increment log ID
  Users_id UUID,                  -- Related User ID
  date_added TIMESTAMP DEFAULT now() -- Timestamp when the log was created
);


-- TRIGGER FUNCTION: log_ekle
-- Inserts a log entry into Users_log table every time a new user is inserted.


CREATE OR REPLACE FUNCTION log_ekle()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Users_log (Users_id, date_added)
  VALUES (NEW.UserID, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Users_insert_log
-- Calls log_ekle() AFTER INSERT on Users table.


DROP TRIGGER IF EXISTS Users_insert_log ON Users;

CREATE TRIGGER Users_insert_log
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE FUNCTION log_ekle();



-- ===============================================
-- TABLE: Company_log
-- Stores a log entry whenever a new company is added to the Companies table.
-- ===============================================

CREATE TABLE Company_log (
  Companylog_id SERIAL PRIMARY KEY, -- Auto-increment log ID
  Company_id UUID,                  -- Related Company ID
  date_added TIMESTAMP DEFAULT now() -- Timestamp when the log was created
);


-- TRIGGER FUNCTION: log_ekle_companies
-- Inserts a log record into Company_log table every time a new company is inserted.


CREATE OR REPLACE FUNCTION log_ekle_companies()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Company_log (Company_id, date_added)
  VALUES (NEW.CompanyID, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Companies_insert_log
-- Calls log_ekle_companies() AFTER INSERT on Companies table.


DROP TRIGGER IF EXISTS Companies_insert_log ON Companies;

CREATE TRIGGER Companies_insert_log
AFTER INSERT ON Companies
FOR EACH ROW
EXECUTE FUNCTION log_ekle_companies();



-- ===============================================
-- TRIGGER FUNCTION: log_update
-- Inserts a log record into Users_log table every time an existing user is updated.
-- ===============================================

CREATE OR REPLACE FUNCTION log_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Users_log (Users_id, date_added)
  VALUES (NEW.UserID, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Users_update_log
-- Calls log_update() AFTER UPDATE on Users table.


DROP TRIGGER IF EXISTS Users_update_log ON Users;

CREATE TRIGGER Users_update_log
AFTER UPDATE ON Users
FOR EACH ROW
EXECUTE FUNCTION log_update();


-- ===============================================
-- TRIGGER FUNCTION: log_delete
-- Inserts a log record into Users_log table every time a user is deleted.
-- Uses OLD to access deleted row.
-- ===============================================

CREATE OR REPLACE FUNCTION log_delete()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Users_log (Users_id, date_added)
  VALUES (OLD.UserID, now());
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Users_delete_log
-- Calls log_delete() AFTER DELETE on Users table.


DROP TRIGGER IF EXISTS Users_delete_log ON Users;

CREATE TRIGGER Users_delete_log
AFTER DELETE ON Users
FOR EACH ROW
EXECUTE FUNCTION log_delete();


-- ===============================================
-- TRIGGER FUNCTION: log_update_companies
-- Inserts a log record into Company_log table every time a company record is updated.
-- Uses NEW to access updated row data.
-- ===============================================

CREATE OR REPLACE FUNCTION log_update_companies()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Company_log (Company_id, date_added)
  VALUES (NEW.CompanyID, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Companies_update_log
-- Calls log_update_companies() AFTER UPDATE on Companies table.


DROP TRIGGER IF EXISTS Companies_update_log ON Companies;

CREATE TRIGGER Companies_update_log
AFTER UPDATE ON Companies
FOR EACH ROW
EXECUTE FUNCTION log_update_companies();


-- ===============================================
-- TRIGGER FUNCTION: log_delete_companies
-- Inserts a log record into Company_log table every time a company record is deleted.
-- Uses OLD to access deleted row data.
-- ===============================================

CREATE OR REPLACE FUNCTION log_delete_companies()
RETURNS trigger AS $$
BEGIN
  INSERT INTO Company_log (Company_id, date_added)
  VALUES (OLD.CompanyID, now());
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: Companies_delete_log
-- Calls log_delete_companies() AFTER DELETE on Companies table.


DROP TRIGGER IF EXISTS Companies_delete_log ON Companies;

CREATE TRIGGER Companies_delete_log
AFTER DELETE ON Companies
FOR EACH ROW
EXECUTE FUNCTION log_delete_companies();


-- ===============================================
-- FUNCTION: Total_Invoice_Amount
-- Calculates the total invoice amount for a given user.
-- If the user has no invoices, returns 0.
-- ===============================================

CREATE OR REPLACE FUNCTION Total_Invoice_Amount(User_UUID UUID)
RETURNS NUMERIC AS $$
DECLARE 
   SumInvoice NUMERIC;
BEGIN 
   SELECT COALESCE(SUM(Amount), 0) INTO SumInvoice
   FROM Invoice 
   WHERE UserID = User_UUID;

   RETURN SumInvoice;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- EXAMPLE USAGE
-- ===============================================

-- Get all users with their total invoice amount
SELECT 
  u.UserName,
  Total_Invoice_Amount(u.UserID) AS total_amount
FROM 
  Users u;

-- List all users with IDs
SELECT UserName, UserID FROM Users;



-- ===============================================
-- FUNCTION: set_user_role
-- Automatically sets the UserRole based on UserType and identity fields.
-- If required fields are missing, raises an exception.
-- ===============================================

CREATE OR REPLACE FUNCTION set_user_role()
RETURNS TRIGGER AS $$
BEGIN
  -- If already admin, keep as is
  IF NEW.UserRole = 'admin' THEN
    RETURN NEW;
  END IF;

  -- Set role based on user type and identity fields
  IF NEW.UserType = 'kurumsal' AND NEW.VKN IS NOT NULL THEN
    NEW.UserRole := 'corp_member';

  ELSIF NEW.UserType = 'bireysel' AND NEW.TCKN IS NOT NULL THEN
    NEW.UserRole := 'ind_member';

  ELSIF NEW.UserType = 'system_user' THEN
    NEW.UserRole := 'admin';

  ELSE
    RAISE EXCEPTION 'UserRole could not be set. Missing UserType or identity field.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER: trg_set_user_role
-- Executes before INSERT or UPDATE on Users table
-- Ensures the UserRole is set automatically.


DROP TRIGGER IF EXISTS trg_set_user_role ON Users;

CREATE TRIGGER trg_set_user_role
BEFORE INSERT OR UPDATE ON Users
FOR EACH ROW
EXECUTE FUNCTION set_user_role();

-- ===============================================
-- Check all triggers on Users table (optional)
-- ===============================================
SELECT tgname FROM pg_trigger WHERE tgrelid = 'users'::regclass;


-- ================================================================
-- USER AND ROLE MANAGEMENT
-- ================================================================

-- ADMIN USER -----------------------------------------------------
-- Creates an admin user and assigns full privileges

CREATE ROLE admin_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;


-- CORP_MEMBER ROLE -----------------------------------------------
-- Kurumsal kullanıcılar için role:
-- Allows SELECT on all tables + INSERT, UPDATE on Invoice table

CREATE ROLE corp_member_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO corp_member_role;
GRANT INSERT, UPDATE ON Invoice TO corp_member_role;

-- IND_MEMBER ROLE ------------------------------------------------
-- Bireysel kullanıcılar için role:
-- Allows SELECT on all tables (read-only)

CREATE ROLE ind_member_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO ind_member_role;

-- Check all roles ------------------------------------------------
SELECT rolname FROM pg_roles;


-- ================================================================
-- VIEW : ActiveCompanyServices
-- ================================================================
-- Lists all services that belong to active companies
-- Aktif şirketlerin sahip olduğu tüm hizmetleri listeler

CREATE VIEW ActiveCompanyServices AS
SELECT 
  c.CompanyName,   -- Company name
  s.ServiceName,   -- Related service name
  c.Status         -- Company status (ENUM: 'Aktif' / 'Pasif')
FROM 
  Companies c
JOIN 
  CompanyServices cs ON c.CompanyID = cs.CompanyID
JOIN 
  Services s ON cs.ServiceID = s.ServiceID
WHERE 
  c.Status = 'Aktif'; -- Only active companies

-- Test the view 

SELECT * FROM ActiveCompanyServices;