WITH userCompany AS (
    SELECT UID, 1 AS Rank
    FROM tblFed
    WHERE User_Controlled = 1
    LIMIT 1
),
childCompanies AS (
    SELECT p.Fed1 AS UID, 2 AS Rank
    FROM tblPact p
    JOIN userCompany uc
    ON (p.Fed2 = uc.UID AND Parent2 = 1)
    UNION
    SELECT p.Fed2 AS UID, 2 AS RANK
    FROM tblPact p
    JOIN userCompany uc
    ON (p.Fed1 = uc.UID AND Parent1 = 1)
),
otherCompanies AS (
    SELECT UID, 3 AS Rank
    FROM tblFed f
    WHERE f.UID NOT IN (
        SELECT UID FROM userCompany
        UNION
        SELECT UID FROM childCompanies
    )
),
companiesRank AS (
    SELECT * FROM userCompany
    UNION ALL
    SELECT * FROM childCompanies
    UNION ALL
    SELECT * FROM otherCompanies
),
contractRank AS (
    SELECT  
        w.UID WorkerUID, 
        c.UID AS ContractUID,
        ROW_NUMBER() OVER (
        PARTITION BY w.UID
        ORDER BY cr.Rank ASC, c.ExclusiveContract DESC, c.WrittenContract DESC, f.Ranking ASC
        ) AS Rank
    FROM tblWorker w
    LEFT JOIN tblContract c
    ON w.UID = c.WorkerUID
    LEFT JOIN companiesRank cr
    ON cr.UID = c.FedUID
    LEFT JOIN tblFed f
    ON c.FedUID = f.UID
),
relevantWorkersAndContracts AS (
    SELECT WorkerUID, ContractUID
    FROM contractRank
    WHERE Rank = 1
),
workerPopularity AS (
    SELECT 
        w.UID,
        CASE 
            WHEN uc.Based_In <= 11 THEN (
                wo.Over1 +
                wo.Over2 +
                wo.Over3 +
                wo.Over4 +
                wo.Over5 +
                wo.Over6 +
                wo.Over7 +
                wo.Over8 +
                wo.Over9 +
                wo.Over10 +
                wo.Over11
            ) / 11
            WHEN uc.Based_In <= 18 THEN (
                wo.Over12 +
                wo.Over13 +
                wo.Over14 +
                wo.Over15 +
                wo.Over16 +
                wo.Over17 +
                wo.Over18
            ) / 7
            WHEN uc.Based_In <= 24 THEN (
                wo.Over19 +
                wo.Over20 +
                wo.Over21 +
                wo.Over22 +
                wo.Over23 +
                wo.Over24
            ) / 6
            WHEN uc.Based_In <= 32 THEN (
                wo.Over25 +
                wo.Over26 +
                wo.Over27 +
                wo.Over28 +
                wo.Over29 +
                wo.Over30 +
                wo.Over31 +
                wo.Over32
            ) / 8
            WHEN uc.Based_In <= 38 THEN (
                wo.Over33 +
                wo.Over34 +
                wo.Over35 +
                wo.Over36 +
                wo.Over37 +
                wo.Over38
            ) / 6
            WHEN uc.Based_In <= 46 THEN (
                wo.Over39 +
                wo.Over40 +
                wo.Over41 +
                wo.Over42 +
                wo.Over43 +
                wo.Over44 +
                wo.Over45 +
                wo.Over46
            ) / 8
            WHEN uc.Based_In <= 53 THEN (
                wo.Over47 +
                wo.Over48 +
                wo.Over49 +
                wo.Over50 +
                wo.Over51 +
                wo.Over52 +
                wo.Over53
            ) / 7
            WHEN uc.Based_In <= 57 THEN (
                wo.Over54 +
                wo.Over55 +
                wo.Over56 +
                wo.Over57
            ) / 4
            ELSE NULL
        END / 10 AS Popularity
    FROM tblWorker w
    JOIN tblWorkerOver wo
    ON wo.WorkerUID = w.UID
    CROSS JOIN (SELECT f.Based_In FROM userCompany uc JOIN tblFed f ON uc.UID = f.UID) uc
),
roles AS (
    SELECT 
        rwc.WorkerUID, 
        CAST(c.Position_Wrestler AS int) AS Wrestler,
        CAST(c.Position_Occasional AS int) AS Occasional,
        CAST(c.Position_Referee AS int) AS Referee,
        CAST(c.Position_Announcer AS int) AS Announcer,
        CAST(c.Position_Colour AS int) AS Colour,
        CAST(c.Position_Manager AS int) AS Manager,
        CAST(c.Position_Personality AS int) AS Personality,
        CAST(c.Position_Roadagent AS int) AS RoadAgent
    FROM relevantWorkersAndContracts rwc
    JOIN tblContract c
    ON rwc.ContractUID = c.UID
    JOIN companiesRank cr
    ON c.FedUID = cr.UID

    UNION ALL

    SELECT 
        rwc.WorkerUID, 
        CAST(w.Position_Wrestler AS int) AS Wrestler,
        CAST(w.Position_Occasional AS int) AS Occasional,
        CAST(w.Position_Referee AS int) AS Referee,
        CAST(w.Position_Announcer AS int) AS Announcer,
        CAST(w.Position_Colour AS int) AS Colour,
        CAST(w.Position_Manager AS int) AS Manager,
        CAST(w.Position_Personality AS int) AS Personality,
        CAST(w.Position_Roadagent AS int) AS RoadAgent
    FROM relevantWorkersAndContracts rwc
    JOIN tblWorker w
    ON rwc.WorkerUID = w.UID
    WHERE rwc.ContractUID IS NULL
),
belts AS (
    SELECT rwc.WorkerUID, GROUP_CONCAT(b.Name, CHAR(10)) AS Belts
    FROM relevantWorkersAndContracts rwc
    JOIN tblBelt b
    ON (rwc.WorkerUID = b.Holder1 OR rwc.WorkerUID = b.Holder2 OR rwc.WorkerUID = b.Holder3)
    WHERE b.Active = 1
    GROUP BY rwc.WorkerUID
),
teams AS (
    SELECT DISTINCT t.UID, t.Name, c1.WorkerUID AS Worker1UID, c2.WorkerUID AS Worker2UID
    FROM tblTeam t
    JOIN tblContract c1
    ON t.Worker1 = c1.WorkerUID AND t.Fed = c1.FedUID
    JOIN tblContract c2
    ON t.Worker2 = c2.WorkerUID AND t.Fed = c2.FedUID
    JOIN companiesRank cr
    ON cr.UID = t.Fed
    WHERE (t.Active = 1 AND t.Type < 4 AND c1.FedUID = c2.FedUID AND cr.Rank < 3)
),
workerTeams AS (
    SELECT w.UID, GROUP_CONCAT(t.Name, CHAR(10)) AS Teams
    FROM tblWorker w
    JOIN teams t
    ON (w.UID = t.Worker1UID OR w.UID = t.Worker2UID)
    GROUP BY w.UID
),
stables AS (
    SELECT s.*
    FROM tblStable s
    JOIN companiesRank cr
    ON cr.UID = s.Fed
    WHERE (s.Active = 1 AND cr.Rank < 3)
),
workerStables AS (
    SELECT w.UID, GROUP_CONCAT(s.Name, CHAR(10)) AS Stables
    FROM tblWorker w
    JOIN stables s
    ON w.UID IN (
    s.Member1,
    s.Member2,
    s.Member3,
    s.Member4,
    s.Member5,
    s.Member6,
    s.Member7,
    s.Member8,
    s.Member9,
    s.Member10,
    s.Member11,
    s.Member12,
    s.Member13,
    s.Member14,
    s.Member15,
    s.Member16,
    s.Member17,
    s.Member18
    )
    GROUP BY w.UID
),
workerManagers AS (
    SELECT c1.WorkerUID, GROUP_CONCAT(c2.Name, CHAR(10)) AS ManagerNames
    FROM tblContract c1
    JOIN tblContract c2
    ON c1.Manager = c2.WorkerUID
    JOIN companiesRank cr
    ON cr.UID = c1.FedUID
    WHERE cr.Rank < 3
    GROUP BY c1.UID
),
momentums AS (
    SELECT
        c.UID,
        CAST(SIGN(c.ContractMomentum) * CEIL(SIGN(c.ContractMomentum) * c.ContractMomentum / 100.) + 6 AS int) AS MomentumIdx
    FROM tblContract c
),
gimmickRatings AS (
    SELECT
        c.UID,
        CASE
            WHEN c.PlasterCaster_Rating <   0 THEN -1
            WHEN c.PlasterCaster_Rating < 250 THEN  0
            WHEN c.PlasterCaster_Rating < 500 THEN  1
            WHEN c.PlasterCaster_Rating < 700 THEN  2
            WHEN c.PlasterCaster_Rating < 800 THEN  3
            WHEN c.PlasterCaster_Rating < 900 THEN  4
            WHEN c.PlasterCaster_Rating       THEN  5
            ELSE NULL
        END AS RatingIdx
    FROM tblContract c
)
SELECT
    -- Worker Info
    CASE
        WHEN cr.Rank < 3 THEN c.Name
        ELSE w.Name
    END AS Name,
    CASE
        WHEN w.Gender IN (1, 2, 4) THEN "Male"
        WHEN w.Gender IN (5, 6, 8) THEN "Female"
        ELSE "Other"
    END AS Gender,
    CAST(strftime("%Y.%m%d", gi.CurrentGameDate) - strftime("%Y.%m%d", w.Birthday) AS int) AS Age,
    w.WorkerHeight AS Height,
    -- TODO: CAST(100 * (((w.WorkerHeight + 35) / 12) * 0.3048 + MOD(w.WorkerHeight + 35, 12) * 0.0254) AS int) AS Height,
    CAST(w.WorkerWeight * 0.453 AS int) AS Weight,

    -- Worker Ratings
    wp.Popularity,

    -- Worker Attributes
    wsk.Brawl / 10 AS Brawling,
    wsk.Puroresu / 10 AS Puroresu,
    wsk.Hardcore / 10 AS Hardcore,
    wsk.Technical / 10 AS Technical,
    wsk.Air / 10 AS Aerial,
    wsk.Flash / 10 AS Flashiness,

    wsk.Psych / 10 AS Psychology,
    wsk.Experience / 10 AS Experience,
    wsk.Respect / 10 AS Respect,
    wsk.Reputation / 10 AS Reputation,

    wsk.Charisma / 10 AS Charisma,
    wsk.Mic / 10 AS Microphone,
    wsk.Act / 10 AS Acting,
    wsk.Star / 10 AS StarQuality,
    wsk.Looks / 10 AS SexAppeal,
    wsk.Menace / 10 AS Menace,

    wsk.Basics / 10 AS Basics,
    wsk.Sell / 10 AS Selling,
    wsk.Consistency / 10 AS Consistency,
    wsk.Safety / 10 AS Safety,

    wsk.Stamina / 10 AS Stamina,
    wsk.Athletic / 10 AS Athleticism,
    wsk.Power / 10 AS Power,
    wsk.Tough / 10 AS Toughness,
    wsk.Injury / 10 AS Resilience,

    wsk.Announcing / 10 AS PlayByPlay,
    wsk.Colour / 10 AS ColourSkill,
    wsk.Refereeing / 10 AS Refereeing,
    wb.Business / 10 AS BusinessRep,
    wb.Booking_Reputation / 10 AS BookingRep,
    wb.Booking_Skill / 10 AS BookingSkill,

    -- Perception
    CASE 
        WHEN c.Perception = 5 THEN "Unimportant"
        WHEN c.Perception = 4 THEN "Recognisable"
        WHEN c.Perception = 3 THEN "Well Known"
        WHEN c.Perception = 2 THEN "Star"
        WHEN c.Perception = 1 THEN "Major Star"
        ELSE NULL
    END AS Perception,
    6 - c.Perception AS PerceptionIdx,
    CASE 
        WHEN m.MomentumIdx =  1 THEN "Ice Cold"
        WHEN m.MomentumIdx =  2 THEN "Very Cold"
        WHEN m.MomentumIdx =  3 THEN "Cold"
        WHEN m.MomentumIdx =  4 THEN "Chilly"
        WHEN m.MomentumIdx =  5 THEN "Cooled"
        WHEN m.MomentumIdx =  6 THEN "Neutral"
        WHEN m.MomentumIdx =  7 THEN "Warm"
        WHEN m.MomentumIdx =  8 THEN "Very Warm"
        WHEN m.MomentumIdx =  9 THEN "Hot"
        WHEN m.MomentumIdx = 10 THEN "Very Hot"
        WHEN m.MomentumIdx = 11 THEN "Red Hot"
        WHEN m.MomentumIdx = 12 THEN "White Hot"
        ELSE NULL
    END AS Momentum,
    m.MomentumIdx,


    -- Contract
    f.Initials AS Company,
    CASE WHEN cr.Rank < 3 AND fb.Brand IS NOT NULL THEN fb.Name ELSE "" END AS Brand,
    CASE WHEN c.Daysleft < 0 THEN NULL ELSE DATE(gi.CurrentGameDate, "+" || c.Daysleft || " days") END AS ExpiryDate,
    c.ExclusiveContract,
    c.WrittenContract,
    c.TouringContract,
    c.OnLoan,
    c.Developmental,
    c.Amount,
    CASE WHEN c.PaidMonthly THEN "Month" ELSE "Show" END AS Per,

    -- Role
    (r.Wrestler OR r.Occasional) AS InRing,
    r.Wrestler,
    r.Occasional,
    r.Referee,
    r.Announcer,
    r.Colour,
    r.Manager,
    r.Personality,
    r.RoadAgent,

    -- Character info
    CASE
        WHEN c.Face = 1 THEN 
        CASE WHEN c.Turn_Change = -1 THEN 'Face' ELSE 'Heel*' END
        WHEN c.Face = 0 THEN
        CASE WHEN c.Turn_Change = -1 THEN 'Heel' ELSE 'Face*' END
    END AS Side,
    wt.Teams,
    ws.Stables,
    wm.ManagerNames AS Managers,
    b.Belts,
    c.PlasterCaster_Gimmick AS Gimmick,
    CASE
        WHEN gr.RatingIdx = 0 THEN "Awful"
        WHEN gr.RatingIdx = 1 THEN "Poor"
        WHEN gr.RatingIdx = 2 THEN "Adequate"
        WHEN gr.RatingIdx = 3 THEN "Very Good"
        WHEN gr.RatingIdx = 4 THEN "Great"
        WHEN gr.RatingIdx = 5 THEN "Legendary"
        ELSE NULL
    END AS GimmickRating,
    gr.RatingIdx,

    -- Availability
    CASE
        WHEN i.UID THEN i.Name
        WHEN aw.Reason =  -1 THEN "Recovering from Overdose"
        WHEN aw.Reason =  -2 THEN "Filming"
        WHEN aw.Reason =  -3 THEN "In Prison"
        WHEN aw.Reason =  -4 THEN "In Rehab"
        WHEN aw.Reason =  -5 THEN "Suspended"
        WHEN aw.Reason =  -6 THEN "Missed Show"
        WHEN aw.Reason =  -7 THEN "On Vacation"
        WHEN aw.Reason =  -8 THEN "Touring with Band"
        WHEN aw.Reason =  -9 THEN "Maternity Leave"
        WHEN aw.Reason = -10 THEN "Engaged in MMA training"
        WHEN aw.Reason = -11 THEN "Sent Home"
        WHEN aw.Reason = -12 THEN "Legal Reasons"
        WHEN aw.Reason = -13 THEN "Personal Reasons"
        WHEN aw.Reason = -14 THEN "On Hiatus"
        WHEN aw.Reason = -15 THEN "In Politics"
        WHEN aw.Reason = -16 THEN "Given Night Off"
        WHEN aw.Reason = -17 THEN "Stranded"
        ELSE NULL
    END AS AbsenceReason,
    DATE(gi.CurrentGameDate, "+" || aw.DaysLeft || " days") AS ReturnDate,

    -- Misc
    fl.Initials AS Loyalty,
    w.DebutDate

