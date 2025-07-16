CREATE DATABASE ProyectoMysql;
USE ProyectoMysql;
CREATE TABLE IF NOT EXISTS countries (
	iscode VARCHAR(6) PRIMARY KEY,
	name VARCHAR(50) UNIQUE,
    alfaisotwo VARCHAR(2) UNIQUE,
    alfaisothree VARCHAR(4) UNIQUE
);

CREATE TABLE IF NOT EXISTS stateorregions (
	code VARCHAR(6) PRIMARY KEY,
	name VARCHAR(60) UNIQUE,
    country_id VARCHAR(6),
    code3166 VARCHAR(10) UNIQUE,
    subdivision_id INT(11)
);

CREATE TABLE IF NOT EXISTS subdivisioncategories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    description VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS citiesormunicipalities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(6),
    name VARCHAR(60),
    statereg_id VARCHAR(6)
);

CREATE TABLE IF NOT EXISTS typesidentifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    description VARCHAR(60) UNIQUE,
    sufix VARCHAR(5) UNIQUE
);

CREATE TABLE IF NOT EXISTS companies (
    id VARCHAR(20) PRIMARY KEY,
    type_id INT,
    name VARCHAR(80),
    category_id INT(11),
    city_id INT,
    audience_id INT,
    cellphone VARCHAR(15) UNIQUE,
    email VARCHAR(80) UNIQUE
);

CREATE TABLE IF NOT EXISTS categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    description VARCHAR(60) UNIQUE
); 

CREATE TABLE IF NOT EXISTS favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    company_id VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS details_favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    company_id VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(80),
    city_id INT,
    audience_id INT,
    cellphone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    address VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS memberships (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS companyproducts (
    company_id VARCHAR(20),
    product_id INT,
    price DOUBLE,
    unitmeasure_id INT,
    PRIMARY KEY (company_id, product_id)
);

CREATE TABLE IF NOT EXISTS products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(60) UNIQUE,
    detail TEXT,
    price DOUBLE,
    category_id INT(11),
    image VARCHAR(80)
);

CREATE TABLE IF NOT EXISTS quality_products (
    product_id INT,
    customer_id INT,
    poll_id INT,
    company_id VARCHAR(20),
    daterating DATETIME,
    rating DOUBLE,
    PRIMARY KEY (product_id,customer_id,poll_id,company_id)
);

CREATE TABLE IF NOT EXISTS membershipperiods (
    membership_id INT(11),
    period_id INT(11),
    price DOUBLE,
    PRIMARY KEY (membership_id,period_id)
);

CREATE TABLE IF NOT EXISTS periods (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS audiences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    description VARCHAR(60)
);

CREATE TABLE IF NOT EXISTS unitofmeasure (
    id INT PRIMARY KEY AUTO_INCREMENT,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS benefits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    description VARCHAR(80),
    detail TEXT
);

CREATE TABLE IF NOT EXISTS membershipbenefits (
    membership_id INT(11),
    period_id INT(11),
    audience_id INT(11),
    benefit_id INT(11),
    PRIMARY KEY (membership_id,period_id,audience_id,benefit_id)
);

CREATE TABLE IF NOT EXISTS audiencebenefits (
    audience_id INT(11),
    benefit_id INT(11),
    PRIMARY KEY (audience_id,benefit_id)
);

CREATE TABLE IF NOT EXISTS rates (
    customer_id INT,
    company_id VARCHAR(20),
    poll_id INT,
    daterating DATETIME,
    rating DOUBLE,
    PRIMARY KEY (customer_id,company_id,poll_id)
);

CREATE TABLE IF NOT EXISTS polls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(80) UNIQUE,
    description TEXT,
    isactive BOOLEAN,
    categorypoll_id INT
);

CREATE TABLE IF NOT EXISTS categories_polls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(80) UNIQUE
);

ALTER TABLE stateorregions
ADD CONSTRAINT fk_stateorregions_country
    FOREIGN KEY (country_id) REFERENCES countries(iscode),
