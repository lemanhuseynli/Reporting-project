- 1. Table-ləri yaradiriq                                      
CREATE TABLE customers(customer_no NUMBER PRIMARY KEY, 
                       customer_type VARCHAR2(1),
                       full_name VARCHAR2(50),
                       address_line1 VARCHAR2(100),
                       address_line2 VARCHAR2(100),
                       address_line3 VARCHAR2(100),
                       address_line4  VARCHAR2(100),
                       country VARCHAR2(5),
                       LANGUAGE VARCHAR2(5),
                       branch_id NUMBER,
                       shexs_ves_no VARCHAR2(15),
                       LIMIT NUMBER,
                       limit_ccy NUMBER,
                       CONSTRAINT branch_id_fk FOREIGN KEY(branch_id) REFERENCES branch(branch_id),
                       CONSTRAINT limit_ccy_fk FOREIGN KEY(limit_ccy) REFERENCES currency(currency_id));
                        
CREATE TABLE branch(branch_id NUMBER PRIMARY KEY, 
                    branch_description VARCHAR2(50));                       

CREATE TABLE currency(currency_id NUMBER PRIMARY KEY, 
                      currency_code VARCHAR2(3));                           
                   
CREATE TABLE exchange_rate(exchange_date DATE, 
                           currency_id NUMBER,
                           exchange_rate NUMBER,
                           CONSTRAINT currency_id_fk FOREIGN KEY(currency_id) REFERENCES currency(currency_id));      
                            
CREATE TABLE transfer(cif NUMBER, 
                      transfer_amount NUMBER,
                      currency_id NUMBER,
                      trn_dt DATE,
                      CONSTRAINT cif_fk FOREIGN KEY(cif) REFERENCES customers(customer_no),
                      CONSTRAINT ccy_id_fk FOREIGN KEY(currency_id) REFERENCES currency(currency_id));                                                
                      
SELECT * FROM customers FOR UPDATE;                      
SELECT * FROM branch FOR UPDATE;   
SELECT * FROM currency FOR UPDATE;  
SELECT * FROM exchange_rate FOR UPDATE; 
SELECT * FROM transfer FOR UPDATE;

DROP TABLE customers;
DROP TABLE branch;
DROP TABLE currency;
DROP TABLE exchange_rate;
DROP TABLE transfer;

-- Bir Package yaratmaq 2 procedur və 1 functiondan ibarət olmalır.Məzənnəni tapan funksiyanı bu packagedə yaratmaq lazım.
-- Funksiyanın içində Pre-defined exceptionlardan istifadə etmək vacibdir.
-- Update_Customer_Tr adlı iki procedure yaratmaq və overloadingdən istifadə etmək.
-- 1. Procedurlardan biri customerID parametrini qəbul edir və ötürdüyünüz customerİD -ə görə 
--   Transfer_amountu 10 faiz artıraraq update edir.
-- 2. Procedurlardan digəri customerID və Trn_date parametrlərini qəbul edir və ötürdüyünüz parametrlərə görə 
--   əgər müştərinin trn_dt-i parametr olaraq ötürülən trn_dt-dən kiçikdirsə,Transfer Amountu 
--   Transfer table-indəki ən böyük transfer məbləğinin 20 faizi qədər artırır əks halda Transfer Amountu 
--   Transfer table-indəki ən kiçik transfer məbləğinin 20 faizi qədər artırır.

--specification hisse
CREATE OR REPLACE PACKAGE customer_pck 
IS

    PROCEDURE update_customer_tr(p_customerID NUMBER);
    PROCEDURE update_customer_tr(p_customerID NUMBER, p_trn_date DATE);
    FUNCTION get_exchange_rate(p_currency_id VARCHAR2,p_date DATE) RETURN NUMBER;

END;

--body hissesi
CREATE OR REPLACE PACKAGE BODY customer_pck
IS
    -- birinci taskdaki procedure
    PROCEDURE update_customer_tr(p_customerID NUMBER) 
    IS
    BEGIN
        UPDATE transfer
        SET transfer_amount = transfer_amount + (transfer_amount * 0.10)
        WHERE cif = p_customerID;
    END;
    
    -- ikinci taskdaki procedure
    PROCEDURE update_customer_tr(p_customerID NUMBER,p_trn_date DATE)
    IS
    v_maxTransferAmount NUMBER;
    v_minTransferAmount NUMBER;
    BEGIN
      -- Musterinin en boyuk transfer meblegi
      SELECT MAX(transfer_amount)
      INTO v_maxTransferAmount
      FROM Transfer;

      -- Musterinin en kicik transfer meblegi
      SELECT MIN(transfer_amount)
      INTO v_minTransferAmount 
      FROM Transfer;

      UPDATE Transfer
      SET transfer_amount = CASE WHEN Trn_dt < p_Trn_date THEN transfer_amount + 0.2 * v_maxTransferAmount
                                 ELSE transfer_amount + 0.2 * v_minTransferAmount
                            END
      WHERE cif = p_customerID;
    END;
    
    -- Məzənnəni əldə etmək üçün funksiya yaradiriq.
    FUNCTION get_exchange_rate(p_currency_id VARCHAR2,p_date DATE) 
    RETURN NUMBER 
    iS
        v_exchange_rate NUMBER;
    BEGIN
        SELECT exchange_rate
        INTO v_exchange_rate
        FROM exchange_rate e
        WHERE currency_id = p_currency_id AND exchange_date = p_date;
        RETURN v_exchange_rate;
        
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          RETURN NULL;
    END;
