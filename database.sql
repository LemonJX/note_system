DROP DATABASE IF EXISTS note_project;
CREATE DATABASE note_project;
USE note_project;

CREATE TABLE users
( 
	username VARCHAR(64) PRIMARY KEY,
    password VARCHAR(64) NOT NULL
);

CREATE TABLE notebook
(
	nb_createTime BIGINT PRIMARY KEY,
	nb_name VARCHAR(64) NOT NULL,
    author VARCHAR(64) NOT NULL,
    FOREIGN KEY (author) REFERENCES users (username) ON DELETE CASCADE ON UPDATE CASCADE 
);

CREATE TABLE booktag
(
	tag VARCHAR(64) PRIMARY KEY,
    priority INT AUTO_INCREMENT UNIQUE
);

CREATE TABLE hasbooktag
( 
	notebook BIGINT NOT NULL,
	tag VARCHAR(64) NOT NULL,
    CONSTRAINT hasbooktag_pk
    PRIMARY KEY (notebook, tag),
    FOREIGN KEY (notebook) REFERENCES notebook (nb_createTime) ON DELETE CASCADE ON UPDATE CASCADE ,
    FOREIGN KEY (tag) REFERENCES booktag (tag) ON DELETE CASCADE ON UPDATE CASCADE 
);

CREATE TABLE note
( 
	note_createTime BIGINT PRIMARY KEY,
    notebook BIGINT NOT NULL,
	title VARCHAR(64) NOT NULL,
	content VARCHAR(1000) NOT NULL,
    FOREIGN KEY (notebook) REFERENCES notebook (nb_createTime) ON DELETE CASCADE ON UPDATE CASCADE 
);

CREATE TABLE notetag
(
	tag VARCHAR(64) PRIMARY KEY,
    priority INT AUTO_INCREMENT UNIQUE
);

CREATE TABLE hasnotetag
( 
	note BIGINT NOT NULL,
	tag VARCHAR(64) NOT NULL,
    CONSTRAINT hasnotetag_pk
    PRIMARY KEY (note, tag),
    FOREIGN KEY (note) REFERENCES note (note_createTime) ON DELETE CASCADE ON UPDATE CASCADE ,
    FOREIGN KEY (tag) REFERENCES notetag (tag) ON DELETE CASCADE ON UPDATE CASCADE 
);

-- procedures

DROP PROCEDURE IF EXISTS register;
DELIMITER //
CREATE PROCEDURE register(myname VARCHAR(64), mypasswd VARCHAR(64))
BEGIN
	INSERT INTO users VALUES (myname, mypasswd);
END //
DELIMITER ;

DROP FUNCTION IF EXISTS checkusername;
DELIMITER //
CREATE FUNCTION checkusername(myname VARCHAR(64)) RETURNS BOOLEAN
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE exist VARCHAR(64) DEFAULT NULL;
    SELECT username INTO exist FROM users WHERE username=myname;
	IF exist IS NULL THEN RETURN TRUE; -- can register with this new name
	ELSE RETURN FALSE; -- cannot register with a duplicate name
	END IF;
END //
DELIMITER ;

DROP FUNCTION IF EXISTS login;
DELIMITER //
CREATE FUNCTION login(myname VARCHAR(64), mypasswd VARCHAR(64)) RETURNS BOOLEAN
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE correctpass VARCHAR(64) DEFAULT NULL;
    SELECT password INTO correctpass FROM users WHERE username=myname;
	IF correctpass = mypasswd THEN RETURN TRUE;
	ELSE RETURN FALSE;
	END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS createBookTag;
