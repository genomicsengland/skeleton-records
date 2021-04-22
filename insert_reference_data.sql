/*
	Reference data insertion
	V0.1 Laura Kerr 20th July 2020
*/


-- Initial identifier types

INSERT INTO IDENTIFIER_TYPE_REF(IDENTIFIER_TYPE) VALUES ('NHSNumber');
INSERT INTO IDENTIFIER_TYPE_REF(IDENTIFIER_TYPE) VALUES ('GenomiCC');
INSERT INTO IDENTIFIER_TYPE_REF(IDENTIFIER_TYPE) VALUES ('DeliveryID');
INSERT INTO IDENTIFIER_TYPE_REF(IDENTIFIER_TYPE) VALUES ('ParticipantID');
INSERT INTO IDENTIFIER_TYPE_REF(IDENTIFIER_TYPE) VALUES ('HospNumber');


-- set up Participant ID range for Genomics England

INSERT INTO PARTICIPANT_ID_REF (ods_code,start_id,last_allocated,last_updated) VALUES ('8J834',300000000,300001016,NOW());

-- set up cohort list

INSERT INTO COHORT_REF(cohort_name) VALUES ('100K RARE DISEASES');
INSERT INTO COHORT_REF(cohort_name) VALUES ('100K CANCER');
INSERT INTO COHORT_REF(cohort_name) VALUES ('COVID');

-- set up programme list
INSERT INTO PROGRAMME_REF (programme_name) VALUE ('COVID SEVERE');
INSERT INTO PROGRAMME_REF (programme_name) VALUE ('COVID MILD');

COMMIT;








