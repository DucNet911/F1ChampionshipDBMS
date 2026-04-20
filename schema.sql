-- ============================================================
-- F1 CHAMPIONSHIP MANAGEMENT SYSTEM — FULL SCHEMA + SEED DATA
-- Hỗ trợ nhiều mùa giải (CHAMPIONSHIPS)
-- ============================================================

DROP DATABASE IF EXISTS F1_Championship_Management;
CREATE DATABASE F1_Championship_Management;
USE F1_Championship_Management;

-- Tắt safe update mode (MySQL Workbench bật mặc định, chặn UPDATE không dùng KEY column)
SET SQL_SAFE_UPDATES = 0;


-- ============================================================
-- 1. CẤU TRÚC BẢNG (DDL)
-- ============================================================
CREATE TABLE CHAMPIONSHIPS (
    champ_code  VARCHAR(10)  PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE TEAMS (
    team_code   VARCHAR(10)  PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    brand       VARCHAR(100),
    owner       VARCHAR(100),
    description TEXT
);

CREATE TABLE DRIVERS (
    driver_code   VARCHAR(10)  PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    nationality   VARCHAR(50),
    biography     TEXT
);

CREATE TABLE CONTRACTS (
    contract_id INT          AUTO_INCREMENT PRIMARY KEY,
    driver_code VARCHAR(10),
    team_code   VARCHAR(10),
    is_active   TINYINT      DEFAULT 1,
    FOREIGN KEY (driver_code) REFERENCES DRIVERS(driver_code),
    FOREIGN KEY (team_code)   REFERENCES TEAMS(team_code)
);

CREATE TABLE RACES (
    race_code   VARCHAR(10)  PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    num_laps    INT          NOT NULL,
    location    VARCHAR(255),
    start_time  DATETIME(3),
    champ_code  VARCHAR(10),
    description TEXT,
    FOREIGN KEY (champ_code) REFERENCES CHAMPIONSHIPS(champ_code)
);

CREATE TABLE RACE_ENTRIES (
    entry_id    INT AUTO_INCREMENT PRIMARY KEY,
    race_code   VARCHAR(10),
    contract_id INT,
    FOREIGN KEY (race_code)   REFERENCES RACES(race_code),
    FOREIGN KEY (contract_id) REFERENCES CONTRACTS(contract_id),
    UNIQUE(race_code, contract_id)
);

CREATE TABLE RESULTS (
    entry_id       INT PRIMARY KEY,
    end_time       DATETIME(3),
    laps_completed INT,
    status         ENUM('Finished', 'DNF', 'Accident') DEFAULT 'Finished',
    points         INT DEFAULT 0,
    FOREIGN KEY (entry_id) REFERENCES RACE_ENTRIES(entry_id),
    CONSTRAINT chk_laps_completed CHECK (laps_completed >= 0),
    CONSTRAINT chk_points         CHECK (points >= 0)
);

-- ============================================================
-- 2. TRIGGER
-- ============================================================
DELIMITER //
CREATE TRIGGER trg_limit_2_riders
BEFORE INSERT ON RACE_ENTRIES
FOR EACH ROW
BEGIN
    DECLARE v_team_id VARCHAR(10);
    DECLARE v_count INT;
    SELECT team_code INTO v_team_id FROM CONTRACTS WHERE contract_id = NEW.contract_id;
    SELECT COUNT(*) INTO v_count FROM RACE_ENTRIES re
    JOIN CONTRACTS c ON re.contract_id = c.contract_id
    WHERE re.race_code = NEW.race_code AND c.team_code = v_team_id;
    IF v_count >= 2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Mỗi đội chỉ được tối đa 2 tay đua tham gia mỗi chặng!';
    END IF;
END //

CREATE TRIGGER trg_check_time_insert
BEFORE INSERT ON RESULTS
FOR EACH ROW
BEGIN
    DECLARE v_start_time DATETIME(3);
    IF NEW.status = 'Finished' AND NEW.end_time IS NOT NULL THEN
        SELECT r.start_time INTO v_start_time
        FROM RACE_ENTRIES re JOIN RACES r ON re.race_code = r.race_code
        WHERE re.entry_id = NEW.entry_id;
        IF NEW.end_time <= v_start_time THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi CSDL: Thời gian kết thúc phải LỚN HƠN thời gian bắt đầu chặng!';
        END IF;
    END IF;
END //

CREATE TRIGGER trg_check_time_update
BEFORE UPDATE ON RESULTS
FOR EACH ROW
BEGIN
    DECLARE v_start_time DATETIME(3);
    IF NEW.status = 'Finished' AND NEW.end_time IS NOT NULL THEN
        SELECT r.start_time INTO v_start_time
        FROM RACE_ENTRIES re JOIN RACES r ON re.race_code = r.race_code
        WHERE re.entry_id = NEW.entry_id;
        IF NEW.end_time <= v_start_time THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi CSDL: Thời gian kết thúc phải LỚN HƠN thời gian bắt đầu chặng!';
        END IF;
    END IF;
END //
DELIMITER ;

-- ============================================================
-- 3. STORED PROCEDURE
-- ============================================================
DELIMITER //
CREATE PROCEDURE sp_calculate_points(IN p_race_code VARCHAR(10))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE RESULTS res
    JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
    SET res.points = 0
    WHERE re.race_code = p_race_code;

    UPDATE RESULTS target
    JOIN (
        SELECT res.entry_id,
        RANK() OVER (ORDER BY TIMESTAMPDIFF(MICROSECOND, r.start_time, res.end_time) ASC) AS pos
        FROM RESULTS res
        JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
        JOIN RACES r ON re.race_code = r.race_code
        WHERE re.race_code = p_race_code AND res.status = 'Finished'
    ) rnk ON target.entry_id = rnk.entry_id
    SET target.points = CASE
        WHEN rnk.pos = 1  THEN 25  WHEN rnk.pos = 2  THEN 18
        WHEN rnk.pos = 3  THEN 15  WHEN rnk.pos = 4  THEN 12
        WHEN rnk.pos = 5  THEN 10  WHEN rnk.pos = 6  THEN 8
        WHEN rnk.pos = 7  THEN 6   WHEN rnk.pos = 8  THEN 4
        WHEN rnk.pos = 9  THEN 2   WHEN rnk.pos = 10 THEN 1
        ELSE 0
    END;

    COMMIT;
END //
DELIMITER ;

-- ============================================================
-- 4. VIEWS
-- ============================================================
CREATE VIEW v_race_performance AS
SELECT re.race_code, c.driver_code, c.team_code, res.status,
       res.laps_completed, res.points,
       TIMESTAMPDIFF(MICROSECOND, r.start_time, res.end_time) / 1000000 AS finish_time_seconds,
       r.start_time AS race_start_time,
       r.champ_code
FROM RESULTS res
JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
JOIN RACES r ON re.race_code = r.race_code
JOIN CONTRACTS c ON re.contract_id = c.contract_id;

CREATE VIEW v_driver_standings AS
SELECT
    d.driver_code, d.name, d.nationality, t.name AS team_name,
    SUM(v.points) AS total_score,
    SUM(CASE WHEN v.status = 'Finished' THEN v.finish_time_seconds ELSE 0 END) AS total_season_time
FROM DRIVERS d
JOIN CONTRACTS c ON d.driver_code = c.driver_code AND c.is_active = 1
JOIN TEAMS t ON c.team_code = t.team_code
JOIN v_race_performance v ON v.driver_code = d.driver_code AND v.team_code = t.team_code
GROUP BY d.driver_code, d.name, d.nationality, t.name
ORDER BY total_score DESC, total_season_time ASC;

CREATE VIEW v_team_standings AS
SELECT
    t.team_code, t.name AS team_name, t.brand,
    SUM(v.points) AS team_total_score,
    SUM(CASE WHEN v.status = 'Finished' THEN v.finish_time_seconds ELSE 0 END) AS team_total_time
FROM TEAMS t
JOIN CONTRACTS c ON t.team_code = c.team_code AND c.is_active = 1
JOIN v_race_performance v ON v.team_code = t.team_code AND v.driver_code = c.driver_code
GROUP BY t.team_code, t.name, t.brand
ORDER BY team_total_score DESC, team_total_time ASC;

-- ============================================================
-- 5. INDEX
-- ============================================================
CREATE INDEX idx_race_code          ON RACE_ENTRIES(race_code);
CREATE INDEX idx_team_code_contracts ON CONTRACTS(team_code, driver_code);
CREATE INDEX idx_results_status_time ON RESULTS(status, end_time);
CREATE INDEX idx_races_start_time    ON RACES(start_time);
CREATE INDEX idx_races_champ_code    ON RACES(champ_code);

-- ============================================================
-- 6. DỮ LIỆU MẪU — MASTER DATA
-- ============================================================

-- Mùa giải
INSERT INTO CHAMPIONSHIPS VALUES
    ('F1-2025', 'Formula 1 Season 2025', 'Mùa giải F1 2025 — McLaren thống trị'),
    ('F1-2026', 'Formula 1 Season 2026', 'Mùa giải F1 2026 — Kỷ nguyên xe hybrid mới');

-- Đội đua (dùng chung cả 2 mùa)
INSERT INTO TEAMS VALUES
    ('RBR', 'Red Bull Racing',   'Red Bull',  'Christian Horner', 'Đội đua xuất sắc nhất thập kỷ'),
    ('FER', 'Scuderia Ferrari',  'Ferrari',   'Fred Vasseur',     'Đội đua lâu đời nhất F1'),
    ('MER', 'Mercedes-AMG',     'Mercedes',  'Toto Wolff',       'Silver Arrows huyền thoại'),
    ('MCL', 'McLaren',           'McLaren',   'Zak Brown',        'Papaya Power'),
    ('ALP', 'Alpine F1 Team',    'Renault',   'Oliver Oakes',     'Đội đua của Pháp'),
    ('AST', 'Aston Martin',      'Mercedes',  'Lawrence Stroll',  'Đội đua xanh lá');

-- Tay đua (18 tay đua — 3 tay đua mỗi đội)
INSERT INTO DRIVERS VALUES
    ('VER', 'Max Verstappen',        '1997-09-30', 'Dutch',       '4x World Champion, số 1 thập kỷ'),
    ('NOR', 'Lando Norris',          '1999-11-13', 'British',     'McLaren số 1 — đang ở đỉnh phong độ'),
    ('PIA', 'Oscar Piastri',         '2001-04-06', 'Australian',  'Tài năng trẻ xuất sắc của McLaren'),
    ('LEC', 'Charles Leclerc',       '1997-10-16', 'Monegasque',  'Biểu tượng Ferrari — quê hương Monaco'),
    ('SAI', 'Carlos Sainz',          '1994-09-01', 'Spanish',     'Il Matador — chắc chắn, nhất quán'),
    ('HAM', 'Lewis Hamilton',        '1985-01-07', 'British',     '7x World Champion — huyền thoại F1'),
    ('RUS', 'George Russell',        '1998-02-15', 'British',     'Mr. Saturday — xuất sắc trong qualifying'),
    ('ALO', 'Fernando Alonso',       '1981-07-29', 'Spanish',     '2x World Champion — vẫn thi đấu ở tuổi 44'),
    ('STR', 'Lance Stroll',          '1998-10-29', 'Canadian',    'Con trai ông chủ Aston Martin'),
    ('GAS', 'Pierre Gasly',          '1996-02-07', 'French',      'Cựu tay đua Red Bull — trụ cột Alpine'),
    ('PER', 'Sergio Perez',          '1990-01-26', 'Mexican',     'Checo — Wing man hoàn hảo của Verstappen'),
    ('BEA', 'Oliver Bearman',        '2005-05-08', 'British',     'Tài năng trẻ người Anh — tương lai F1'),
    ('LAW', 'Liam Lawson',           '2002-02-11', 'New Zealander','Người thay thế Perez tại Red Bull 2026'),
    ('OWA', 'Pato O''Ward',          '1999-05-06', 'Mexican',     'Ngôi sao IndyCar chuyển sang F1 cùng Alpine'),
    -- Tay đua reserve / 3rd driver của các đội
    ('ANT', 'Kimi Antonelli',        '2006-08-25', 'Italian',     'Người kế thừa Hamilton tại Mercedes 2025'),
    ('ZHO', 'Zhou Guanyu',           '1999-05-30', 'Chinese',     'Tay đua người Trung Quốc — reserve McLaren'),
    ('DEV', 'Jack Doohan',           '2003-01-05', 'Australian',  'Học viên Alpine — reserve Alpine 2026'),
    ('HUL', 'Nico Hulkenberg',       '1987-08-19', 'German',      'Tay đua kỳ cựu — reserve Aston Martin');


-- ============================================================
-- HỢP ĐỒNG MÙA 2025 (is_active = 0 vì đã kết thúc)
-- ============================================================
INSERT INTO CONTRACTS (driver_code, team_code, is_active) VALUES
    -- Red Bull
    ('VER', 'RBR', 0), ('PER', 'RBR', 0),
    -- Ferrari
    ('LEC', 'FER', 0), ('SAI', 'FER', 0),
    -- Mercedes
    ('HAM', 'MER', 0), ('RUS', 'MER', 0),
    -- McLaren
    ('NOR', 'MCL', 0), ('PIA', 'MCL', 0),
    -- Alpine
    ('GAS', 'ALP', 0),
    -- Aston Martin
    ('ALO', 'AST', 0), ('STR', 'AST', 0);

-- HỢP ĐỒNG MÙA 2026 (is_active = 1 — đang hiệu lực)
-- Mỗi đội có đúng 3 tay đua — chọn 2 trong 3 khi đăng ký chặng
-- contract_id bắt đầu từ 12 (sau 11 contract 2025):
--   12:VER/RBR  13:LAW/RBR  14:PER/RBR  (reserve)
--   15:HAM/FER  16:LEC/FER  17:SAI/FER  (reserve)
--   18:RUS/MER  19:BEA/MER  20:ANT/MER  (reserve)
--   21:NOR/MCL  22:PIA/MCL  23:ZHO/MCL  (reserve)
--   24:GAS/ALP  25:OWA/ALP  26:DEV/ALP  (reserve)
--   27:ALO/AST  28:STR/AST  29:HUL/AST  (reserve)
INSERT INTO CONTRACTS (driver_code, team_code, is_active) VALUES
    -- 🔴 Red Bull Racing (3/3): VER + LAW chính thức, PER reserve
    ('VER', 'RBR', 1), ('LAW', 'RBR', 1), ('PER', 'RBR', 1),
    -- 🔴 Scuderia Ferrari (3/3): HAM + LEC chính thức, SAI reserve
    ('HAM', 'FER', 1), ('LEC', 'FER', 1), ('SAI', 'FER', 1),
    -- ⚫ Mercedes-AMG (3/3): RUS + BEA chính thức, ANT reserve
    ('RUS', 'MER', 1), ('BEA', 'MER', 1), ('ANT', 'MER', 1),
    -- 🟠 McLaren (3/3): NOR + PIA chính thức, ZHO reserve
    ('NOR', 'MCL', 1), ('PIA', 'MCL', 1), ('ZHO', 'MCL', 1),
    -- 🔵 Alpine F1 (3/3): GAS + OWA chính thức, DEV reserve
    ('GAS', 'ALP', 1), ('OWA', 'ALP', 1), ('DEV', 'ALP', 1),
    -- 🟢 Aston Martin (3/3): ALO + STR chính thức, HUL reserve
    ('ALO', 'AST', 1), ('STR', 'AST', 1), ('HUL', 'AST', 1);


-- ============================================================
-- CHẶNG ĐUA MÙA 2025
-- ============================================================
INSERT INTO RACES VALUES
    ('BHR25',    'Bahrain Grand Prix',      57, 'Sakhir, Bahrain',     '2025-03-02 15:00:00.000', 'F1-2025', 'Season Opener 2025'),
    ('JED25',    'Saudi Arabian Grand Prix',50, 'Jeddah, Saudi Arabia','2025-03-16 17:00:00.000', 'F1-2025', 'Night Race'),
    ('AUS25',    'Australian Grand Prix',   58, 'Melbourne, Australia','2025-03-30 15:00:00.000', 'F1-2025', 'Albert Park Circuit'),
    ('JAP25',    'Japanese Grand Prix',     53, 'Suzuka, Japan',       '2025-04-06 14:00:00.000', 'F1-2025', 'Suzuka Classic'),
    ('CHN25',    'Chinese Grand Prix',      56, 'Shanghai, China',     '2025-04-20 08:00:00.000', 'F1-2025', 'Shanghai International'),
    ('MIA25',    'Miami Grand Prix',        57, 'Miami, USA',          '2025-05-04 20:00:00.000', 'F1-2025', 'Hard Rock Stadium'),
    ('MONACO25', 'Monaco Grand Prix',       78, 'Monte Carlo, Monaco', '2025-05-25 15:00:00.000', 'F1-2025', 'Jewel of the Crown'),
    ('SPA25',    'Spanish Grand Prix',      66, 'Barcelona, Spain',    '2025-06-01 15:00:00.000', 'F1-2025', 'Circuit de Catalunya');

-- CHẶNG ĐUA MÙA 2026
INSERT INTO RACES VALUES
    ('BHR26',    'Bahrain Grand Prix',      57, 'Sakhir, Bahrain',     '2026-03-05 15:00:00.000', 'F1-2026', 'Season Opener 2026'),
    ('JED26',    'Saudi Arabian Grand Prix',50, 'Jeddah, Saudi Arabia','2026-03-19 17:00:00.000', 'F1-2026', 'Night Race 2026'),
    ('AUS26',    'Australian Grand Prix',   58, 'Melbourne, Australia','2026-04-06 15:00:00.000', 'F1-2026', 'Albert Park'),
    ('MONACO26', 'Monaco Grand Prix',       78, 'Monte Carlo, Monaco', '2026-05-24 15:00:00.000', 'F1-2026', 'Jewel of the Crown 2026'),
    ('SPA26',    'Spanish Grand Prix',      66, 'Barcelona, Spain',    '2026-06-07 15:00:00.000', 'F1-2026', 'Circuit de Catalunya');

-- ============================================================
-- ĐĂNG KÝ TẤT CẢ CHẶNG MÙA 2025
-- Contracts 2025: VER=1 PER=2 LEC=3 SAI=4 HAM=5 RUS=6 NOR=7 PIA=8 GAS=9 ALO=10 STR=11
-- 11 tay đua × 8 chặng = 88 entries (IDs 1-88)
-- Mỗi chặng: VER(1) PER(2) LEC(3) SAI(4) HAM(5) RUS(6) NOR(7) PIA(8) GAS(9) ALO(10) STR(11)
-- ============================================================
INSERT INTO RACE_ENTRIES (race_code, contract_id) VALUES
    ('BHR25',1),('BHR25',2),('BHR25',3),('BHR25',4),('BHR25',5),('BHR25',6),('BHR25',7),('BHR25',8),('BHR25',9),('BHR25',10),('BHR25',11),
    ('JED25',1),('JED25',2),('JED25',3),('JED25',4),('JED25',5),('JED25',6),('JED25',7),('JED25',8),('JED25',9),('JED25',10),('JED25',11),
    ('AUS25',1),('AUS25',2),('AUS25',3),('AUS25',4),('AUS25',5),('AUS25',6),('AUS25',7),('AUS25',8),('AUS25',9),('AUS25',10),('AUS25',11),
    ('JAP25',1),('JAP25',2),('JAP25',3),('JAP25',4),('JAP25',5),('JAP25',6),('JAP25',7),('JAP25',8),('JAP25',9),('JAP25',10),('JAP25',11),
    ('CHN25',1),('CHN25',2),('CHN25',3),('CHN25',4),('CHN25',5),('CHN25',6),('CHN25',7),('CHN25',8),('CHN25',9),('CHN25',10),('CHN25',11),
    ('MIA25',1),('MIA25',2),('MIA25',3),('MIA25',4),('MIA25',5),('MIA25',6),('MIA25',7),('MIA25',8),('MIA25',9),('MIA25',10),('MIA25',11),
    ('MONACO25',1),('MONACO25',2),('MONACO25',3),('MONACO25',4),('MONACO25',5),('MONACO25',6),('MONACO25',7),('MONACO25',8),('MONACO25',9),('MONACO25',10),('MONACO25',11),
    ('SPA25',1),('SPA25',2),('SPA25',3),('SPA25',4),('SPA25',5),('SPA25',6),('SPA25',7),('SPA25',8),('SPA25',9),('SPA25',10),('SPA25',11);

-- ============================================================
-- KẾT QUẢ MÙA 2025 (88 entries)
-- BHR25: entry  1-11  | JED25:    12-22 | AUS25:    23-33 | JAP25: 34-44
-- CHN25: entry 45-55  | MIA25:    56-66 | MONACO25: 67-77 | SPA25: 78-88
-- Thứ tự mỗi race: VER PER LEC SAI HAM RUS NOR PIA GAS ALO STR
-- NOR vô địch 2025 với 169 điểm
-- ============================================================

-- BHR25: NOR P1, PIA P2, VER P3, LEC P4, HAM P5, RUS P6, SAI P7, ALO P8, STR P9 | GAS ACC, PER DNF
INSERT INTO RESULTS VALUES
( 1, '2025-03-02 16:37:12.000', 57, 'Finished', 0), -- VER → P3
( 2, NULL,                       12, 'DNF',       0), -- PER
( 3, '2025-03-02 16:37:28.000', 57, 'Finished', 0), -- LEC → P4
( 4, '2025-03-02 16:38:02.000', 57, 'Finished', 0), -- SAI → P7
( 5, '2025-03-02 16:37:45.000', 57, 'Finished', 0), -- HAM → P5
( 6, '2025-03-02 16:37:58.000', 57, 'Finished', 0), -- RUS → P6
( 7, '2025-03-02 16:36:45.000', 57, 'Finished', 0), -- NOR → P1
( 8, '2025-03-02 16:36:58.000', 57, 'Finished', 0), -- PIA → P2
( 9, NULL,                       44, 'Accident',  0), -- GAS
(10, '2025-03-02 16:38:18.000', 57, 'Finished', 0), -- ALO → P8
(11, '2025-03-02 16:38:35.000', 57, 'Finished', 0); -- STR → P9

-- JED25: VER P1, HAM P2, NOR P3, LEC P4, PIA P5, RUS P6, SAI P7, ALO P8, STR P9 | GAS ACC, PER DNF
INSERT INTO RESULTS VALUES
(12, '2025-03-16 18:30:22.000', 50, 'Finished', 0), -- VER → P1
(13, NULL,                       18, 'DNF',       0), -- PER
(14, '2025-03-16 18:31:12.000', 50, 'Finished', 0), -- LEC → P4
(15, '2025-03-16 18:32:02.000', 50, 'Finished', 0), -- SAI → P7
(16, '2025-03-16 18:30:38.000', 50, 'Finished', 0), -- HAM → P2
(17, '2025-03-16 18:31:45.000', 50, 'Finished', 0), -- RUS → P6
(18, '2025-03-16 18:30:55.000', 50, 'Finished', 0), -- NOR → P3
(19, '2025-03-16 18:31:28.000', 50, 'Finished', 0), -- PIA → P5
(20, NULL,                       30, 'Accident',  0), -- GAS
(21, '2025-03-16 18:32:18.000', 50, 'Finished', 0), -- ALO → P8
(22, '2025-03-16 18:32:35.000', 50, 'Finished', 0); -- STR → P9

-- AUS25: PIA P1, NOR P2, VER P3, LEC P4, HAM P5, SAI P6, RUS P7, ALO P8, GAS P9 | STR DNF, PER ACC
INSERT INTO RESULTS VALUES
(23, '2025-03-30 16:27:48.000', 58, 'Finished', 0), -- VER → P3
(24, NULL,                       12, 'Accident',  0), -- PER
(25, '2025-03-30 16:28:05.000', 58, 'Finished', 0), -- LEC → P4
(26, '2025-03-30 16:28:38.000', 58, 'Finished', 0), -- SAI → P6
(27, '2025-03-30 16:28:22.000', 58, 'Finished', 0), -- HAM → P5
(28, '2025-03-30 16:28:55.000', 58, 'Finished', 0), -- RUS → P7
(29, '2025-03-30 16:27:32.000', 58, 'Finished', 0), -- NOR → P2
(30, '2025-03-30 16:27:15.000', 58, 'Finished', 0), -- PIA → P1
(31, '2025-03-30 16:29:28.000', 58, 'Finished', 0), -- GAS → P9
(32, '2025-03-30 16:29:12.000', 58, 'Finished', 0), -- ALO → P8
(33, NULL,                       25, 'DNF',       0); -- STR

-- JAP25: VER P1, NOR P2, PIA P3, HAM P4, LEC P5, RUS P6, SAI P7, ALO P8, GAS P9 | STR DNF, PER ACC
INSERT INTO RESULTS VALUES
(34, '2025-04-06 15:22:33.000', 53, 'Finished', 0), -- VER → P1
(35, NULL,                        0, 'Accident',  0), -- PER
(36, '2025-04-06 15:23:40.000', 53, 'Finished', 0), -- LEC → P5
(37, '2025-04-06 15:24:13.000', 53, 'Finished', 0), -- SAI → P7
(38, '2025-04-06 15:23:23.000', 53, 'Finished', 0), -- HAM → P4
(39, '2025-04-06 15:23:57.000', 53, 'Finished', 0), -- RUS → P6
(40, '2025-04-06 15:22:50.000', 53, 'Finished', 0), -- NOR → P2
(41, '2025-04-06 15:23:07.000', 53, 'Finished', 0), -- PIA → P3
(42, '2025-04-06 15:24:47.000', 53, 'Finished', 0), -- GAS → P9
(43, '2025-04-06 15:24:30.000', 53, 'Finished', 0), -- ALO → P8
(44, NULL,                       28, 'DNF',       0); -- STR

-- CHN25: NOR P1, PIA P2, VER P3, LEC P4, SAI P5, HAM P6, RUS P7, ALO P8, STR P9 | GAS DNF, PER ACC
INSERT INTO RESULTS VALUES
(45, '2025-04-20 09:33:14.000', 56, 'Finished', 0), -- VER → P3
(46, NULL,                        0, 'Accident',  0), -- PER
(47, '2025-04-20 09:33:31.000', 56, 'Finished', 0), -- LEC → P4
(48, '2025-04-20 09:33:48.000', 56, 'Finished', 0), -- SAI → P5
(49, '2025-04-20 09:34:04.000', 56, 'Finished', 0), -- HAM → P6
(50, '2025-04-20 09:34:21.000', 56, 'Finished', 0), -- RUS → P7
(51, '2025-04-20 09:32:41.000', 56, 'Finished', 0), -- NOR → P1
(52, '2025-04-20 09:32:58.000', 56, 'Finished', 0), -- PIA → P2
(53, NULL,                       11, 'DNF',       0), -- GAS
(54, '2025-04-20 09:34:37.000', 56, 'Finished', 0), -- ALO → P8
(55, '2025-04-20 09:34:54.000', 56, 'Finished', 0); -- STR → P9

-- MIA25: NOR P1, PIA P2, HAM P3, LEC P4, VER P5, RUS P6, SAI P7, ALO P8, GAS P9, STR P10 | PER DNF
INSERT INTO RESULTS VALUES
(56, '2025-05-04 21:33:07.000', 57, 'Finished', 0), -- VER → P5
(57, NULL,                       22, 'DNF',       0), -- PER
(58, '2025-05-04 21:32:50.000', 57, 'Finished', 0), -- LEC → P4
(59, '2025-05-04 21:33:40.000', 57, 'Finished', 0), -- SAI → P7
(60, '2025-05-04 21:32:33.000', 57, 'Finished', 0), -- HAM → P3
(61, '2025-05-04 21:33:23.000', 57, 'Finished', 0), -- RUS → P6
(62, '2025-05-04 21:32:00.000', 57, 'Finished', 0), -- NOR → P1
(63, '2025-05-04 21:32:17.000', 57, 'Finished', 0), -- PIA → P2
(64, '2025-05-04 21:34:30.000', 57, 'Finished', 0), -- GAS → P9
(65, '2025-05-04 21:33:57.000', 57, 'Finished', 0), -- ALO → P8
(66, '2025-05-04 21:34:13.000', 57, 'Finished', 0); -- STR → P10

-- MONACO25: LEC P1, NOR P2, VER P3, PIA P4, HAM P5, RUS P6, SAI P7, ALO P8, GAS P9 | STR DNF, PER DNF
INSERT INTO RESULTS VALUES
(67, '2025-05-25 16:47:03.000', 78, 'Finished', 0), -- VER → P3
(68, NULL,                       22, 'DNF',       0), -- PER
(69, '2025-05-25 16:46:30.000', 78, 'Finished', 0), -- LEC → P1
(70, '2025-05-25 16:48:10.000', 78, 'Finished', 0), -- SAI → P7
(71, '2025-05-25 16:47:37.000', 78, 'Finished', 0), -- HAM → P5
(72, '2025-05-25 16:47:53.000', 78, 'Finished', 0), -- RUS → P6
(73, '2025-05-25 16:46:47.000', 78, 'Finished', 0), -- NOR → P2
(74, '2025-05-25 16:47:20.000', 78, 'Finished', 0), -- PIA → P4
(75, '2025-05-25 16:48:43.000', 78, 'Finished', 0), -- GAS → P9
(76, '2025-05-25 16:48:27.000', 78, 'Finished', 0), -- ALO → P8
(77, NULL,                       35, 'DNF',       0); -- STR

-- SPA25: NOR P1, VER P2, PIA P3, LEC P4, HAM P5, RUS P6, SAI P7, ALO P8, GAS P9 | STR DNF, PER ACC
INSERT INTO RESULTS VALUES
(78, '2025-06-01 16:34:50.000', 66, 'Finished', 0), -- VER → P2
(79, NULL,                        8, 'Accident',  0), -- PER
(80, '2025-06-01 16:35:23.000', 66, 'Finished', 0), -- LEC → P4
(81, '2025-06-01 16:36:13.000', 66, 'Finished', 0), -- SAI → P7
(82, '2025-06-01 16:35:40.000', 66, 'Finished', 0), -- HAM → P5
(83, '2025-06-01 16:35:57.000', 66, 'Finished', 0), -- RUS → P6
(84, '2025-06-01 16:34:33.000', 66, 'Finished', 0), -- NOR → P1
(85, '2025-06-01 16:35:07.000', 66, 'Finished', 0), -- PIA → P3
(86, '2025-06-01 16:36:47.000', 66, 'Finished', 0), -- GAS → P9
(87, '2025-06-01 16:36:30.000', 66, 'Finished', 0), -- ALO → P8
(88, NULL,                       40, 'DNF',       0); -- STR

-- Tính điểm toàn bộ mùa 2025
CALL sp_calculate_points('BHR25');
CALL sp_calculate_points('JED25');
CALL sp_calculate_points('AUS25');
CALL sp_calculate_points('JAP25');
CALL sp_calculate_points('CHN25');
CALL sp_calculate_points('MIA25');
CALL sp_calculate_points('MONACO25');
CALL sp_calculate_points('SPA25');

-- ============================================================
-- MÙA GIẢI 2026 — ĐỂ TRỐNG HOÀN TOÀN CHO DEMO
-- ✅ Có sẵn: 5 chặng đua + hợp đồng 18 tay đua (3/đội × 6 đội)
-- ❌ Chưa có: RACE_ENTRIES và RESULTS (demo trực tiếp trên UI)
-- 
-- HƯỚNG DẪN DEMO:
--   Bước 1: Register Team → chọn mùa F1-2026 → chọn chặng → chọn đội
--            → tick 2 trong 3 tay đua → nhấn "Sync Registration"
--   Bước 2: Update Results → chọn chặng → nhập thời gian/vòng/trạng thái
--            → nhấn "Save All Results" → điểm tự động tính
--   Bước 3: Driver/Team Standings → xem bảng xếp hạng cập nhật
--
-- 3 ĐỘI GỢI Ý DEMO (chưa có data, dễ biểu diễn):
--   🔴 Red Bull   : VER(12) + LAW(13) + PER(14-reserve)
--   🔵 Alpine     : GAS(24) + OWA(25) + DEV(26-reserve)  
--   🟢 Aston Martin: ALO(27) + STR(28) + HUL(29-reserve)
-- ============================================================
