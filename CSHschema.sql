DROP TABLE IF EXISTS Administrator;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS AdmissionType;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Admission;

SET datestyle = 'DMY';

CREATE TABLE Administrator (
    UserName VARCHAR(10) PRIMARY KEY,
    Password VARCHAR(20) NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(20) NOT NULL
);

INSERT INTO Administrator VALUES 
('jdoe', 'Pass1234', 'John', 'Doe', 'jdoe@csh.com'),
('jsmith', 'Pass5678', 'Jane', 'Smith', 'jsmith@csh.com'),
('ajohnson', 'Passabcd', 'Alice', 'Johnson', 'ajohnson@csh.com'),
('bbrown', 'Passwxyz', 'Bob', 'Brown', 'bbrown@csh.com'),
('cdavis', 'Pass9876', 'Charlie', 'Davis', 'cdavis@csh.com'),
('ksmith', 'Pass5566', 'Karen', 'Smith', 'ksmith@csh.com');

CREATE TABLE Patient (
    PatientID VARCHAR(10) PRIMARY KEY,
    Password VARCHAR(20) NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Mobile VARCHAR(20) NOT NULL
);

INSERT INTO Patient VALUES 
('dwilson', 'Pass5432', 'David', 'Wilson', '4455667788'),
('etylor', 'Passlmno', 'Eva', 'Taylor', '5566778899'),
('faderson', 'Passrstu', 'Frank', 'Anderson', '6677889900'),
('gthomas', 'Pass1357', 'Grace', 'Thomas', '7788990011'),
('smartinez', 'Pass2468', 'Stan', 'Martinez', '8899001122'),
('lroberts', 'Pass1122', 'Laura', 'Roberts', '9900112233');