DELIMITER //
CREATE PROCEDURE createBookTag(mytag VARCHAR(64), mynbid BIGINT)
BEGIN
	DECLARE existTag VARCHAR(64) DEFAULT NULL;
	SELECT tag INTO existTag FROM booktag WHERE tag = mytag;
    IF (existTag IS NULL) THEN
	INSERT INTO booktag (tag) VALUES (mytag);
    END IF;
    INSERT INTO hasbooktag VALUES (mynbid, mytag);
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS deleteBookTag;
DELIMITER //
CREATE PROCEDURE deleteBookTag(mytag VARCHAR(64), mynbid BIGINT)
BEGIN
	DECLARE existBook VARCHAR(64) DEFAULT NULL;
    DELETE FROM hasbooktag WHERE tag = mytag AND notebook = mynbid;
	SELECT notebook INTO existBook FROM hasbooktag WHERE tag = mytag LIMIT 1;
    IF (existBook IS NULL) THEN
	DELETE FROM booktag WHERE tag = mytag;
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS createNoteTag;
DELIMITER //
CREATE PROCEDURE createNoteTag(mytag VARCHAR(64), notetitle VARCHAR(64), mynotebook BIGINT)
BEGIN
	DECLARE noteid BIGINT;
    DECLARE existTag VARCHAR(64) DEFAULT NULL;
    SELECT note_createTime INTO noteid FROM note WHERE notebook = mynotebook AND title = notetitle;
	SELECT tag INTO existTag FROM notetag WHERE tag = mytag;
    IF (existTag IS NULL) THEN
	INSERT INTO notetag (tag) VALUES (mytag);
    END IF;
    INSERT INTO hasnotetag VALUES (noteid, mytag);
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS deleteNoteTag;
DELIMITER //
CREATE PROCEDURE deleteNoteTag(mytag VARCHAR(64), notetitle VARCHAR(64), mynotebook BIGINT)
BEGIN
    DECLARE noteid BIGINT;
    DECLARE existNote VARCHAR(64) DEFAULT NULL;
    SELECT note_createTime INTO noteid FROM note WHERE notebook = mynotebook AND title = notetitle;
    DELETE FROM hasnotetag WHERE tag = mytag AND note = noteid;
	SELECT note INTO existNote FROM hasnotetag WHERE tag = mytag LIMIT 1;
    IF (existNote IS NULL) THEN
	DELETE FROM notetag WHERE tag = mytag;
    END IF;
END //
DELIMITER ;

DROP FUNCTION IF EXISTS createNote;
DELIMITER //
CREATE FUNCTION createNote(mynbid BIGINT, mytitle VARCHAR(64)) RETURNS BOOLEAN
DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE exist VARCHAR(64) DEFAULT NULL;
    SELECT title INTO exist FROM note WHERE notebook=mynbid AND title=mytitle;
    
	IF exist IS NULL THEN 
    INSERT INTO note (note_createTime, notebook, title, content) VALUES 
    (CAST(SUBSTR(date_format(NOW(3), '%Y%m%d%H%i%s%f'), 1, 17) AS SIGNED), mynbid, mytitle, '');
    RETURN TRUE;
	ELSE RETURN FALSE;
	END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS deleteNote;
DELIMITER //
CREATE PROCEDURE deleteNote(mynbid BIGINT, mytitle VARCHAR(64))
BEGIN
	DECLARE noteid BIGINT;
	SELECT note_createTime INTO noteid FROM note WHERE notebook=mynbid AND title=mytitle;
	DELETE FROM hasnotetag WHERE note=noteid;
    DELETE FROM notetag WHERE tag NOT IN (SELECT tag FROM hasnotetag);
	DELETE FROM note WHERE notebook=mynbid AND title=mytitle;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS updateNote;
DELIMITER //
CREATE PROCEDURE updateNote(mytext VARCHAR(1000), mytitle VARCHAR(64), mynotebook BIGINT)
BEGIN
	UPDATE note SET content=mytext WHERE title=mytitle AND notebook=mynotebook;
END //
DELIMITER ;

DROP FUNCTION IF EXISTS createNotebook;
DELIMITER //
CREATE FUNCTION createNotebook(myname VARCHAR(64), myauthor VARCHAR(64)) RETURNS BOOLEAN
DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE exist VARCHAR(64) DEFAULT NULL;
    SELECT nb_name INTO exist FROM notebook WHERE nb_name=myname;
    
	IF exist IS NULL THEN 
    INSERT INTO notebook (nb_createTime, nb_name, author) VALUES 
    (CAST(SUBSTR(date_format(NOW(3), '%Y%m%d%H%i%s%f'), 1, 17) AS SIGNED), myname, myauthor);
    RETURN TRUE;
	ELSE RETURN FALSE;
	END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS deleteNotebook;
