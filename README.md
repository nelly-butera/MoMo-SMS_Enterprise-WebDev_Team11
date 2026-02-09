## MoMo SMS Data Analytics Dashboard  
**Team Name:** Team 11

### Project Overview
This project is an ongoing enterprise-level fullstack application designed to process, clean, analyze, and visualize Mobile Money (MoMo) SMS transaction data provided in XML format.

The system ingests raw MoMo SMS XML data, performs ETL (Extract, Transform, Load) operations, stores structured data in a relational database (SQLite), and exposes insights through a frontend dashboard. The project emphasizes backend data processing, database management, frontend visualization, and collaborative Agile development practices.


### Objectives
- Parse MoMo SMS data from XML format
- Clean and normalize transaction data (dates, amounts, phone numbers)
- Categorize transactions using rule-based logic
- Store processed data in a relational database
- Prepare data for frontend analytics and visualization
- Practice collaborative development using GitHub and Agile methods


### Team Members (Collaborators)
- Ingabe Mbayire Melyssa
- Murenzi Bonheur
- Teta Butera Nelly


### Repo Structure
```bash
├── README.md
├── .env.example 
├── requirements.txt #
├── index.html # program entry point
├── web/
├── data/
├── etl/
├── api/
├── scripts/
└── tests/
```

### Architecture Diagram: 
  https://miro.com/app/board/uXjVGRWd6vw=/?share_link_id=987046808677
  The architecture diagram image/file is also committed to this repository.

### Scrum Board Link
  
  https://alustudent-team-11.atlassian.net/jira/software/projects/DEV/boards/2?atlOrigin=eyJpIjoiZmRjNTMwOGRhMmFhNGY1Y2EwZTQyZGQ0ODdmOWYwNDYiLCJwIjoiaiJ9

### Tech Stack
- **Backend:**
- **Database:**
- **Frontend:**
- **Optional API:**
- **Version Control:** Git & GitHub
- **Project Management:** Scrum (GitHub Projects / Trello)


### Checklist for Week 1
- GitHub repository created (completed)
- Team members added as collaborators (completed)
- README with team info and links (completed)
- Architecture diagram committed (completed)
- Scrum board created and populated (completed)

## Assignment: Database Design and Implementation (Week 2)
Designed and implemented the database foundation for our MoMo SMS data processing system, we used SQL and practiced data serialization concepts using JSON.

ERD diagram file (docs/erd_diagram.[png/pdf])
SQL setup script (database/database_setup.sql)
JSON examples (examples/json_schemas.json)

### New Folders
- `docs/erd_diagram.pdf` added our erd diagram pdf
- `database/database_setup.sql` added XML parsing and DSA comparison scripts
- `docs/` API documentation and report template
- `screenshots/` test evidence screenshots (add your images here)

### ERD Link:
   https://lucid.app/lucidchart/2dca8e99-8925-4c91-9e58-8ddf5f5ce427/edit?viewport_loc=-920%2C-744%2C743%2C940%2C0_0&invitationId=inv_4840b8a5-1ffc-443d-a2f1-63593d8ec605

## Assignment: Secure REST API (Week 3)
This update adds a plain-Python REST API for MoMo SMS transactions, XML parsing utilities, and DSA comparison scripts.

### New Folders
- `api/` REST API implementation
- `dsa/` XML parsing and DSA comparison scripts
- `docs/` API documentation and report template
- `screenshots/` test evidence screenshots

### Setup
1. Place the dataset at `data/raw/modified_sms_v2.xml`
2. Parse XML into JSON:
   - `python dsa/parse_xml.py --xml data/raw/modified_sms_v2.xml --out data/processed/transactions.json`
3. Run the API:
   - `python api/app.py`
4. Test endpoints with curl or Postman (documentation is at `docs/api_docs.md`)
5. Run DSA comparison:
   - `python dsa/search_compare.py`

### Environment Variables
- `API_USER` default `admin`
- `API_PASS` default `admin123`

### Deliverables Checklist
- API code in `api/`
- XML parsing & DSA code in `dsa/`
- Documentation in `docs/api_docs.md`
- Report template in `docs/report.md`
- Screenshots in `screenshots/`
- Team participation sheet placed in `docs/` 


