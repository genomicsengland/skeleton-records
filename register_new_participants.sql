-- Patient Registration
/*
	V0.1 Laura Kerr 27th July 2020
*/
DO $$
DECLARE
	reg_cursor CURSOR IS SELECT * FROM sr.SKELETON_LANDING WHERE STATUS = 1 AND UPPER(insert_update) = 'I';
	v_LogMessage VARCHAR(1024) := NULL;
	v_SqlString VARCHAR(1024) := NULL;
	v_record_count INTEGER := 0;
	v_new_participant_id bigint := 0;
BEGIN
	v_LogMessage := 'Starting registration at ' || now()::varchar;
	INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
	-- count the records
	SELECT COUNT(1) FROM sr.SKELETON_LANDING WHERE STATUS = 1 AND UPPER(insert_update) = 'I' INTO STRICT v_record_count;
	v_LogMessage := 'There are ' || v_record_count::varchar || ' records in the landing table.' ;
	INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
	-- loop through the sr.SKELETON_LANDING table
	FOR reg_rec IN reg_cursor
	LOOP
		-- get the next participant ID
		SELECT last_allocated FROM sr.PARTICIPANT_ID_REF WHERE ods_code = '8J834' INTO STRICT v_new_participant_id;
		v_new_participant_id := v_new_participant_id + 1;
		
		-- first of all, create a new patient record
		INSERT INTO sr.SKELETON_PATIENT (participant_id,date_of_birth,forenames,surname,gender)
		VALUES (v_new_participant_id,TO_DATE(reg_rec.date_of_birth,'YYYY-MM-DD'),reg_rec.forenames,reg_rec.surname,reg_rec.gender);
		-- Add the NHS number if supplied
		IF reg_rec.nhs_number IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_IDENTIFIER (participant_id,person_identifier,person_identifier_type,ods_code)
			VALUES (v_new_participant_id,reg_rec.nhs_number,'NHSNumber',null);
		END IF;
		-- Add the hospital number if supplied
		IF reg_rec.hospital_number IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_IDENTIFIER (participant_id,person_identifier,person_identifier_type,ods_code)
			VALUES (v_new_participant_id,reg_rec.hospital_number,'HospNumber',null);
		END IF;
		-- External identifier
		IF reg_rec.person_identifier IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_IDENTIFIER (participant_id,person_identifier,person_identifier_type,ods_code)
			VALUES (v_new_participant_id,reg_rec.person_identifier,reg_rec.person_identifier_type,null);
		END IF;
		-- consent status
		IF reg_rec.consent_status IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_CONSENT (participant_id,consent_status,consent_date)
			VALUES (v_new_participant_id,reg_rec.consent_status,TO_DATE(reg_rec.consent_date,'YYYY-MM-DD'));
		END IF;
		-- sample data
		IF reg_rec.sample_id IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_SAMPLE (participant_id,sample_id)
			VALUES (v_new_participant_id,reg_rec.sample_id);
		END IF;
		-- cohort record
		IF reg_rec.cohort_id IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_COHORT (participant_id,cohort_id)
			VALUES (v_new_participant_id,reg_rec.cohort_id);
		END IF;
		-- programme record
		IF reg_rec.programme_id IS NOT NULL THEN
			INSERT INTO sr.SKELETON_PATIENT_PROGRAMME (participant_id,programme_id)
			VALUES (v_new_participant_id,reg_rec.programme_id);
		END IF;
		-- update the last_allocated value
		UPDATE sr.PARTICIPANT_ID_REF SET last_allocated = v_new_participant_id WHERE ods_code = '8J834';
		
		-- update the source record
		UPDATE sr.SKELETON_LANDING SET STATUS = 2 WHERE CURRENT OF reg_cursor;
	END LOOP;
	v_LogMessage := 'Registration completed at ' || now()::varchar;
	INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
EXCEPTION
	WHEN others THEN
 		v_LogMessage := 'SQLSTATE ' || SQLSTATE || ': error occurred in main exception handler';
		INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
END;
$$ LANGUAGE plpgsql;