DELIMITER //
CREATE PROCEDURE deleteNotebook(mynbid BIGINT)
BEGIN
	DELETE FROM note WHERE notebook=mynbid;
	DELETE FROM hasbooktag WHERE notebook=mynbid;
    DELETE FROM booktag WHERE tag NOT IN (SELECT tag FROM hasbooktag);
	DELETE FROM notebook WHERE nb_createTime=mynbid;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getBookNameById;
DELIMITER //
CREATE PROCEDURE getBookNameById(mynbid BIGINT)
BEGIN
	SELECT nb_name FROM notebook WHERE nb_createTime=mynbid;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getAllNotebooks;
DELIMITER //
CREATE PROCEDURE getAllNotebooks(myusername VARCHAR(64))
BEGIN
	SELECT * FROM notebook WHERE author=myusername;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getNotebooksBySearch;
DELIMITER //
CREATE PROCEDURE getNotebooksBySearch(myusername VARCHAR(64), searchWord VARCHAR(64))
BEGIN
	SELECT * FROM notebook WHERE author=myusername AND nb_name LIKE CONCAT('%',searchWord,'%');
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getNotebooksByTag;
DELIMITER //
CREATE PROCEDURE getNotebooksByTag(myusername VARCHAR(64), searchTag VARCHAR(64))
BEGIN
	SELECT * FROM notebook RIGHT JOIN hasbooktag ON nb_createTime = notebook WHERE author=myusername AND tag=searchTag;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getAllBookTags;
DELIMITER //
CREATE PROCEDURE getAllBookTags(myusername VARCHAR(64))
BEGIN
	SELECT tag FROM booktag WHERE tag IN
		(SELECT tag FROM hasbooktag LEFT JOIN notebook ON notebook = nb_createTime
		WHERE author=myusername)
	ORDER BY priority DESC;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getAllNotes;
DELIMITER //
CREATE PROCEDURE getAllNotes(mynbid BIGINT)
BEGIN
	SELECT * FROM note WHERE notebook=mynbid;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getNotesBySearch;
DELIMITER //
CREATE PROCEDURE getNotesBySearch(mynbid BIGINT, searchWord VARCHAR(64))
BEGIN
	SELECT * FROM note WHERE notebook=mynbid AND title LIKE CONCAT('%',searchWord,'%');
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getNotesByTag;
DELIMITER //
CREATE PROCEDURE getNotesByTag(mynbid BIGINT, searchTag VARCHAR(64))
BEGIN
	SELECT * FROM note RIGHT JOIN hasnotetag ON note_createTime = note 
    WHERE notebook=mynbid AND tag=searchTag;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getAllNoteTags;
DELIMITER //
CREATE PROCEDURE getAllNoteTags(mynbid BIGINT)
BEGIN
	SELECT tag FROM notetag WHERE tag IN
		(SELECT tag FROM hasnotetag LEFT JOIN note ON note = note_createTime 
        WHERE notebook=mynbid)
	ORDER BY priority DESC;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getTagsOfANotebook;
DELIMITER //
CREATE PROCEDURE getTagsOfANotebook(mynbid BIGINT)
BEGIN
	SELECT tag FROM booktag WHERE tag IN 
		(SELECT tag FROM hasbooktag WHERE notebook=mynbid)
	ORDER BY priority DESC;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getTagsOfANote;
DELIMITER //
CREATE PROCEDURE getTagsOfANote(mynbid BIGINT, mynote VARCHAR(64))
BEGIN
	SELECT tag FROM notetag WHERE tag IN
		(SELECT tag FROM hasnotetag LEFT JOIN note ON note = note_createTime 
		WHERE notebook=mynbid AND title=mynote)
	ORDER BY priority DESC;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS getContent;
DELIMITER //
CREATE PROCEDURE getContent(mynotebook BIGINT, mytitle VARCHAR(64))
BEGIN
	SELECT content FROM note WHERE notebook=mynotebook AND title=mytitle;
