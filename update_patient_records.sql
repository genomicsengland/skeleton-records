-- Update patient records
/*
	V0.1 Laura Kerr 10th August 2020
*/
DO $$
DECLARE
	reg_cursor CURSOR IS SELECT * FROM SKELETON_LANDING WHERE STATUS = 1 AND UPPER(insert_update) = 'U';
	v_LogMessage VARCHAR(1024) := NULL;
	v_SqlString VARCHAR(1024) := NULL;
	v_record_count INTEGER := 0;
	v_participant_id bigint := 0;
	v_Attribute VARCHAR(1024) := NULL;
	v_Date	DATE := NULL;
BEGIN
	v_LogMessage := 'Starting record updates at ' || now()::varchar;
	INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
	-- count the records
	SELECT COUNT(1) FROM SKELETON_LANDING WHERE STATUS = 1 AND UPPER(insert_update) = 'U' INTO STRICT v_record_count;
	v_LogMessage := 'There are ' || v_record_count::varchar || ' records in the landing table.' ;
	INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());

	-- loop through the SKELETON_LANDING table
	FOR reg_rec IN reg_cursor
	LOOP
		-- check the participant ID is present in the landing data
		IF reg_rec.participant_id IS NULL THEN
			v_LogMessage := reg_rec.forenames || ' ' || reg_rec.surname || ' DOB ' || reg_rec.date_of_birth || ' has no participant ID';
			INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			CONTINUE; -- next iteration
		END IF;	

		-- check the participant ID is present in the patient data
		v_participant_id := NULL;
		SELECT participant_id INTO STRICT v_participant_id FROM SKELETON_PATIENT WHERE participant_id = reg_rec.participant_id;
		IF v_participant_id  = NULL THEN
			v_LogMessage := reg_rec.participant_id || ' not found in patient table, ignoring';
			INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			CONTINUE; -- next iteration

		END IF;

		-- for each value in the landing table, check it is not a dupe. Log as a dupe if it is and insert if not
		-- surname
		IF reg_rec.surname IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT surname INTO STRICT v_Attribute FROM SKELETON_PATIENT WHERE participant_id = reg_rec.participant_id;
			IF v_Attribute = reg_rec.surname THEN
				v_LogMessage := reg_rec.participant_id || ' surname ' || reg_rec.surname || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT SET surname = reg_rec.surname WHERE participant_id = reg_rec.participant_id;
			END IF;
		END IF;

		-- forenames
		IF reg_rec.forenames IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT forenames INTO STRICT v_Attribute FROM SKELETON_PATIENT WHERE participant_id = reg_rec.participant_id;
			IF v_Attribute = reg_rec.forenames THEN
				v_LogMessage := reg_rec.participant_id || ' forenames ' || reg_rec.forenames || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT SET forenames = reg_rec.forenames WHERE participant_id = reg_rec.participant_id;
			END IF;
		END IF;

		-- date of birth
		IF reg_rec.date_of_birth IS NOT NULL THEN
			v_Date := NULL;
			SELECT date_of_birth INTO STRICT v_Date FROM SKELETON_PATIENT WHERE participant_id = reg_rec.participant_id;
			IF TO_DATE(reg_rec.date_of_birth,'YYYY-MM-DD') = v_Date THEN
				v_LogMessage := reg_rec.participant_id || ' date of birth ' || reg_rec.date_of_birth::varchar || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT SET date_of_birth = TO_DATE(reg_rec.date_of_birth,'YYYY-MM-DD') WHERE participant_id = reg_rec.participant_id;
			END IF;
		END IF;
		

		-- gender
		IF reg_rec.gender IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT gender INTO STRICT v_Attribute FROM SKELETON_PATIENT WHERE participant_id = reg_rec.participant_id;
			IF v_Attribute = reg_rec.gender THEN
				v_LogMessage := reg_rec.participant_id || ' gender ' || reg_rec.gender || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT SET gender = reg_rec.gender WHERE participant_id = reg_rec.participant_id;
			END IF;
		END IF;

		-- NHS number
		IF reg_rec.nhs_number IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT nhs_number INTO STRICT v_Attribute FROM SKELETON_PATIENT_IDENTIFIER WHERE participant_id = reg_rec.participant_id
			AND IDENTIFIER_TYPE = 'NhsNumber'
			AND IDENTIFIER IS NOT NULL;
			IF v_Attribute = reg_rec.nhs_number THEN
				v_LogMessage := reg_rec.participant_id || ' NHS Number ' || reg_rec.nhs_number || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT_IDENTIFIER SET identifier = reg_rec.nhs_number, identifer_type = 'NHSNumber' WHERE participant_id = reg_rec.participant_id;
			END IF;
		END IF;

		-- Hospital number
		IF reg_rec.hospital_number IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT hospital_number INTO STRICT v_Attribute FROM SKELETON_PATIENT_IDENTIFIER WHERE participant_id = reg_rec.participant_id
			AND IDENTIFIER_TYPE = 'HospNumber'
			AND IDENTIFIER IS NOT NULL;
			IF v_Attribute = reg_rec.hospital_number THEN
				v_LogMessage := reg_rec.participant_id || ' Hospital Number ' || reg_rec.hospital_number || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT_IDENTIFIER SET identifier = reg_rec.hospital_number, identifer_type = 'HospNumber' WHERE participant_id = reg_rec.participant_id;
			END IF;
		END IF;

		-- ODS Code
		IF reg_rec.ods_code IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT ods_code INTO STRICT v_Attribute FROM SKELETON_PATIENT_IDENTIFIER WHERE participant_id = reg_rec.participant_id
			AND IDENTIFIER_TYPE = 'HospNumber'
			AND IDENTIFIER IS NOT NULL;
			IF v_Attribute = reg_rec.hospital_number THEN
				v_LogMessage := reg_rec.participant_id || ' Hospital Number ' || reg_rec.hospital_number || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				UPDATE SKELETON_PATIENT_IDENTIFIER SET ods_code = reg_rec.ods_code WHERE participant_id = reg_rec.participant_id AND identifer_type = 'HospNumber' AND identifier = reg_rec.identifier;
			END IF;
		END IF;

		-- other identifiers
		IF reg_rec.identifier IS NOT NULL THEN
			IF reg_rec.identifier_type IS NOT NULL THEN
				v_Attribute := NULL;
				SELECT identifier INTO STRICT v_Attribute FROM SKELETON_PATIENT_IDENTIFIER WHERE participant_id = reg_rec.participant_id
				AND IDENTIFIER_TYPE = reg_rec.identifier_type
				AND IDENTIFIER IS NOT NULL;
				IF v_Attribute = reg_rec.identifier THEN
					v_LogMessage := reg_rec.participant_id || ' External identifier ' || reg_rec.identifier || ' already exists, ignoring';
					INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
				ELSE
					UPDATE SKELETON_PATIENT_IDENTIFIER SET identifier = reg_rec.identifier, identifier_type = reg.rec.identifier_type WHERE participant_id = reg_rec.participant_id;
				END IF;
			END IF;
		END IF;

		-- consent status
		IF reg_rec.consent_status IS NOT NULL THEN		
			v_Attribute := NULL;
			SELECT consent_status INTO STRICT v_Attribute FROM SKELETON_PATIENT_CONSENT WHERE participant_id = reg_rec.participant_id
			AND consent_status = reg_rec.consent_status
			AND consent_date = TO_DATE(reg_rec.consent_date,'YYYY-MM-DD');
			IF v_Attribute = reg_rec.consent_status THEN
				v_LogMessage := reg_rec.participant_id || ' consent status ' || reg_rec.consent_status || ' date ' || TO_DATE(reg_rec.consent_date,'YYYY-MM-DD') || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				INSERT INTO SKELETON_PATIENT_CONSENT (participant_id,consent_status,consent_date,date_created)
				VALUES (reg_rec.participant_id,reg_rec.consent_status,TO_DATE(reg_rec.consent_date,'YYYY-MM-DD'),now());
			END IF;
		END IF;

		-- sample ID
		IF reg_rec.sample_id IS NOT NULL THEN		
			v_Attribute := NULL;
			SELECT sample_id INTO STRICT v_Attribute FROM SKELETON_PATIENT_SAMPLE WHERE participant_id = reg_rec.participant_id
			AND sample_id = reg_rec.sample_id;
			IF v_Attribute = reg_rec.sample_id THEN
				v_LogMessage := reg_rec.participant_id || ' sample ID ' || reg_rec.sample_id || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				INSERT INTO SKELETON_PATIENT_SAMPLE (participant_id,sample_id,date_created)
				VALUES (reg_rec.participant_id,reg_rec.sample_id,now());
			END IF;
		END IF;

		-- cohort ID
		IF reg_rec.cohort_id IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT cohort_id INTO STRICT v_Attribute FROM SKELETON_PATIENT_COHORT WHERE participant_id = reg_rec.participant_id
			AND cohort_id = reg_rec.cohort_id;
			IF v_Attribute = reg_rec.cohort_id THEN
				v_LogMessage := reg_rec.participant_id || ' cohort ID ' || reg_rec.cohort_id || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				INSERT INTO SKELETON_PATIENT_COHORT (participant_id,cohort_id,date_created)
				VALUES (reg_rec.participant_id,reg_rec.cohort_id,now());
			END IF;
		END IF;

		-- programme ID
		IF reg_rec.programme_id IS NOT NULL THEN
			v_Attribute := NULL;
			SELECT programme_id INTO STRICT v_Attribute FROM SKELETON_PATIENT_PROGRAMME WHERE participant_id = reg_rec.participant_id
			AND programme_id = reg_rec.programme_id;
			IF v_Attribute = reg_rec.programme_id THEN
				v_LogMessage := reg_rec.participant_id || ' programme ID ' || reg_rec.programme_id || ' already exists, ignoring';
				INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
			ELSE
				INSERT INTO SKELETON_PATIENT_PROGRAMME (participant_id,programme_id,date_created)
				VALUES (reg_rec.participant_id,reg_rec.programme_id,now());
			END IF;
		END IF;
		
		-- update the source record
		UPDATE SKELETON_LANDING SET STATUS = 3 WHERE CURRENT OF reg_cursor;
	END LOOP;

	v_LogMessage := 'Updating completed at ' || now()::varchar;
	INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
EXCEPTION
	WHEN others THEN
 		v_LogMessage := 'SQLSTATE ' || SQLSTATE || ': error occurred in main exception handler';
		INSERT INTO GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('GEL_LOG_SEQUENCE'), v_LogMessage,now());
END;
$$ LANGUAGE plpgsql;

