----bating statics 
WITH player_match_runs AS (
    SELECT 
        b.striker,
        b.matchid,
        SUM(s.runscored) AS total_runs_in_match
    FROM 
        ball_by_ball b
    JOIN 
        scoredruns s ON b.matchid = s.matchid 
                    AND b.overno = s.overno 
                    AND b.ball_no = s.ball_no 
                    AND b.inningsno = s.inningsno
    GROUP BY 
        b.striker, b.matchid
),

player_totals AS (
    SELECT 
        b.striker,
        SUM(s.runscored) AS total_runs,
        COUNT(*) AS balls_faced
    FROM 
        ball_by_ball b
    JOIN 
        scoredruns s ON b.matchid = s.matchid 
                    AND b.overno = s.overno 
                    AND b.ball_no = s.ball_no 
                    AND b.inningsno = s.inningsno
    GROUP BY 
        b.striker
)

SELECT 
    pt.striker AS player_name,
    pt.total_runs,
    pt.balls_faced,
    ROUND(pt.total_runs * 100.0 / pt.balls_faced, 2) AS strike_rate,
    COUNT(CASE WHEN pmr.total_runs_in_match BETWEEN 50 AND 99 THEN 1 END) AS fifties,
    COUNT(CASE WHEN pmr.total_runs_in_match >= 100 THEN 1 END) AS hundreds
FROM 
    player_totals pt
LEFT JOIN 
    player_match_runs pmr ON pt.striker = pmr.striker
GROUP BY 
    pt.striker, pt.total_runs, pt.balls_faced
ORDER BY 
    pt.total_runs DESC;



-----bowling statics
SELECT
    bb.bowler,
    COUNT(DISTINCT bb.matchid) AS total_matches_played, 
    COUNT(CASE WHEN wt.outtype NOT IN ('run out', 'Run Out') THEN wt.overno ELSE NULL END) AS total_wickets,
    ROUND(SUM(sr.runscored + NVL(er.extraruns, 0)) / NULLIF(COUNT(CASE WHEN wt.outtype NOT IN ('run out', 'Run Out') THEN wt.overno ELSE NULL END), 0), 2) AS bowling_average,
    ROUND((SUM(sr.runscored + NVL(er.extraruns, 0)) / NULLIF(COUNT(bb.ball_no), 0)) * 6, 2) AS economy_rate
FROM
    ball_by_ball bb
JOIN
    match m ON bb.matchid = m.matchid
LEFT JOIN
    wickettaken wt ON bb.overno = wt.overno
                  AND bb.ball_no = wt.ball_no
                  AND bb.inningsno = wt.inningsno
                  AND bb.matchid = wt.matchid
LEFT JOIN
    scoredruns sr ON bb.overno = sr.overno
                 AND bb.ball_no = sr.ball_no
                 AND bb.inningsno = sr.inningsno
                 AND bb.matchid = sr.matchid
LEFT JOIN
    extraruns er ON bb.overno = er.overno
                AND bb.ball_no = er.ball_no
                AND bb.inningsno = er.inningsno
                AND bb.matchid = er.matchid
GROUP BY
    bb.bowler
ORDER BY
    total_wickets DESC;


----Team Statics over seasons

