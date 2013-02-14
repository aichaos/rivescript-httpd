CREATE TABLE rs_session (
	sessid CHAR(32) NOT NULL,
	vars TEXT DEFAULT NULL,
	last_modified DATETIME DEFAULT '0000-00-00 00:00:00',
	PRIMARY KEY (sessid)
);
