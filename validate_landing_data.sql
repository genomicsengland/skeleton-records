-- validate the landing data

DO $$
DECLARE
	landing_cursor CURSOR IS SELECT * FROM sr.SKELETON_LANDING;
	v_LogMessage VARCHAR(1024) := NULL;
	v_SqlString VARCHAR(1024) := NULL;
	v_DateCheck DATE;
	v_IdString VARCHAR(255) := NULL;
	v_CurrentStatus VARCHAR(5) := 'OK';
	v_RecordCount INTEGER := 0;
BEGIN
	-- clear down data and reset sequence
	v_SqlString  := 'TRUNCATE TABLE sr.GEL_LOGFILE';
	EXECUTE v_SqlString ;
	v_SqlString  := 'DROP SEQUENCE sr.GEL_LOG_SEQUENCE';
	EXECUTE v_SqlString ;
	v_SqlString  := 'CREATE SEQUENCE sr.GEL_LOG_SEQUENCE INCREMENT BY 1 START WITH 1';
	EXECUTE v_SqlString ;
	v_LogMessage := 'Starting validation at ' || now()::varchar;
	INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
	-- loop through the sr.SKELETON_LANDING table

	FOR landing_rec IN landing_cursor
	LOOP
		v_CurrentStatus := 'OK';
        	-- check for completely empty rows
		IF landing_rec.surname IS NULL AND landing_rec.forenames IS NULL AND landing_rec.date_of_birth IS NULL AND landing_rec.gender IS NULL AND
		landing_rec.nhs_number IS NULL AND landing_rec.hospital_number IS NULL AND landing_rec.ods_code IS NULL AND landing_rec.person_identifier IS NULL 			AND landing_rec.person_identifier_type IS NULL AND landing_rec.consent_status IS NULL AND landing_rec.consent_date IS NULL AND 		landing_rec.sample_id IS NULL AND landing_rec.cohort_id IS NULL AND landing_rec.programme_id IS NULL
		THEN
			v_LogMessage := 'Empty row found, ignoring.';
			INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
			UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
		END IF;
		
		-- Check for duplicate records
		SELECT COUNT(1) FROM sr.SKELETON_LANDING WHERE forenames = landing_rec.forenames
		AND surname = landing_rec.surname
		AND date_of_birth = landing_rec.date_of_birth
		AND gender = landing_rec.gender
		AND landing_rec.forenames IS NOT NULL
		AND landing_rec.surname IS NOT NULL
		AND landing_rec.date_of_birth IS NOT NULL
		AND landing_rec.gender IS NOT NULL
		AND UPPER(landing_rec.insert_update) = 'I'
		INTO STRICT v_RecordCount;
		IF v_RecordCount > 1 THEN
			v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ' has ' || v_RecordCount::varchar || ' in the landing table.';
			INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
			UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
			v_CurrentStatus := 'ERR';
		END IF;

		-- check for duplicate NHS numbers
		SELECT COUNT(1) FROM sr.SKELETON_LANDING WHERE nhs_number = landing_rec.nhs_number
		AND landing_rec.nhs_number IS NOT NULL
		AND UPPER(landing_rec.insert_update) = 'I'
		INTO STRICT v_RecordCount;
		IF v_RecordCount > 1 THEN
			v_LogMessage := landing_rec.person_identifier || ' ' || 'NHS number ' || landing_rec.nhs_number || ' has ' || v_RecordCount::varchar || ' insertions in the landing table.';
			INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
			UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
			v_CurrentStatus := 'ERR';
		END IF;


		-- reject a record if it's an insert with a populated participant_id
		IF landing_rec.participant_id IS NOT NULL AND landing_rec.insert_update = 'I' THEN
			v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': attempt to insert existing participant ID ' || landing_rec.participant_id;
			INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
			UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
			v_CurrentStatus := 'ERR';
		END IF;

		-- check the intended operation
		IF UPPER(landing_rec.insert_update) NOT IN ('I','U') THEN
			v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': invalid operation specified - expected I or U and found ' || landing_rec.insert_update ;
		INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
		UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
		v_CurrentStatus := 'ERR';
	END IF; 

		-- check that external identifiers have a type

		IF landing_rec.person_identifier IS NOT NULL AND landing_rec.person_identifier_type IS NULL THEN
			v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': identifier type not specified for identifier ' || landing_rec.person_identifier ;
			INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
			UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
			v_CurrentStatus := 'ERR';
		END IF;

		-- check that external identifiers have a valid type
		IF landing_rec.person_identifier IS NOT NULL AND landing_rec.person_identifier_type IS NOT NULL THEN
			BEGIN
				SELECT identifier_type INTO STRICT v_IdString FROM sr.IDENTIFIER_TYPE_REF WHERE identifier_type = landing_rec.person_identifier_type;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': identifier type ' || landing_rec.person_identifier_type || ' is not valid';
			INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
			UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
			v_CurrentStatus := 'ERR';

			WHEN OTHERS THEN
 				v_LogMessage := landing_rec.person_identifier || ' ' || 'SQLSTATE ' || SQLSTATE || ': error occurred when checking identifier type';
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
				UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
				v_CurrentStatus := 'ERR';
		END;
	END IF;

		-- if a cohort identifier is supplied, check its validity
		IF landing_rec.cohort_id IS NOT NULL THEN
			BEGIN
				SELECT cohort_name INTO STRICT v_IdString FROM sr.COHORT_REF WHERE cohort_name= landing_rec.cohort_id;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_LogMessage := landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': cohort name ' || landing_rec.cohort_id || ' is not valid';
					INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
					UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
					v_CurrentStatus := 'ERR';

				WHEN OTHERS THEN
 					v_LogMessage := 'SQLSTATE ' || SQLSTATE || ': error occurred when checking cohort name';
					INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
					UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
					v_CurrentStatus := 'ERR';
			END;
		END IF;

	-- if a programme identifier is supplied, check its validity
	IF landing_rec.programme_id IS NOT NULL THEN
		BEGIN
			SELECT programme_name INTO STRICT v_IdString FROM sr.PROGRAMME_REF WHERE programme_name = landing_rec.programme_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': programme name ' || landing_rec.programme_id || ' is not valid';
		INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
		UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
		v_CurrentStatus := 'ERR';

			WHEN OTHERS THEN
 				v_LogMessage := landing_rec.person_identifier || ' ' || 'SQLSTATE ' || SQLSTATE || ': error occurred when checking programme name';
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
				UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
				v_CurrentStatus := 'ERR';
		END;
	END IF;

	-- check the date of birth
	IF landing_rec.date_of_birth IS NOT NULL THEN
		BEGIN
			v_DateCheck := TO_DATE(landing_rec.date_of_birth,'YYYY-MM-DD');
			-- if no exception is raised, the date is valid. Check its range.
			IF v_DateCheck > NOW() THEN
				v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': date of birth ' || landing_rec.date_of_birth || ' cannot be in the future.';
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
				UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
				v_CurrentStatus := 'ERR';
			END IF;

			IF v_DateCheck < '1895-01-01'::date THEN
				v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': date of birth ' || landing_rec.date_of_birth || ' looks too early. Please check and manually correct.';
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
				UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
				v_CurrentStatus := 'ERR';
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': date of birth ' || landing_rec.date_of_birth || ' is not valid. Format must be YYYY-MM-DD';
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
 				v_LogMessage := landing_rec.person_identifier || ' ' || 'Error details are SQLSTATE ' || SQLSTATE;
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
				UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
				v_CurrentStatus := 'ERR';
		END;
	END IF;

	
	-- check the consent date
	IF landing_rec.consent_date IS NOT NULL THEN
		BEGIN
			v_DateCheck := TO_DATE(landing_rec.consent_date,'YYYY-MM-DD');
		EXCEPTION
			WHEN OTHERS THEN
				v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': consent date' || landing_rec.consent_date || ' is not valid. Format must be YYYY-MM-DD';
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
 				v_LogMessage := landing_rec.person_identifier || ' ' || 'Error details are SQLSTATE ' || SQLSTATE;
				INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
				UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
				v_CurrentStatus := 'ERR';
		END;
	END IF;

	-- check the consent status is not null. TODO - add enumeration check
	IF landing_rec.consent_status IS NULL THEN		
		v_LogMessage := landing_rec.person_identifier || ' ' || landing_rec.forenames || ' ' || landing_rec.surname || ' DOB ' || landing_rec.date_of_birth || ': consent status cannot be null.';
		INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
		UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
		v_CurrentStatus := 'ERR';
	END IF;
	
	-- TODO if needed - check ODS code against data set
	
	-- With all checks passed, set the status to 1 (valid)
	IF v_CurrentStatus = 'ERR' THEN
		UPDATE sr.SKELETON_LANDING SET STATUS = '9' WHERE CURRENT OF landing_cursor;
	ELSE
		UPDATE sr.SKELETON_LANDING SET STATUS = '1' WHERE CURRENT OF landing_cursor;
	END IF;

END LOOP;

v_LogMessage := 'Validation completed at ' || now()::varchar;
INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);

EXCEPTION
	WHEN others THEN
 		v_LogMessage := landing_rec.person_identifier || ' ' || 'SQLSTATE ' || SQLSTATE || ': error occurred in main exception handler';
		INSERT INTO sr.GEL_LOGFILE (entry_no,logmessage,entry_date) VALUES (nextval('sr.GEL_LOG_SEQUENCE'), v_LogMessage,now()::date);
END;
$$ LANGUAGE plpgsql;