WITH all_matches AS (
    SELECT 
        m.matchid,
        m.seasonyear,
        m.team1,
        m.team2,
        m.matchtype,
        r.matchwinner
    FROM 
        match m
    JOIN 
        matchresult r ON m.matchid = r.matchid
),
team_outcomes AS (
    SELECT 
        seasonyear,
        matchid,
        matchtype,
        team1 AS team,
        CASE 
            WHEN team1 = matchwinner THEN 'WIN'
            WHEN team2 = matchwinner THEN 'LOSS'
            ELSE 'LOSS' 
        END AS result
    FROM all_matches

    UNION ALL

    SELECT 
        seasonyear,
        matchid,
        matchtype,
        team2 AS team,
        CASE 
            WHEN team2 = matchwinner THEN 'WIN'
            WHEN team1 = matchwinner THEN 'LOSS'
            ELSE 'LOSS'
        END AS result
    FROM all_matches
),
aggregated AS (
    SELECT 
        seasonyear,
        team,
        COUNT(*) AS total_matches,
        COUNT(CASE WHEN result = 'WIN' THEN 1 END) AS total_wins,
        COUNT(CASE WHEN result = 'LOSS' THEN 1 END) AS total_losses,
        COUNT(CASE WHEN matchtype = 'League' AND result = 'WIN' THEN 1 END) AS league_wins,
        COUNT(CASE WHEN matchtype = 'League' THEN 1 END) AS league_matches,
        COUNT(CASE WHEN matchtype = 'Qualifier' AND result = 'WIN' THEN 1 END) AS qualifier_wins,
        COUNT(CASE WHEN matchtype = 'Eliminator' AND result = 'WIN' THEN 1 END) AS eliminator_wins,
        COUNT(CASE WHEN matchtype = 'Semi Final' AND result = 'WIN' THEN 1 END) AS semi_final_wins,
        COUNT(CASE WHEN matchtype = 'Final' AND result = 'WIN' THEN 1 END) AS final_wins
    FROM 
        team_outcomes
    GROUP BY 
        seasonyear, team
)
SELECT 
    seasonyear,
    team,
    total_matches,
    total_wins,
    total_losses,
    league_matches,
    league_wins,
    ROUND(league_wins * 100.0 / NULLIF(league_matches, 0), 2) AS league_win_ratio,
    qualifier_wins,
    eliminator_wins,
    semi_final_wins,
    final_wins
FROM 
    aggregated
ORDER BY 
    seasonyear, team;


----Chased above 180 runs

WITH innings_scores AS (
    SELECT 
        b.matchid,
        b.inningsno,
        b.teambatting,
        SUM(NVL(s.runscored, 0)) + SUM(NVL(e.extraruns, 0)) AS total_runs
    FROM 
        ball_by_ball b
    LEFT JOIN 
        scoredruns s ON b.matchid = s.matchid 
                    AND b.overno = s.overno 
                    AND b.ball_no = s.ball_no 
                    AND b.inningsno = s.inningsno
    LEFT JOIN 
        extraruns e ON b.matchid = e.matchid 
                   AND b.overno = e.overno 
                   AND b.ball_no = e.ball_no 
                   AND b.inningsno = e.inningsno
    GROUP BY 
        b.matchid, b.inningsno, b.teambatting
),
first_and_second_innings AS (
    SELECT 
        f.matchid,
        f.teambatting AS team_batted_first,
        f.total_runs AS first_innings_score,
        s.teambatting AS team_chasing,
        s.total_runs AS second_innings_score
    FROM 
        innings_scores f
    JOIN 
        innings_scores s ON f.matchid = s.matchid
    WHERE 
        f.inningsno = 1 AND s.inningsno = 2
),
successful_chases AS (
    SELECT 
        fi.matchid,
        fi.team_batted_first,
        fi.first_innings_score,
        fi.team_chasing,
        fi.second_innings_score,
        fi.first_innings_score + 1 AS target_runs
    FROM 
        first_and_second_innings fi
    WHERE 
        fi.first_innings_score + 1 > 180
        AND fi.second_innings_score > fi.first_innings_score
),
final_result AS (
    SELECT 
        sc.*,
        mr.matchwinner
    FROM 
        successful_chases sc
    JOIN 
        matchresult mr ON sc.matchid = mr.matchid
)
SELECT 
    matchid,
    team_batted_first,
    first_innings_score,
    target_runs,
    team_chasing,
    second_innings_score,
    matchwinner
FROM 
    final_result
WHERE 
    team_chasing = matchwinner
ORDER BY 
    target_runs DESC;