FROM relevantWorkersAndContracts rwc
JOIN tblWorker w
ON rwc.WorkerUID = w.UID
LEFT JOIN tblContract c
ON rwc.ContractUID = c.UID
LEFT JOIN tblAway aw
ON aw.Worker = w.UID
LEFT JOIN companiesRank cr
ON c.FedUID = cr.UID
LEFT JOIN tblFed f
ON c.FedUID = f.UID
LEFT JOIN tblFedBrand fb
ON (fb.FedUID = f.UID AND c.Brand = fb.Brand)
JOIN roles r
ON r.WorkerUID = w.UID
LEFT JOIN belts b
ON w.UID = b.WorkerUID
LEFT JOIN workerTeams wt
ON w.UID = wt.UID
LEFT JOIN workerStables ws
ON w.UID = ws.UID
LEFT JOIN workerManagers wm
ON w.UID = wm.WorkerUID
JOIN tblWorkerSkill wsk
ON w.UID = wsk.WorkerUID
JOIN tblWorkerBusiness wb
ON w.UID = wb.WorkerUID
LEFT JOIN tblFed fl
ON w.Loyalty = fl.UID
JOIN workerPopularity wp
ON wp.UID = w.UID
CROSS JOIN tblGameInfo gi
LEFT JOIN tblInjury i
ON i.UID = aw.Reason
LEFT JOIN momentums m
ON m.UID = c.UID
LEFT JOIN gimmickRatings gr
ON gr.UID = c.UID

WHERE w.DebutDate <= gi.CurrentGameDate

ORDER BY cr.Rank ASC NULLS LAST, Name COLLATE NOCASE ASC
