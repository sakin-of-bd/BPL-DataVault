--CREATE PART
CREATE TABLE ball_by_ball (
    matchid       NUMBER NOT NULL,
    inningsno     NUMBER NOT NULL,
    overno        NUMBER NOT NULL,
    ball_no       NUMBER NOT NULL,
    teambatting   VARCHAR2(50),
    team_bowling  VARCHAR2(50),
    striker       VARCHAR2(50),
    Non_Striker   VARCHAR2(50),
    bowler        VARCHAR2(50)
);

ALTER TABLE ball_by_ball
    ADD CONSTRAINT ball_by_ball_pk
        PRIMARY KEY ( matchid,
                      inningsno,
                      overno,
                      ball_no );


CREATE TABLE extraruns (
    matchid    NUMBER NOT NULL,
    inningsno  NUMBER NOT NULL,
    overno     NUMBER NOT NULL,
    ball_no    NUMBER NOT NULL,
    extratype  VARCHAR2(12),
    extraruns  NUMBER
);

ALTER TABLE extraruns
    ADD CONSTRAINT extraruns_pk
        PRIMARY KEY ( matchid,
                      inningsno,
                      overno,
                      ball_no );


CREATE TABLE match (
    matchid    NUMBER NOT NULL,
    team1      VARCHAR2(50),
    team2      VARCHAR2(50),
    matchtype  VARCHAR2(20),
    matchdate  DATE,
    venuename  VARCHAR2(100) NOT NULL,
    seasonyear VARCHAR2(8) NOT NULL,
    method     VARCHAR2(10)
);

ALTER TABLE match ADD CONSTRAINT match_pk PRIMARY KEY ( matchid );


CREATE TABLE matchresult (
    matchid        NUMBER NOT NULL,
    matchwinner    VARCHAR2(50),
    wintype        VARCHAR2(30),
    winmargin      VARCHAR2(12),
    manofthematch  VARCHAR2(50)
);

ALTER TABLE matchresult ADD CONSTRAINT matchresult_pk PRIMARY KEY ( matchid );


CREATE TABLE player (
    playerid   NUMBER NOT NULL,
    playername VARCHAR2(50)
);

ALTER TABLE player ADD CONSTRAINT player_pk PRIMARY KEY ( playerid );


CREATE TABLE scoredruns (
    matchid    NUMBER NOT NULL,
    inningsno  NUMBER NOT NULL,
    overno     NUMBER NOT NULL,
    ball_no    NUMBER NOT NULL,
    runscored  NUMBER
);

ALTER TABLE scoredruns
    ADD CONSTRAINT scoredruns_pk
        PRIMARY KEY ( matchid,
                      inningsno,
                      overno,
                      ball_no );


CREATE TABLE season (
    seasonyear            VARCHAR2(8) NOT NULL,
    playerofthetournament VARCHAR2(50)
);

ALTER TABLE season ADD CONSTRAINT season_pk PRIMARY KEY ( seasonyear );


CREATE TABLE season_team_player (
    playerid   NUMBER NOT NULL,
    seasonyear VARCHAR2(8) NOT NULL,
    teamname   VARCHAR2(50) NOT NULL
);

ALTER TABLE season_team_player
    ADD CONSTRAINT season_team_player_pk PRIMARY KEY ( playerid,
                                                       seasonyear,
                                                       teamname );


CREATE TABLE team (
    teamname     VARCHAR2(50) NOT NULL,
    teamlogo     BLOB,
    mime_type    VARCHAR2(20),
    file_type    VARCHAR2(20),
    updated_date DATE
);

ALTER TABLE team ADD CONSTRAINT team_pk PRIMARY KEY ( teamname );


CREATE TABLE toss (
    matchid      NUMBER NOT NULL,
    tosswinner   VARCHAR2(50),
    tossdecision VARCHAR2(12)
);

ALTER TABLE toss ADD CONSTRAINT toss_pk PRIMARY KEY ( matchid );


CREATE TABLE umpire (
    umpireid   NUMBER NOT NULL,
    umpirename VARCHAR2(50)
);