END;

--error'u yoxlayiriq
SELECT * FROM User_Errors e where e.name=UPPER('customer_pck');

--procedure birin yoxlanilmasi
BEGIN
     customer_pck.update_customer_tr(9758573);
END;

SELECT * FROM transfer;
--procedure ikinin yoxlanilmasi
BEGIN
     customer_pck.update_customer_tr(9758573,'01.jan.2023');
END;

--funksiyanin yoxlanilmasi
BEGIN
  dbms_output.put_line(customer_pck.get_exchange_rate(944,'24.feb.2019'));
END;

SELECT * FROM exchange_rate;
SELECT * FROM transfer;

-- Packagedə olan procedur-ları run etmək vacibdir və funksiyanı Forma 1 və Forma 2 selectin içində çağırmaq lazım.
-- Lazım olan Hesabat formaları layihə işi excelinin Hesabat Forması sheetində əks olunmuşdur.
-- Forms 1 Hesabat :
-- 1. Forma 1 -də Siz Şəhərlər üzrə 24.02.2019 tarixinə verilmiş məzənnələrə əsasən limit summaları
--    və Transfer tablesindəki köçürmə məbləğlərini əks etdirməlisiniz.Summalar AZN ekvivalentində əks olunmalıdır. 
--    PL SQL tətbiq edərək məzənnələri tapan funksiya yaradıb həmin funksiyanı sql selectin içində yazaraq çağırın. 
--    Bu funksiya sizə tarix,valutaya görə həmin tarixdə həmin valutanın qaytaracağı məzənnəni gətirməlidir.
--    Elə Select yazmalısınız ki , 12 cell qaytarsın .Yəni iki sətirdən ibarət və 6 sütundan olsun.
SELECT
    customer_type,
    SUM(CASE WHEN branch_description LIKE '%Baki%' THEN total_limit
             ELSE 0 END) AS total_limit_baku,
    SUM(CASE WHEN branch_description LIKE '%Baki%' THEN total_transfer 
             ELSE 0 END) AS total_transfer_baku,
    SUM(CASE WHEN branch_description LIKE '%Sumqayit%' THEN total_limit
             ELSE 0 END) AS total_limit_sumqayit,
    SUM(CASE WHEN branch_description LIKE '%Sumqayit%' THEN total_transfer 
             ELSE 0 END) AS total_transfer_sumqayit,
    SUM(CASE WHEN branch_description LIKE '%Mingecevir%' THEN total_limit
             ELSE 0 END) AS total_limit_mingecevir,
    SUM(CASE WHEN branch_description LIKE '%Mingecevir%' THEN total_transfer  
             ELSE 0 END) AS total_transfer_mingecevir
FROM (
    SELECT
        c.customer_type,
        b.branch_description,
        c.limit * get_exchange_rate(c.limit_ccy,e.exchange_date) AS total_limit,
        t.transfer_amount * get_exchange_rate(c.limit_ccy,e.exchange_date) AS total_transfer,
        ROW_NUMBER() OVER(PARTITION BY c.customer_no ORDER BY c.customer_no) AS rownumberr
    FROM
        Customers c
    LEFT JOIN
        Branch b ON c.branch_id = b.branch_id
    LEFT JOIN
        Transfer t ON c.customer_no = t.cif
    LEFT JOIN
        Currency cur ON c.limit_ccy = cur.currency_id
    LEFT JOIN 
        Exchange_rate e ON e.currency_id=cur.currency_id AND e.exchange_date='24.feb.2019'
)  subquery
WHERE 
    rownumberr = 1 
GROUP BY 
    customer_type;