-----Batting average per venue

WITH innings_totals AS (
    SELECT 
        m.venuename,
        b.matchid,
        b.inningsno,
        SUM(NVL(s.runscored, 0)) + SUM(NVL(e.extraruns, 0)) AS innings_runs
    FROM 
        match m
    JOIN 
        ball_by_ball b ON m.matchid = b.matchid
    LEFT JOIN 
        scoredruns s ON b.matchid = s.matchid 
                    AND b.overno = s.overno 
                    AND b.ball_no = s.ball_no 
                    AND b.inningsno = s.inningsno
    LEFT JOIN 
        extraruns e ON b.matchid = e.matchid 
                   AND b.overno = e.overno 
                   AND b.ball_no = e.ball_no 
                   AND b.inningsno = e.inningsno
    GROUP BY 
        m.venuename, b.matchid, b.inningsno
),
venue_avg AS (
    SELECT 
        venuename,
        COUNT(*) AS total_innings,
        SUM(innings_runs) AS total_runs,
        ROUND(SUM(innings_runs) * 1.0 / COUNT(*), 2) AS avg_runs_per_innings,
        SUM(CASE WHEN inningsno = 1 THEN innings_runs ELSE 0 END) AS first_innings_total,
        ROUND(
            SUM(CASE WHEN inningsno = 1 THEN innings_runs ELSE 0 END) * 1.0 /
            NULLIF(COUNT(CASE WHEN inningsno = 1 THEN 1 END), 0), 2
        ) AS avg_first_innings_runs
    FROM 
        innings_totals
    GROUP BY 
        venuename
)
SELECT 
    venuename,
    total_innings,
    total_runs,
    avg_runs_per_innings,
    first_innings_total,
    avg_first_innings_runs
FROM 
    venue_avg
ORDER BY 
    avg_first_innings_runs DESC;




-----Highest innings in a match 

WITH team_innings_scores AS (
    SELECT 
        b.matchid,
        b.teambatting,
        b.inningsno,
        SUM(NVL(s.runscored, 0)) + SUM(NVL(e.extraruns, 0)) AS total_score
    FROM 
        ball_by_ball b
    LEFT JOIN 
        scoredruns s ON b.matchid = s.matchid 
                    AND b.overno = s.overno 
                    AND b.ball_no = s.ball_no 
                    AND b.inningsno = s.inningsno
    LEFT JOIN 
        extraruns e ON b.matchid = e.matchid 
                   AND b.overno = e.overno 
                   AND b.ball_no = e.ball_no 
                   AND b.inningsno = e.inningsno
    GROUP BY 
        b.matchid, b.teambatting, b.inningsno
),
top_scores AS (
    SELECT 
        t.matchid,
        t.teambatting,
        t.inningsno,
        t.total_score,
        RANK() OVER (ORDER BY t.total_score DESC) AS score_rank
    FROM 
        team_innings_scores t
)
SELECT 
    ts.matchid,
    ts.teambatting AS team,
    ts.inningsno,
    ts.total_score,
    mr.matchwinner,
    mr.wintype,
    mr.winmargin
FROM 
    top_scores ts
JOIN 
    matchresult mr ON ts.matchid = mr.matchid
WHERE 
    ts.score_rank <= 5
ORDER BY 
    ts.total_score DESC;



-----bowlers with the most wickets

WITH BowlerWicketsPerSeason AS (
    SELECT
        bb.bowler,
        m.seasonyear,
        COUNT(CASE WHEN wt.outtype NOT IN ('run out', 'Run Out') THEN wt.overno ELSE NULL END) AS total_wickets_in_season
    FROM
        ball_by_ball bb
    JOIN
        match m ON bb.matchid = m.matchid
    LEFT JOIN
        wickettaken wt ON bb.overno = wt.overno
                      AND bb.ball_no = wt.ball_no
                      AND bb.inningsno = wt.inningsno
                      AND bb.matchid = wt.matchid
    GROUP BY
        bb.bowler,
        m.seasonyear
),
RankedBowlers AS (
    SELECT
        bowler,
        seasonyear,
        total_wickets_in_season,
        ROW_NUMBER() OVER (PARTITION BY seasonyear ORDER BY total_wickets_in_season DESC) AS rnk
    FROM
        BowlerWicketsPerSeason
)
SELECT
    bowler,
    seasonyear,
    total_wickets_in_season
