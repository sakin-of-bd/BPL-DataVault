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