ALTER TABLE umpire ADD CONSTRAINT umpire_pk PRIMARY KEY ( umpireid );


CREATE TABLE umpired_by (
    matchid  NUMBER NOT NULL,
    umpireid NUMBER NOT NULL
);

ALTER TABLE umpired_by ADD CONSTRAINT umpired_by_pk PRIMARY KEY ( matchid,
                                                                  umpireid );


CREATE TABLE venue (
    venuename    VARCHAR2(80) NOT NULL,
    venuepic     BLOB,
    mime_type    VARCHAR2(20),
    file_type    VARCHAR2(20),
    updated_date DATE,
    cityname     VARCHAR2(25)
);

ALTER TABLE venue ADD CONSTRAINT venue_pk PRIMARY KEY ( venuename );


CREATE TABLE wickettaken (
    matchid    NUMBER NOT NULL,
    inningsno  NUMBER NOT NULL,
    overno     NUMBER NOT NULL,
    ball_no    NUMBER NOT NULL,
    playerout  VARCHAR2(50),
    fielder    VARCHAR2(50),
    outtype    VARCHAR2(50)
);

ALTER TABLE wickettaken
    ADD CONSTRAINT wickettaken_pk
        PRIMARY KEY ( matchid,
                      inningsno,
                      overno,
                      ball_no );






--NEXT
ALTER TABLE ball_by_ball
    ADD CONSTRAINT ball_by_ball_match_fk FOREIGN KEY ( matchid )
        REFERENCES match ( matchid );

ALTER TABLE extraruns
    ADD CONSTRAINT extraruns_ball_by_ball_fk
        FOREIGN KEY ( overno,
                      ball_no,
                      inningsno,
                      matchid )
            REFERENCES ball_by_ball ( overno,
                                      ball_no,
                                      inningsno,
                                      matchid );

ALTER TABLE match
    ADD CONSTRAINT match_season_fk FOREIGN KEY ( seasonyear )
        REFERENCES season ( seasonyear );

ALTER TABLE match
    ADD CONSTRAINT match_venue_fk FOREIGN KEY ( venuename )
        REFERENCES venue ( venuename );

ALTER TABLE matchresult
    ADD CONSTRAINT matchresult_match_fk FOREIGN KEY ( matchid )
        REFERENCES match ( matchid );

ALTER TABLE scoredruns
    ADD CONSTRAINT scoredruns_ball_by_ball_fk
        FOREIGN KEY ( overno,
                      ball_no,
                      inningsno,
                      matchid )
            REFERENCES ball_by_ball ( overno,
                                      ball_no,
                                      inningsno,
                                      matchid );

ALTER TABLE season_team_player
    ADD CONSTRAINT season_team_player_player_fk FOREIGN KEY ( playerid )
        REFERENCES player ( playerid );

ALTER TABLE season_team_player
    ADD CONSTRAINT season_team_player_season_fk FOREIGN KEY ( seasonyear )
        REFERENCES season ( seasonyear );

ALTER TABLE season_team_player
    ADD CONSTRAINT season_team_player_team_fk FOREIGN KEY ( teamname )
        REFERENCES team ( teamname );

ALTER TABLE toss
    ADD CONSTRAINT toss_match_fk FOREIGN KEY ( matchid )
        REFERENCES match ( matchid );

ALTER TABLE umpired_by
    ADD CONSTRAINT umpired_by_match_fk FOREIGN KEY ( matchid )
        REFERENCES match ( matchid );

ALTER TABLE umpired_by
    ADD CONSTRAINT umpired_by_umpire_fk FOREIGN KEY ( umpireid )
        REFERENCES umpire ( umpireid );

ALTER TABLE wickettaken
    ADD CONSTRAINT wickettaken_ball_by_ball_fk
        FOREIGN KEY ( overno,
                      ball_no,
                      inningsno,
                      matchid )
            REFERENCES ball_by_ball ( overno,
                                      ball_no,
                                      inningsno,
                                      matchid );