FROM
    RankedBowlers
WHERE
    rnk = 1
ORDER BY
    seasonyear ASC;


-----Most Sixes in each season 

SELECT player_name, seasonyear, sixes
FROM (
    SELECT
        b.striker AS player_name,
        m.seasonyear,
        COUNT(*) AS sixes,
        RANK() OVER (PARTITION BY m.seasonyear ORDER BY COUNT(*) DESC) AS rank
    FROM
        scoredruns s
    JOIN ball_by_ball b
        ON s.overno = b.overno
        AND s.ball_no = b.ball_no
        AND s.inningsno = b.inningsno
        AND s.matchid = b.matchid
    JOIN match m
        ON s.matchid = m.matchid
    WHERE
        s.runscored = 6
    GROUP BY
        b.striker, m.seasonyear
)
WHERE rank = 1
ORDER BY seasonyear;



---Top win ration in each seasons

WITH TeamMatchesPlayed AS (
    SELECT
        team_name,
        COUNT(matchid) AS total_matches
    FROM (
        
        SELECT m.team1 AS team_name, m.matchid
        FROM match m
        UNION ALL
        
        SELECT m.team2 AS team_name, m.matchid
        FROM match m
    )
    GROUP BY
        team_name
)
SELECT
    mr.matchwinner AS team,
    COUNT(*) AS matches_won,
    tmp.total_matches AS total_matches_played, 
    ROUND(
        COUNT(*) * 100.0 / NULLIF(tmp.total_matches, 0),
    2) AS win_percentage
FROM
    matchresult mr
JOIN
    TeamMatchesPlayed tmp ON mr.matchwinner = tmp.team_name
WHERE
    mr.matchwinner IS NOT NULL
GROUP BY
    mr.matchwinner,
    tmp.total_matches
ORDER BY
    win_percentage DESC
FETCH FIRST 5 ROWS ONLY;


----Toss impact in each season