-----------------------------------------------------------------------------------------------------------------------------
--analitik funksiya ile
SELECT DISTINCT
    customer_type,
    SUM(CASE WHEN branch_description LIKE '%Baki%' THEN total_limit 
             ELSE 0 END) OVER (PARTITION BY customer_type) AS total_limit_baku,
    SUM(CASE WHEN branch_description LIKE '%Baki%' THEN total_transfer 
             ELSE 0 END) OVER (PARTITION BY customer_type) AS total_transfer_baku,
    SUM(CASE WHEN branch_description LIKE '%Sumqayit%' THEN total_limit 
             ELSE 0 END) OVER (PARTITION BY customer_type) AS total_limit_sumqayit,
    SUM(CASE WHEN branch_description LIKE '%Sumqayit%' THEN total_transfer 
             ELSE 0 END) OVER (PARTITION BY customer_type) AS total_transfer_sumqayit,
    SUM(CASE WHEN branch_description LIKE '%Mingecevir%' THEN total_limit 
             ELSE 0 END) OVER (PARTITION BY customer_type) AS total_limit_mingecevir,
    SUM(CASE WHEN branch_description LIKE '%Mingecevir%' THEN total_transfer 
             ELSE 0 END) OVER (PARTITION BY customer_type) AS total_transfer_mingecevir
FROM (
    SELECT
        c.customer_type,
        b.branch_description,
        c.limit * get_exchange_rate(c.limit_ccy,e.exchange_date) AS total_limit,
        t.transfer_amount * get_exchange_rate(c.limit_ccy,e.exchange_date) AS total_transfer,
        row_number() OVER(PARTITION BY c.customer_no ORDER BY c.customer_no) AS rownumberr
    FROM
        Customers c
    LEFT JOIN
        Branch b ON c.branch_id = b.branch_id
    LEFT JOIN
        Transfer t ON c.customer_no = t.cif
    LEFT JOIN
        Currency cur ON c.limit_ccy = cur.currency_id
    LEFT JOIN 
        Exchange_rate e ON e.currency_id=cur.currency_id AND e.exchange_date='24.feb.2019'
) subquery
WHERE 
    rownumberr=1
ORDER BY 
    customer_type;
    
-- Forma 2-də siz Ölkələr üzrə (bunu customer tablesinin country columna əsasən təyin edə bilərsiniz.AZ-yazılanlar 
-- Azərbaycan və digərləri də muvafiq olaraq decodla çevirə bilərsiniz.Hansı sətirdəki country nulldur onun əvəzinə 
-- AZ yəni Azərbaycan kimi götürmək vacibdir.Excelin C,D,E sütunlarında müvafiq ölkələr üzrə Customer tablesindəki 
-- limit summalar AZN ekvivalentində götürülməlidir.Yəni məzənnəyə vurmaqla .F,G,H sütunlarındakılar isə Müvafiq 
-- ölkələr üzrə sayı ifadə edir.Elə Select yazmalısınız ki 12 cell qaytarsın.
-- Yəni iki sətirdən ibarət və 6 sütundan ibarət olsun.  
SELECT 
    customer_type AS vetendasliq,
    SUM(DECODE(c.country, 'AZ', c.limit * get_exchange_rate(c.limit_ccy,e.exchange_date), 0)) AS Azerbaycan_Limit,
    SUM(DECODE(c.country, 'TYR', c.limit * get_exchange_rate(c.limit_ccy,e.exchange_date), 0)) AS Turkiye_Limit,
    SUM(DECODE(c.country, 'RU', c.limit * get_exchange_rate(c.limit_ccy,e.exchange_date), 0)) AS Rusiya_Limit,
    COUNT(DECODE(NVL(c.country,'AZ'), 'AZ',1)) AS Azerbaycan_Count,
    COUNT(DECODE(c.country, 'TYR', 1)) AS Turkiye_Count,
    COUNT(DECODE(c.country, 'RU', 1)) AS Rusiya_Count
FROM Customers c
LEFT JOIN Exchange_rate e ON e.currency_id=c.limit_ccy AND e.exchange_date='01.march.2019'
GROUP BY customer_type;

-----------------------------------------------------------------------------------------------------------------------
--analitik funksiya ile
SELECT DISTINCT
    customer_type AS vetendasliq,
    SUM(DECODE(c.country, 'AZ', c.limit * get_exchange_rate(c.limit_ccy, e.exchange_date), 0)) 
        OVER (PARTITION BY customer_type) AS Azerbaycan_Limit,
    SUM(DECODE(c.country, 'TYR', c.limit * get_exchange_rate(c.limit_ccy, e.exchange_date), 0)) 
        OVER (PARTITION BY customer_type) AS Turkiye_Limit,
    SUM(DECODE(c.country, 'RU', c.limit * get_exchange_rate(c.limit_ccy, e.exchange_date), 0)) 
        OVER (PARTITION BY customer_type) AS Rusiya_Limit,    
    COUNT(DECODE(NVL(c.country,'AZ'), 'AZ', 1)) 
        OVER (PARTITION BY customer_type) AS Azerbaycan_Count,
    COUNT(DECODE(c.country, 'TYR', 1)) 
        OVER (PARTITION BY customer_type) AS Turkiye_Count,
    COUNT(DECODE(c.country, 'RU', 1)) 
        OVER (PARTITION BY customer_type) AS Rusiya_Count
FROM Customers c
LEFT JOIN Exchange_rate e ON e.currency_id=c.limit_ccy AND e.exchange_date='01.march.2019';
