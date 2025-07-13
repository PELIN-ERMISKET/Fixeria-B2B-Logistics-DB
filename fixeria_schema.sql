CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--COMPANIES TABLE

CREATE TYPE company_status AS ENUM ('Aktif', 'Pasif');


CREATE TABLE Companies (
    CompanyID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    CompanyName VARCHAR(100) NOT NULL UNIQUE, 
    CompanyPhone VARCHAR(15) UNIQUE,
    CompanyEmail VARCHAR(100) UNIQUE,
    CompanyAddress TEXT,
    CompanyWebsite VARCHAR(100) UNIQUE,
    CityID UUID REFERENCES Cities(CityID),
    CountryID UUID REFERENCES Countries(CountryID),
    Status company_status DEFAULT 'Aktif',   -- Company status: 'Aktif' or 'Pasif'
    RetentionDays INT DEFAULT 180            --  Retention period in days (default 180)
);


--CITIES TABLE

CREATE TABLE Cities (
    CityID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    CityName VARCHAR(50) NOT NULL,    -- Name of the city
    CountryID UUID REFERENCES Countries(CountryID) 
);


--COUNTRIES TABLE

CREATE TABLE Countries (
    CountryID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    CountryName VARCHAR(50) NOT NULL UNIQUE 
);



--SERVICE CATEGORIES TABLE

CREATE TABLE ServiceCategories (
    CategoryID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    CategoryName VARCHAR(50) NOT NULL UNIQUE  -- Name of the service category
);



--SUB SERVICES TABLE


CREATE TABLE SubServices (
    SubServiceID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    SubServiceName VARCHAR(50) NOT NULL UNIQUE, 
    ServiceID UUID REFERENCES Services(ServiceID)
);



--COMPANY SERVICES TABLE

CREATE TABLE CompanyServices (
    CompanyID UUID REFERENCES Companies(CompanyID), 
    ServiceID UUID REFERENCES Services(ServiceID),   
    PRIMARY KEY (CompanyID, ServiceID)  
);



--SERVICES TABLE

CREATE TABLE Services (
    ServiceID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    ServiceName VARCHAR(50) NOT NULL UNIQUE,
    CategoryID UUID REFERENCES ServiceCategories(CategoryID) 
);




--ADDITIONAL SERVICES TABLE

CREATE TABLE AdditionalServices (
    AdditionalServiceID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    AdditionalServiceName VARCHAR(50) NOT NULL UNIQUE,
    CompanyID UUID REFERENCES Companies(CompanyID) 
);



--USERS TABLE

CREATE TABLE Users (
    UserID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    UserName VARCHAR(50) NOT NULL,
    UserEmail VARCHAR(100) UNIQUE NOT NULL, 
    UserPassword VARCHAR(100) NOT NULL, 
    UserRole VARCHAR(20) NOT NULL,  -- Role of the user (admin, member, etc.)
    UserType VARCHAR(15) NOT NULL CHECK (UserType IN ('bireysel', 'kurumsal', 'system_user')), 
    VKN VARCHAR(10) UNIQUE,  -- Tax number for corporate users (optional)
    TCKN VARCHAR(11) UNIQUE, -- National ID for individual users (optional)
    Status SMALLINT DEFAULT 1 CHECK (Status IN (1, 2)) -- 1 = Active, 2 = Inactive
);


-- INVOICE TABLE

CREATE TYPE invoice_type AS ENUM ('Subscription', 'Service', 'Other');

CREATE TABLE Invoice (
    InvoiceID UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    InvoiceNumber VARCHAR(50) NOT NULL UNIQUE, 
    UserID UUID REFERENCES Users(UserID),      -- References the user who owns the invoice
    CompanyID UUID REFERENCES Companies(CompanyID), 
    SubscriptionID UUID REFERENCES Subscriptions(SubscriptionID), -- FK to link related subscription
    ETTN VARCHAR(36) UNIQUE NOT NULL,          -- Unique electronic invoice identifier (ETTN)
    InvoiceDate DATE NOT NULL,                 -- Date the invoice was issued
    Amount DECIMAL(10, 2) NOT NULL,            -- Total invoice amount
    InvoiceType invoice_type DEFAULT 'Service', -- Invoice type: Subscription, Service, Other
    RetentionDays INT DEFAULT 180,             -- Retention period in days (default 180)
    RetentionEndDate DATE                      -- Retention end date (calculated by trigger)
);


--COMPANYSUBSERVICES TABLE

CREATE TABLE CompanySubServices (
    CompanyID UUID REFERENCES Companies(CompanyID),
    SubServiceID UUID REFERENCES SubServices(SubServiceID),
    PRIMARY KEY (CompanyID, SubServiceID)
);


--COMPANYADDITIONALSERVICES TABLE

CREATE TABLE CompanyAdditionalServices (
    CompanyID UUID REFERENCES Companies(CompanyID),
    AdditionalServiceID UUID REFERENCES AdditionalServices(AdditionalServiceID),
    PRIMARY KEY (CompanyID, AdditionalServiceID)
);


-- PAYMENTS TABLE
-- Stores individual payment transactions related to subscriptions or invoices.


CREATE TABLE Payments (
  PaymentID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),        -- Unique ID for each payment
  SubscriptionID UUID REFERENCES Subscriptions(SubscriptionID), -- Related subscription
  InvoiceID UUID REFERENCES Invoice(InvoiceID),                 -- Related invoice
  CompanyID UUID REFERENCES Companies(CompanyID),               -- Related company
  PaymentDate DATE NOT NULL,                                    -- Date of payment
  PaymentAmount DECIMAL(10,2) NOT NULL,                         -- Amount paid
  PaymentMethod VARCHAR(50),                                    -- e.g. Credit Card, Bank Transfer
  PaymentReference VARCHAR(100)                                 -- External transaction/reference number
);

--SUBSCRIPTION TABLE

CREATE TYPE subscription_type AS ENUM ('Basic', 'Premium');
CREATE TYPE subscription_status AS ENUM ('Aktif', 'Pasif', 'Iptal', 'Beklemede');

CREATE TABLE Subscriptions (
    SubscriptionID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),          -- Unique ID for each subscription record
    CompanyID UUID NOT NULL REFERENCES Companies(CompanyID),             
    SubscriptionType subscription_type NOT NULL DEFAULT 'Basic',         -- Subscription plan type
    StartDate DATE NOT NULL,                                             -- Start date of the subscription
    EndDate DATE NOT NULL,                                               -- End date of the subscription
    PaymentAmount DECIMAL(10, 2) NOT NULL,                               -- Fee amount for the subscription
    Subscription_status subscription_status NOT NULL DEFAULT 'Beklemede',
    PaymentMethod VARCHAR(50),                                           -- How the payment was made (Credit Card, Transfer, etc.)
    PaymentReference VARCHAR(100)                                        -- Reference number for payment transaction
);



