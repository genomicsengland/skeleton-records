/*
	Add a new cohort
	V0.1 Laura Kerr 20th July 2020
*/



-- Amend this script to insert a new cohort by replacing the <NEW COHORT NAME> with
-- the identifier you want to add.
-- If the value already exists in the database, an error will occur.

INSERT INTO COHORT_REF(cohort_name) VALUES ('<NEW COHORT NAME>');

COMMIT;








