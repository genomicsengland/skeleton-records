/*
	Skeleton record table creation
	V0.1 Laura Kerr 20th July 2020
*/

-- Landing table
CREATE TABLE SKELETON_LANDING (
	participant_id 		bigint,
	insert_update		character varying (1),
	surname     		character varying (255),    
	forenames            	character varying (255), 
	date_of_birth        	character varying (255), 
	gender               	character varying (255), 
	nhs_number      	character varying (255), 
	hospital_number	 	character varying (255), 
	ods_code             	character varying (255), 
	identifier           	character varying (255), 
	identifier_type      	character varying (255), 
	consent_status       	character varying (255), 
	consent_date         	character varying (255), 
	sample_id            	character varying (255), 
	cohort_id 		character varying (255), 
	programme_id 		character varying (255), 
	status     		integer not null default 0
);


-- The Identifier_Type_Ref table holds the list of identifier types (such as ‘NHSNumber’, ‘GenomiCC’ and so on)


CREATE SEQUENCE IDENTIFIER_TYPE_REF_SEQ INCREMENT BY 1 START WITH 1;

CREATE TABLE IDENTIFIER_TYPE_REF (
	id   			INTEGER NOT NULL PRIMARY KEY DEFAULT NEXTVAL('IDENTIFIER_TYPE_REF_SEQ'::regclass), 
	identifier_type    	character varying (255), 
	in_use_flag          	character varying (255),           
	date_created   		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT unique_identifier_type UNIQUE (identifier_type)
);


-- The participant_id_ref holds the participant ID range to be used and has the following columns:
-- The ODS code will be Genomics England’s  code, which is 8J834.

CREATE TABLE PARTICIPANT_ID_REF (
	ods_code   		character varying (255), 
	start_id 		bigint,
	last_allocated          bigint,  
	last_updated	 	TIMESTAMP,
	CONSTRAINT unique_ods_code UNIQUE (ods_code)
);

CREATE SEQUENCE COHORT_REF_SEQ INCREMENT BY 1 START WITH 1;

CREATE TABLE COHORT_REF (
	id   			INTEGER NOT NULL PRIMARY KEY DEFAULT NEXTVAL('COHORT_REF_SEQ'::regclass), 
	cohort_name    		character varying (255), 
	date_created   		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT unique_cohort_name UNIQUE (cohort_name) 
);

CREATE SEQUENCE PROGRAMME_REF_SEQ INCREMENT BY 1 START WITH 1;

CREATE TABLE PROGRAMME_REF (
	id   			INTEGER NOT NULL PRIMARY KEY DEFAULT NEXTVAL('PROGRAMME_REF_SEQ'::regclass), 
	programme_name    	character varying (255), 
	date_created   		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT unique_programme_name UNIQUE (programme_name)  
);



-- This is a list of patients only – external identifiers, sample and consent data are held as separate entities.
-- The current date is normally used for the date_created column.
CREATE TABLE SKELETON_PATIENT (
	participant_id 		bigint primary key not null,
	date_of_birth 		date,
	forenames  		character varying (255),            
	surname 		character varying (255),
	gender	 		character varying (1), 
	date_created 		DATE NOT NULL DEFAULT NOW() 
);


-- This table holds all the identifiers associated with a patient, including the NHS number
CREATE TABLE SKELETON_PATIENT_IDENTIFIER (
	participant_id 		bigint,
	person_identifier 	character varying (255),
	person_identifier_type 	character varying (255),
	ods_code 		character varying (255),
	date_created 		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_participant_1
        FOREIGN KEY(participant_id) 
	  REFERENCES SKELETON_PATIENT (participant_id)
);


-- This table holds the research status consent data. It can have multiple rows per patient, thus providing a history record
CREATE TABLE SKELETON_PATIENT_CONSENT (
	participant_id 		bigint,
	consent_status 		character varying (255),
	consent_date 		date,
	date_created 		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_participant_2
        FOREIGN KEY(participant_id) 
	  REFERENCES SKELETON_PATIENT (participant_id)
);


-- Sample data. This is an absolute minimum data set and is used to allow external sample IDs to be matched to patient records. 
-- We may wish to extend it in future.
CREATE TABLE SKELETON_PATIENT_SAMPLE (
	participant_id 		bigint,
	sample_id 		character varying (255),
	date_created 		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_participant_3
        FOREIGN KEY(participant_id) 
	  REFERENCES SKELETON_PATIENT (participant_id)

);

-- link between participant and cohort
CREATE TABLE SKELETON_PATIENT_COHORT (
	participant_id 		bigint,
	cohort_id 		character varying (255), 
	date_created 		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_participant_4
        FOREIGN KEY(participant_id) 
	  REFERENCES SKELETON_PATIENT (participant_id)
);

-- link between participant and programme
CREATE TABLE SKELETON_PATIENT_PROGRAMME (
	participant_id 		bigint,
	programme_id 		character varying (255), 
	date_created 		DATE NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_participant_5
        FOREIGN KEY(participant_id) 
	  REFERENCES SKELETON_PATIENT (participant_id)
);


CREATE TABLE GEL_LOGFILE
(
  ENTRY_NO    bigint primary key,
  LOGMESSAGE  character varying(1024),
  ENTRY_DATE  DATE
)
;

CREATE SEQUENCE GEL_LOG_SEQUENCE INCREMENT BY 1 START WITH 1;