SELECT
    t.tossdecision,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN t.tosswinner = r.matchwinner THEN 1 ELSE 0 END) AS matches_won_after_toss,
    ROUND(
        100.0 * SUM(CASE WHEN t.tosswinner = r.matchwinner THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS win_percentage
FROM
    toss t
JOIN matchresult r
    ON t.matchid = r.matchid
WHERE
    t.tossdecision IS NOT NULL
GROUP BY
    t.tossdecision;


------Most contribution in each season 

SELECT
    seasonyear,
    manofthematch AS player,
    awards
FROM (
    SELECT
        m.seasonyear,
        r.manofthematch,
        COUNT(*) AS awards,
        RANK() OVER (PARTITION BY m.seasonyear ORDER BY COUNT(*) DESC) AS rnk
    FROM
        matchresult r
    JOIN match m ON r.matchid = m.matchid
    WHERE
        r.manofthematch IS NOT NULL
    GROUP BY
        m.seasonyear, r.manofthematch
)
WHERE rnk = 1
ORDER BY seasonyear;


------Most wasted match in each seasons 

SELECT
    seasonyear,
    COUNT(*) AS dl_matches
FROM
    match
WHERE
    UPPER(method) = 'D/L'
GROUP BY
    seasonyear
ORDER BY
    seasonyear;


-----Head to Head match against each teams 

SELECT
    CASE
        WHEN LEAST(m.team1, m.team2) = :P34_RECORD THEN GREATEST(m.team1, m.team2)
        ELSE LEAST(m.team1, m.team2)
    END AS opponent_team,
    COUNT(*) AS matches_faced,
    SUM(CASE WHEN mr.matchwinner = :P34_RECORD THEN 1 ELSE 0 END) AS selected_team_wins,
    SUM(CASE WHEN mr.matchwinner IS NOT NULL AND mr.matchwinner != :P34_RECORD THEN 1 ELSE 0 END) AS opponent_wins
FROM
    match m
JOIN
    matchresult mr ON m.matchid = mr.matchid
WHERE
    mr.matchwinner IS NOT NULL
    AND (m.team1 = :P34_RECORD OR m.team2 = :P34_RECORD)
GROUP BY
    LEAST(m.team1, m.team2),
    GREATEST(m.team1, m.team2)
ORDER BY
    opponent_team;


----Top 10 ducks of all times

SELECT
    bb.striker AS player_name,
    COUNT(wt.playerout) AS total_ducks
FROM
    ball_by_ball bb
JOIN
    wickettaken wt ON bb.overno = wt.overno
                  AND bb.ball_no = wt.ball_no
                  AND bb.inningsno = wt.inningsno
                  AND bb.matchid = wt.matchid
LEFT JOIN
    scoredruns sr ON bb.overno = sr.overno
                 AND bb.ball_no = sr.ball_no
                 AND bb.inningsno = sr.inningsno
                 AND bb.matchid = sr.matchid
WHERE
    bb.striker = wt.playerout 
    AND sr.runscored = 0 
    AND wt.outtype NOT IN (
        'run out',
        'Run Out',
        'retired hurt',
        'Retired Hurt',
        'obstructing the field', 
        'hit wicket' 
    )
GROUP BY
    bb.striker
ORDER BY
    total_ducks DESC
FETCH FIRST 10 ROWS ONLY;


-----Top 5 filders with most caught

SELECT
    wt.fielder AS player_name,
    COUNT(*) AS total_catches
FROM
    wickettaken wt
WHERE
    wt.outtype = 'caught' 
    AND wt.fielder IS NOT NULL 
GROUP BY
    wt.fielder
ORDER BY
    total_catches DESC
FETCH FIRST 5 ROWS ONLY;


----Top 5 bowlers with worst economy 

SELECT
    bb.bowler AS player_name,
    SUM(sr.runscored + NVL(er.extraruns, 0)) AS runs_conceded,
    COUNT(bb.ball_no) AS balls_bowled,
    ROUND((SUM(sr.runscored + NVL(er.extraruns, 0)) / NULLIF(COUNT(bb.ball_no), 0)) * 6, 2) AS economy_rate
FROM
    ball_by_ball bb
LEFT JOIN
    scoredruns sr ON bb.overno = sr.overno
                 AND bb.ball_no = sr.ball_no
                 AND bb.inningsno = sr.inningsno
                 AND bb.matchid = sr.matchid
LEFT JOIN
    extraruns er ON bb.overno = er.overno
                AND bb.ball_no = er.ball_no
                AND bb.inningsno = er.inningsno
                AND bb.matchid = er.matchid
GROUP BY
    bb.bowler
HAVING
    COUNT(bb.ball_no) >= 60
ORDER BY
    economy_rate DESC
FETCH FIRST 5 ROWS ONLY;


-----Top 5 bowlers with most exrtra runs given 

SELECT
    bb.bowler AS player_name,
    SUM(er.extraruns) AS total_extras_conceded
FROM
    ball_by_ball bb
JOIN
    extraruns er ON bb.overno = er.overno
                 AND bb.ball_no = er.ball_no
                 AND bb.inningsno = er.inningsno
                 AND bb.matchid = er.matchid
WHERE
    er.extratype IN ('wides', 'noballs')
GROUP BY
    bb.bowler
ORDER BY
    total_extras_conceded DESC
FETCH FIRST 5 ROWS ONLY;





