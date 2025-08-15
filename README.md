# Project Report: End-to-End Healthcare Data Pipeline and Analytics Platform

## 1. Introduction

Healthcare data is fragmented across multiple systems, making it difficult for patients and insurers to make cost-effective, quality-driven decisions. This project aims to bridge that gap by developing a **cloud-based end-to-end data pipeline and web application** that enables patients and insurers to explore treatment costs, hospital quality, and insurance plan comparisons.

The solution integrates **Azure Data Factory (ADF)**, **Databricks with Medallion Architecture**, **Delta Live Tables**, **Azure SQL Serverless Database**, and a **Flask + Bootstrap web application** to deliver insights through a user-friendly interface.

---

## 2. Objectives

The project was designed with the following objectives:

- Automate ingestion of raw healthcare data (pricing, claims, hospital quality metrics).  
- Apply scalable transformation and curation using **Databricks and Delta Live Tables**.  
- Provide a queryable **SQL layer** for analytics without infrastructure management.  
- Deliver a **Flask web application** that allows patients to search by procedure (CPT code), hospital, and insurance plan.  
- Provide **best options and comparisons** for hospitals and insurance plans based on negotiated rates and quality.  

---

## 3. System Architecture

The solution follows the **Medallion Architecture (Bronze → Silver → Gold)** pattern.

### 3.1 Data Flow

1. **Data Ingestion (Bronze Layer)**  
   - Implemented via **Azure Data Factory (ADF)**.  
   - Extracted raw data from CSV/JSON files, APIs, and third-party feeds.  
   - Stored raw datasets in **Azure Data Lake Storage (ADLS) containers**.  

2. **Transformation & Curation (Silver & Gold Layers)**  
   - Processed in **Databricks using Delta Live Tables**.  
   - Applied schema validation, null handling, and normalization of hospital IDs, CPT codes, and payer plan names.  
   - Business logic enriched data with:  
     - Hospital quality scores  
     - Insurance negotiation rates  
     - Aggregated statistics (min, max, discounted cash price)  

3. **Processed Storage & Query Layer**  
   - Curated data written into an **Azure SQL Serverless Database**.  
   - Optimized with partitioning on CPT codes and payer IDs for faster queries.  
   - Connected to **Visual Studio Code** for SQL development and schema testing.  

4. **Analytics & Web Application Layer**  
   - Developed a **Flask application** (`app.py`) exposing REST endpoints (`/search`, `/testdb`).  
   - Frontend built with **Bootstrap 5 + jQuery** (`index.html`).  
   - User workflow:  
     - Input CPT Code  
     - (Optional) Filter by hospital and/or insurance plan  
     - Receive results: hospital details, negotiated rates, comparisons, and recommendations.  

---

## 4. Implementation

### 4.1 Backend (Flask Application)

- **Database Connectivity:** SQLAlchemy/ODBC connection to Azure SQL Serverless DB.  
- **APIs:**  
  - `/testdb` → Validates DB connection.  
  - `/search` → Accepts JSON payload (`code`, `plan_name`, `hospital_id`) and queries the database for matching results.  
- **Logic:**  
  - Returns charge details (gross, discounted cash price, negotiated rates, min/max).  
  - Identifies **best hospital** and **best insurance plan** with the lowest negotiated rate.  
- **Error Handling:** JSON responses with structured error messages.  

### 4.2 Frontend (`index.html`)

- **Frameworks Used:** Bootstrap 5, Font Awesome, jQuery.  
- **Features:**  
  - Procedure code input box (CPT).  
  - Hospital dropdown populated dynamically from DB.  
  - Insurance plan dropdown.  
  - Results card showing:  
    - Procedure description  
    - Gross charges  
    - Discounted cash price  
    - Negotiated rate  
    - Min & max charges  
  - Recommendations section highlighting:  
    - **Best Insurance Option** (lowest negotiated rate)  
    - **Best Hospital Option** (lowest cost provider).  

- **UX Enhancements:**  
  - Loading spinner on search.  
  - Alert boxes for DB errors or invalid inputs.  
  - Responsive design for mobile devices.  

### 4.3 Data Models

- **Hospitals Table:** `hospital_id`, `hospital_name`, `quality_index`  
- **Payers Table:** `payer_id`, `payer_name`, `plan_name`  
- **Charges Table:** `procedure_code`, `hospital_id`, `payer_id`, `gross_charge`, `discounted_cash`, `negotiated_rate`, `min_charge`, `max_charge`  

---

## 5. Results & Deliverables

- **Fully automated data pipeline** from ingestion (ADF) → transformation (Databricks) → curation (SQL).  
- **Optimized query layer** in Azure SQL for near real-time responses.  
- **Flask web API** serving structured healthcare pricing and recommendation data.  
- **Interactive web application** for patient/insurer use cases.  

**Key Deliverables:**  
- `app.py` → Flask backend with APIs.  
- `index.html` → Responsive frontend with search, results, and recommendation cards.  
- **End-to-end tested workflow:** Enter CPT code → Get results & best options.  

---

## 6. Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| Inconsistent raw healthcare data formats | Standardized schema enforcement in Databricks Silver Layer |
| Query latency with large datasets | Partitioning by CPT and `payer_id` in SQL serverless |
| Displaying actionable insights for non-technical users | Clear visual UI with Bootstrap cards, icons, and pricing highlights |
| Integration across multiple Azure services | CI/CD deployment pipeline with clear data lineage |

---

## 7. Future Enhancements

- Add **Power BI dashboards** for advanced visualizations.  
- Implement **machine learning models** to predict hospital outcomes or cost savings.  
- Incorporate **real-time APIs** for up-to-date negotiated rates.  
- Add **role-based authentication** for patients, insurers, and providers.  
- Ensure **HIPAA compliance** with enhanced encryption and audit logging.  

---

## 8. Conclusion

This project successfully demonstrates the **design and implementation of a modern, cloud-native data platform** integrated with an interactive analytics application. Leveraging **Azure Data Factory, Databricks, and Azure SQL**, the backend ensures data reliability and scalability, while the **Flask web app** empowers users with transparent healthcare cost and quality insights.  

The outcome is a **comprehensive healthcare decision-support system** that helps patients and insurers make informed treatment and provider choices.  
