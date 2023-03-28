1--

-- Trigger to insert into a new table everytime any change is made in the Takes table

SET SERVEROUTPUT ON;

DROP TABLE Log_Change_Takes;

CREATE TABLE Log_Change_Takes (
	ID VARCHAR(8),
	type VARCHAR(6),
	toc TIMESTAMP,
	course_id VARCHAR(8),
	sec_id VARCHAR(8),
	semester VARCHAR(8),
	year NUMERIC(4, 0),
	grade VARCHAR(2),
	PRIMARY KEY (ID, toc, course_id, sec_id, semester, year)
);

CREATE OR REPLACE TRIGGER Log_Change_Takes 
BEFORE INSERT OR UPDATE OR DELETE ON Takes FOR EACH ROW
BEGIN
	CASE
		WHEN INSERTING THEN
			INSERT INTO Log_Change_Takes VALUES (:NEW.ID, 'INSERT', CURRENT_TIMESTAMP, :NEW.course_id, :NEW.sec_id, :NEW.semester, :NEW.year, :NEW.grade);
			DBMS_OUTPUT.PUT_LINE('INSERT ' || :NEW.ID);
		WHEN DELETING THEN
			INSERT INTO Log_Change_Takes VALUES (:OLD.ID, 'DELETE', CURRENT_TIMESTAMP, :OLD.course_id, :OLD.sec_id, :OLD.semester, :OLD.year, :OLD.grade);
			DBMS_OUTPUT.PUT_LINE('DELETE ' || :OLD.ID);
		WHEN UPDATING THEN
			INSERT INTO Log_Change_Takes VALUES (:NEW.ID, 'UPDATE', CURRENT_TIMESTAMP, :NEW.course_id, :NEW.sec_id, :NEW.semester, :NEW.year, :NEW.grade);
			DBMS_OUTPUT.PUT_LINE('UPDATE ' || :NEW.ID);
	END CASE;
END;
/


2--

CREATE OR REPLACE TRIGGER Item_update
BEFORE INSERT ON Item_Transaction FOR EACH ROW
BEGIN
	UPDATE Item_Master SET balanceStock = balanceStock - :NEW.quantity;
END;
/


3--

DROP TABLE ZAccount;

CREATE TABLE ZAccount (
	ano VARCHAR(10) PRIMARY KEY, 
	bal NUMERIC(8, 0)
);

INSERT INTO ZAccount VALUES ('1001', 98730);
INSERT INTO ZAccount VALUES ('1002', 48810);
INSERT INTO ZAccount VALUES ('1003', 61730);
INSERT INTO ZAccount VALUES ('1004', 10170);
INSERT INTO ZAccount VALUES ('1005', 69480);
INSERT INTO ZAccount VALUES ('1006', 34050);
INSERT INTO ZAccount VALUES ('1007', 47030);

DROP TABLE ZTransaction;

CREATE TABLE ZTransaction (
	ano VARCHAR(10),
	amt NUMERIC(8, 0)
);

CREATE OR REPLACE TRIGGER ZBanktrans
BEFORE INSERT ON ZTransaction FOR EACH ROW
DECLARE
	kcount NUMERIC(8, 0) := 0;
	kbal FLOAT := 0;
BEGIN
	SELECT count(*) INTO kcount FROM ZAccount WHERE ano = :NEW.ano;
	IF kcount < 1 THEN
		DBMS_OUTPUT.PUT_LINE('Wrong Account!');
		RAISE_APPLICATION_ERROR(-1, 'Wrong Account!');
	ELSE
		SELECT bal INTO kbal FROM ZAccount WHERE ano = :NEW.ano;
		IF kbal - :NEW.amt < 0 THEN
			DBMS_OUTPUT.PUT_LINE('Low balance!');
			RAISE_APPLICATION_ERROR(-2, 'Low balance!');
		ELSIF :NEW.amt < 1 THEN
			DBMS_OUTPUT.PUT_LINE('Cannot withdraw negative amount!');
			RAISE_APPLICATION_ERROR(-3, 'Cannot withdraw negative amount!');
		ELSE
			UPDATE ZAccount SET bal = bal - :NEW.amt WHERE ano = :NEW.ano;
			DBMS_OUTPUT.PUT_LINE('Updated!');
		END IF;
	END IF;
END;
/

INSERT INTO ZTransaction VALUES ('1006', 1000);
INSERT INTO ZTransaction VALUES ('1007', 1000);

4--

DROP TABLE Client_Master;

CREATE TABLE Client_Master (
	cno VARCHAR(8) PRIMARY KEY,
	name VARCHAR(20),
	address VARCHAR(50),
	dues NUMBER
);

INSERT INTO Client_Master VALUES ('01430', 'Gazorpzorp', 'Lowlanet', 3000);
INSERT INTO Client_Master VALUES ('04862', 'Ifiwiuefiu', 'Ppdjsfro', 4000);
INSERT INTO Client_Master VALUES ('16796', 'Loswiueweo', 'Xvwouire', 6000);

DROP TABLE Audi_Client;

CREATE TABLE Audi_Client (
	operation VARCHAR(6),
	tstamp TIMESTAMP,
	cno VARCHAR(8),
	name VARCHAR(20),
	address VARCHAR(50),
	dues NUMBER,
	userid VARCHAR(5)
);

CREATE OR REPLACE TRIGGER ClientAudit
BEFORE UPDATE OR DELETE ON Client_Master FOR EACH ROW
BEGIN
	CASE
		WHEN UPDATING THEN
			INSERT INTO Audi_Client VALUES ('UPDATE', CURRENT_TIMESTAMP, :NEW.cno, :NEW.name, :NEW.address, :NEW.dues, NULL);
		WHEN DELETING THEN
			INSERT INTO Audi_Client VALUES ('DELETE', CURRENT_TIMESTAMP, :OLD.cno, :OLD.name, :OLD.address, :OLD.dues, NULL);
	END CASE;
END;
/

5--

CREATE OR REPLACE VIEW Advisor_Student AS
	SELECT s_id, s.name AS s_name, s.dept_name AS s_dept, s.tot_cred, i_id, i.name AS i_name, i.dept_name AS i_dept, i.salary
	FROM ((Student s JOIN Advisor a ON s.id = a.s_id) JOIN Instructor i on i_id = i.id);

CREATE OR REPLACE TRIGGER AdvUpdate
INSTEAD OF DELETE ON Advisor_Student FOR EACH ROW
BEGIN
	DELETE FROM Advisor WHERE s_id = :OLD.s_id;
END;
/