CREATE TABLE AdmissionType (
    AdmissionTypeID SERIAL PRIMARY KEY,
    AdmissionTypeName VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO AdmissionType VALUES (1, 'Emergency');
INSERT INTO AdmissionType VALUES (2, 'Transfer');
INSERT INTO AdmissionType VALUES (3, 'Inpatient');
INSERT INTO AdmissionType VALUES (4, 'Outpatient');

CREATE TABLE Department (
    DeptId SERIAL PRIMARY Key,
    DeptName VARCHAR(20) UNIQUE not NULL
);

INSERT INTO Department VALUES (1, 'General');
INSERT INTO Department VALUES (2, 'Emergency');
INSERT INTO Department VALUES (3, 'Surgery');
INSERT INTO Department VALUES (4, 'Obstetrics');
INSERT INTO Department VALUES (5, 'Rehabilitation');
INSERT INTO Department VALUES (6, 'Paediatrics');

CREATE table Admission (
    AdmissionID SERIAL PRIMARY KEY,
    AdmissionType INTEGER NOT NULL,
    Department INTEGER NOT NULL,
	Patient VARCHAR(10) NOT NULL,
	Administrator VARCHAR(10) NOT NULL,
    Fee Decimal(7,2),
    DischargeDate Date,
    Condition VARCHAR(500),
	FOREIGN KEY(AdmissionType) REFERENCES AdmissionType,
	FOREIGN KEY(Department) REFERENCES Department,
	FOREIGN KEY(Patient) REFERENCES Patient,
	FOREIGN KEY(Administrator) REFERENCES Administrator
);

INSERT INTO Admission (AdmissionType, Department, Fee, Patient, Administrator, DischargeDate, Condition) VALUES
    (4, 1, 666.00, 'lroberts', 'jdoe', '28/02/2024', 'a red patch on my skin that looks irritated. It started small but has been spreading and feels warm to the touch'),
	(2, 1, 100.00, 'gthomas', 'jdoe', '11/09/2021', NULL),
	(1, 2, NULL, 'lroberts','jsmith', '02/09/2019', 'Admitted to the emergency department after suffering head trauma from a fall, requiring a CT scan and observation for potential concussion.'),
	(2, 3, 7688.00, 'dwilson','ajohnson', '01/12/2022', NULL),
	(2, 6, 1600.00, 'faderson', 'ajohnson', '03/09/2014', 'Child admitted to the hospital with a severe asthma attack, requiring oxygen therapy and nebulizer treatment.'),
	(4, 1, 90.00, 'gthomas', 'ksmith', '04/07/2021', 'Routine follow-up consultation to review progress after recent knee surgery, with positive recovery observed.'),
	(1, 2, 1450.00, 'smartinez', 'jsmith', NULL, 'Admitted to the emergency department with severe food poisoning, requiring IV fluids and anti-nausea medication for recovery.'),
	(4, 5, 180.95, 'dwilson', 'cdavis', '06/11/2021', 'Attended a physiotherapy session as part of an ongoing rehabilitation program following shoulder surgery.'),
	(3, 1, 2000.00, 'etylor', 'ajohnson', '10/09/2021', NULL),
	(2, 4, 8290.00, 'gthomas', 'jsmith', '01/09/2024', 'Postpartum care following a natural childbirth, including monitoring of both the mother and the newborn for potential complications.'),
	(2, 6, 1800.00, 'faderson', 'bbrown',  NULL, 'Child admitted to the paediatrics department for severe pneumonia, requiring intravenous antibiotics and respiratory therapy.'),
	(4, 1, 75.00, 'gthomas', 'bbrown', '19/11/2023', 'Routine general practitioner consultation for a follow-up after a recent bout of seasonal allergies.'),
	(3, 3, 7000.50, 'smartinez', 'jdoe', '15/10/2024', NULL),
	(1, 2, NULL, 'etylor', 'jdoe', NULL, 'I am having intense, crushing pain in my chest that feels like an elephant is sitting on it. It is spreading to my left arm and neck.');

-- Viewing admission function
CREATE OR REPLACE FUNCTION get_admissions_by_admin(admin_id TEXT)
RETURNS TABLE (
    admissionid INT,
    admissiontypename VARCHAR(20),
    deptname VARCHAR(20),
    dischargedate TEXT,
    fee TEXT,
    fullname TEXT,
    "condition" VARCHAR(500)
) AS $$
BEGIN
    RETURN QUERY
    SELECT a.admissionid, 
        at.admissiontypename,
        d.deptname,
        COALESCE(TO_CHAR(a.dischargedate, 'DD-MM-YYYY'),'') as dischargedate,
        COALESCE(a.fee :: TEXT, '') AS fee,
        CONCAT(p.firstname, ' ', p.lastname) as fullname,
        COALESCE(a.condition, '') as "condition"
    FROM admission a 
    INNER JOIN patient p ON a.patient = p.patientid
    INNER JOIN admissiontype at ON a.admissiontype = at.admissiontypeid
    INNER JOIN department d ON a.department = d.deptid
    WHERE a.administrator = admin_id
    ORDER BY a.dischargedate DESC NULLS LAST,
        CONCAT(p.firstname, ' ', p.lastname) ASC,
        at.admissiontypename DESC;
END;
$$ LANGUAGE plpgsql;

--  Finding Admissions function
CREATE OR REPLACE FUNCTION find_admissions(keyword TEXT)
RETURNS TABLE(
    admissionid INT,
    admissiontypename VARCHAR(20),
    deptname VARCHAR(20),
    dischargedate TEXT,
    fee TEXT,
    fullname TEXT,
    "condition" VARCHAR(500)
) AS $$
BEGIN
	RETURN QUERY 
	SELECT a.admissionid, 
		at.admissiontypename,
		d.deptname,
		COALESCE(TO_CHAR(a.dischargedate, 'DD-MM-YYYY'),'') as dischargedate,
		COALESCE(a.fee :: TEXT, '') as fee,
		CONCAT(p.firstname, ' ', p.lastname) as fullname,
		COALESCE(a.condition, '') as "condition"
    FROM admission a 
    INNER JOIN patient p ON a.patient = p.patientid
    INNER JOIN admissiontype at ON a.admissiontype = at.admissiontypeid
    INNER JOIN department d ON a.department = d.deptid
	WHERE 
		(a.dischargedate >= CURRENT_DATE - INTERVAL '2 years' OR a.dischargedate IS NULL)
		AND
        (LOWER(at.admissiontypename) LIKE LOWER('%' || keyword || '%') OR 
        LOWER(d.deptname) LIKE LOWER('%' || keyword || '%') OR 
        LOWER(p.firstname || ' ' || p.lastname) LIKE LOWER('%' || keyword || '%') OR
        LOWER(a.condition) LIKE LOWER('%' || keyword || '%')
		)
    ORDER BY 
        a.dischargedate ASC NULLS FIRST,
		fullname ASC;
END;
$$ LANGUAGE plpgsql;

-- Update admission function
CREATE OR REPLACE FUNCTION update_admission(
    p_admissionid INT, 
    p_admissiontype VARCHAR(20), 
    p_department VARCHAR(20), 
    p_dischargeDate DATE, 
    p_fee NUMERIC, 
    p_patient TEXT, 
    p_condition VARCHAR(500)
)
RETURNS VOID AS $$
BEGIN
	UPDATE admission
	SET
		admissiontype = (SELECT admissiontypeid FROM admissiontype WHERE LOWER(admissiontypename) = LOWER(p_admissiontype)),
		department = (SELECT deptid FROM department WHERE LOWER(deptname) = LOWER(p_department)),
		dischargedate = p_dischargeDate,
		fee = p_fee,
		patient = (SELECT patientid FROM patient WHERE LOWER(CONCAT(firstname, ' ', lastname)) LIKE LOWER('%' || p_patient || '%')),
		"condition" = p_condition
	WHERE admissionid = p_admissionid;
END;
$$ LANGUAGE plpgsql;