END //
DELIMITER ;

-- sample data
CALL register('Alice', 'password1');
CALL register('Bob', 'password2');

SELECT createNotebook('recent', 'Alice');
SELECT createNotebook('CS5200', 'Alice');
SELECT createNotebook('CS5010', 'Alice');
SELECT createNotebook('BobNotebook', 'Bob');	-- not show when Alice login

SET @nb = (SELECT nb_createTime FROM notebook WHERE author = 'Alice' AND nb_name = 'recent');
SET @nb2 = (SELECT nb_createTime FROM notebook WHERE author = 'Alice' AND nb_name = 'CS5200');
SET @nb3 = (SELECT nb_createTime FROM notebook WHERE author = 'Alice' AND nb_name = 'CS5010');
SET @nb4 = (SELECT nb_createTime FROM notebook WHERE author = 'Bob' AND nb_name = 'BobNotebook');
CALL createBookTag('2022Fall', @nb2);
CALL createBookTag('NEU', @nb2);
CALL createBookTag('2021Fall', @nb3);
CALL createBookTag('NEU', @nb3);
CALL createBookTag('BobTag', @nb4);				-- not show when Alice login

SELECT createNote(@nb, 'TODO');
SELECT createNote(@nb, 'websites');
SELECT createNote(@nb2, 'deltest');	-- for testing delete note
SELECT createNote(@nb2, 'lecture1');
SELECT createNote(@nb2, 'lecture2');
SELECT createNote(@nb2, 'homework1');
SELECT createNote(@nb2, 'homework2');
SELECT createNote(@nb3, 'lecture1');
SELECT createNote(@nb3, 'lecture2');
SELECT createNote(@nb3, 'homework1');
SELECT createNote(@nb3, 'homework2');

CALL updateNote('TODO:\n1. abc\n2. def','TODO',@nb);
CALL updateNote('www.google.com\npython flask: https://www.w3cschool.cn/flask/flask-sgtc3gx7.html\nsql: https://www.w3schools.com/sql/sql_datatypes.asp\n','websites',@nb);

CALL createNoteTag('del', 'deltest', @nb2);	-- 'del' disappear after delete deltest
CALL createNoteTag('lec', 'lecture1', @nb2);
CALL createNoteTag('lec', 'lecture2', @nb2);
CALL createNoteTag('hw', 'homework1', @nb2);
CALL createNoteTag('hw', 'homework2', @nb2);
CALL createNoteTag('week1', 'lecture1', @nb2);
CALL createNoteTag('week1', 'homework1', @nb2);
CALL createNoteTag('week2', 'lecture2', @nb2);
CALL createNoteTag('week2', 'homework2', @nb2);

CALL createNoteTag('lec', 'lecture1', @nb3);
CALL createNoteTag('lec', 'lecture2', @nb3);
CALL createNoteTag('hw', 'homework1', @nb3);
CALL createNoteTag('hw', 'homework2', @nb3);
CALL createNoteTag('week1', 'lecture1', @nb3);
CALL createNoteTag('week1', 'homework1', @nb3);
CALL createNoteTag('week2', 'lecture2', @nb3);
CALL createNoteTag('week2', 'homework2', @nb3);

-- test
-- SELECT * FROM users;
-- SELECT * FROM notebook;
-- SELECT * FROM booktag;
-- SELECT * FROM hasbooktag;
-- SELECT * FROM note;
-- SELECT * FROM notetag;
-- SELECT * FROM hasnotetag;

-- SELECT checkusername('Alice');
-- SELECT login('Alice', 'password1');
-- SELECT login('Alice', 'wrongpass');
-- CALL getContent(@nb, 'TODO');
-- CALL getAllNotebooks('Alice');
-- CALL getNotebooksBySearch('Alice','recen');
-- CALL getNotebooksByTag('Alice','NEU');
-- CALL getAllBookTags('Alice');
-- CALL deleteNote(@nb2, 'deltest');
-- CALL getTagsOfANote(@nb2, 'lecture1');