ADD CONSTRAINT fk_stateorregions_subdivision
    FOREIGN KEY (subdivision_id) REFERENCES subdivisioncategories(id);

ALTER TABLE citiesormunicipalities
ADD CONSTRAINT fk_cities_statereg
    FOREIGN KEY (statereg_id) REFERENCES stateorregions(code);

ALTER TABLE companies
ADD CONSTRAINT fk_companies_type
    FOREIGN KEY (type_id) REFERENCES typesidentifications(id),
ADD CONSTRAINT fk_companies_category
    FOREIGN KEY (category_id) REFERENCES categories(id),
ADD CONSTRAINT fk_companies_city
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(id),
ADD CONSTRAINT fk_companies_audience
    FOREIGN KEY (audience_id) REFERENCES audiences(id);

ALTER TABLE favorites
ADD CONSTRAINT fk_favorites_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id),
ADD CONSTRAINT fk_favorites_company
    FOREIGN KEY (company_id) REFERENCES companies(id);

ALTER TABLE details_favorites
ADD CONSTRAINT fk_detailsfavorites_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id),
ADD CONSTRAINT fk_detailsfavorites_company
    FOREIGN KEY (company_id) REFERENCES companies(id);

ALTER TABLE customers
ADD CONSTRAINT fk_customers_city
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(id),
ADD CONSTRAINT fk_customers_audience
    FOREIGN KEY (audience_id) REFERENCES audiences(id);

ALTER TABLE companyproducts
ADD CONSTRAINT fk_companyproducts_company
    FOREIGN KEY (company_id) REFERENCES companies(id),
ADD CONSTRAINT fk_companyproducts_product
    FOREIGN KEY (product_id) REFERENCES products(id),
ADD CONSTRAINT fk_companyproducts_unit
    FOREIGN KEY (unitmeasure_id) REFERENCES unitofmeasure(id);

ALTER TABLE products
ADD CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(id);

ALTER TABLE quality_products
ADD CONSTRAINT fk_quality_product
    FOREIGN KEY (product_id) REFERENCES products(id),
ADD CONSTRAINT fk_quality_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id),
ADD CONSTRAINT fk_quality_poll
    FOREIGN KEY (poll_id) REFERENCES polls(id),
ADD CONSTRAINT fk_quality_company
    FOREIGN KEY (company_id) REFERENCES companies(id);

ALTER TABLE membershipperiods
ADD CONSTRAINT fk_membershipperiods_membership
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
ADD CONSTRAINT fk_membershipperiods_period
    FOREIGN KEY (period_id) REFERENCES periods(id);

ALTER TABLE membershipbenefits
ADD CONSTRAINT fk_membershipbenefits_membership
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
ADD CONSTRAINT fk_membershipbenefits_period
    FOREIGN KEY (period_id) REFERENCES periods(id),
ADD CONSTRAINT fk_membershipbenefits_audience
    FOREIGN KEY (audience_id) REFERENCES audiences(id),
ADD CONSTRAINT fk_membershipbenefits_benefit
    FOREIGN KEY (benefit_id) REFERENCES benefits(id);

ALTER TABLE audiencebenefits
ADD CONSTRAINT fk_audiencebenefits_audience
    FOREIGN KEY (audience_id) REFERENCES audiences(id),
ADD CONSTRAINT fk_audiencebenefits_benefit
    FOREIGN KEY (benefit_id) REFERENCES benefits(id);

ALTER TABLE rates
ADD CONSTRAINT fk_rates_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id),
ADD CONSTRAINT fk_rates_company
    FOREIGN KEY (company_id) REFERENCES companies(id),
ADD CONSTRAINT fk_rates_poll
    FOREIGN KEY (poll_id) REFERENCES polls(id);

ALTER TABLE polls
ADD CONSTRAINT fk_polls_category
    FOREIGN KEY (categorypoll_id) REFERENCES categories_polls(id);