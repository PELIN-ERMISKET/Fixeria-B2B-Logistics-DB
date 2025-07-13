-- ============================================================
-- QUERY 1: Companies with sub services but no additional services
-- ============================================================
-- Lists companies that have at least one sub service
-- but do not have any additional services linked.
SELECT 
  co.CompanyName
FROM 
  Companies co
LEFT JOIN 
  CompanyAdditionalServices cas ON cas.CompanyID = co.CompanyID
INNER JOIN 
  CompanySubServices cs ON cs.CompanyID = co.CompanyID
WHERE 
  cas.AdditionalServiceID IS NULL;


-- ============================================================
-- QUERY 2: Companies with at least 2 distinct additional services
-- ============================================================
-- Lists companies that offer at least 2 different additional services.
SELECT 
  co.CompanyName 
FROM 
  Companies co
JOIN 
  AdditionalServices ad ON ad.CompanyID = co.CompanyID
GROUP BY 
  co.CompanyName
HAVING 
  COUNT(DISTINCT ad.AdditionalServiceID) >= 2;


-- ============================================================
-- QUERY 3: Active companies located in Istanbul with total invoice stats
-- ============================================================
-- For each active company in Istanbul, shows contact info,
-- total invoice amount and latest invoice date.
SELECT 
  co.CompanyName, co.CompanyPhone, co.CompanyEmail, co.CompanyAddress, co.CompanyWebsite,
  COALESCE(SUM(i.Amount), 0) AS TotalInvoiceAmount,
  MAX(i.InvoiceDate) AS LastInvoiceDate
FROM 
  Companies co
LEFT JOIN 
  Invoice i ON co.CompanyID = i.CompanyID
WHERE 
  co.CompanyAddress ILIKE '%İstanbul%'
  AND co.Status = 'Aktif'
GROUP BY 
  co.CompanyName, co.CompanyPhone, co.CompanyEmail, co.CompanyAddress, co.CompanyWebsite
ORDER BY 
  TotalInvoiceAmount DESC;


-- ============================================================
-- QUERY 4: Sub services and additional service count for "Ekol Lojistik"
-- ============================================================
-- Shows all sub services for Ekol Lojistik and its total additional service count.

SELECT 
  s.SubServiceName,
  (SELECT COUNT(*) 
   FROM CompanyAdditionalServices cas
   WHERE cas.CompanyID = co.CompanyID) AS AdditionalServiceCount
FROM 
  Companies co
JOIN 
  CompanySubServices cs ON co.CompanyID = cs.CompanyID
JOIN 
  SubServices s ON cs.SubServiceID = s.SubServiceID
WHERE 
  co.CompanyName = 'Ekol Lojistik';


-- ============================================================
-- QUERY 5: Active individual users with invoices and their total/first invoice
-- ============================================================
-- Lists active individual users who have invoices,
-- showing total invoice amount and the date of their first invoice.

SELECT 
  u.UserName,
  SUM(i.Amount) AS TotalAmount,
  MIN(i.InvoiceDate) AS FirstInvoiceDate
FROM 
  Invoice i
JOIN 
  Users u ON u.UserID = i.UserID
WHERE 
  u.UserType = 'bireysel'
  AND u.Status = 1
GROUP BY 
  u.UserName
ORDER BY 
  TotalAmount DESC;


-- ============================================================
-- QUERY 6: Users invoiced within a specific date range with ranking
-- ============================================================
-- Shows total invoice amount and rank for users who received invoices
-- in the specified date range.

SELECT 
  u.UserName,
  SUM(i.Amount) AS TotalAmount,
  RANK() OVER (ORDER BY SUM(i.Amount) DESC) AS UserRank
FROM 
  Invoice i
JOIN 
  Users u ON u.UserID = i.UserID
WHERE 
  i.InvoiceDate BETWEEN '2025-06-20' AND '2025-06-22'
GROUP BY 
  u.UserName;


-- ============================================================
-- QUERY 7: Total invoice amount and ranking by city
-- ============================================================
-- Shows each city's total invoice amount and its rank by total.

SELECT 
  ci.CityName,
  SUM(i.Amount) AS TotalAmount,
  RANK() OVER (ORDER BY SUM(i.Amount) DESC) AS CityRank
FROM 
  Invoice i
JOIN 
  Companies co ON i.CompanyID = co.CompanyID
JOIN 
  Cities ci ON co.CityID = ci.CityID
GROUP BY 
  ci.CityName;


-- ============================================================
-- QUERY 8: Last 10 entries in Users log table
-- ============================================================
-- Shows the last 10 log records for user operations with timestamps.

SELECT 
  ul.Userslog_id,
  ul.Users_id,
  u.UserName,
  ul.date_added
FROM 
  Users_log ul
JOIN 
  Users u ON ul.Users_id = u.UserID
ORDER BY 
  ul.date_added DESC
LIMIT 10;

