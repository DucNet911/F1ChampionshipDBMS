-- 1. XÓA VÀ TẠO MỚI DATABASE (Để đảm bảo sạch sẽ nhất)
DROP DATABASE IF EXISTS F1_Championship_Management;
CREATE DATABASE F1_Championship_Management;
USE F1_Championship_Management;

-- 2. TẠO CẤU TRÚC BẢNG (Schema)
CREATE TABLE CHAMPIONSHIPS (
    champ_code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE TEAMS (
    team_code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    owner VARCHAR(100),
    description TEXT
);

CREATE TABLE DRIVERS (
    driver_code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    nationality VARCHAR(50),
    biography TEXT -- Added for spec
);

CREATE TABLE CONTRACTS (
    contract_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_code VARCHAR(10),
    team_code VARCHAR(10),
    is_active TINYINT DEFAULT 1,
    FOREIGN KEY (driver_code) REFERENCES DRIVERS(driver_code),
    FOREIGN KEY (team_code) REFERENCES TEAMS(team_code)
);

CREATE TABLE RACES (
    race_code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    num_laps INT NOT NULL,
    location VARCHAR(255),
    start_time DATETIME(3),
    champ_code VARCHAR(10),
    description TEXT, -- Added for spec
    FOREIGN KEY (champ_code) REFERENCES CHAMPIONSHIPS(champ_code)
);

CREATE TABLE RACE_ENTRIES (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    race_code VARCHAR(10),
    contract_id INT,
    FOREIGN KEY (race_code) REFERENCES RACES(race_code),
    FOREIGN KEY (contract_id) REFERENCES CONTRACTS(contract_id),
    UNIQUE(race_code, contract_id)
);

CREATE TABLE RESULTS (
    entry_id INT PRIMARY KEY,
    end_time DATETIME(3),
    laps_completed INT,
    status ENUM('Finished', 'DNF', 'Accident') DEFAULT 'Finished',
    points INT DEFAULT 0, -- Cột vật lý lưu điểm
    FOREIGN KEY (entry_id) REFERENCES RACE_ENTRIES(entry_id),
    CONSTRAINT chk_laps_completed CHECK (laps_completed >= 0),
    CONSTRAINT chk_points CHECK (points >= 0)
);

-- 3. CÀI ĐẶT TRIGGER (Chặn 2 tay đua/đội)
DELIMITER //
CREATE TRIGGER trg_limit_2_riders
BEFORE INSERT ON RACE_ENTRIES
FOR EACH ROW
BEGIN
    DECLARE v_team_id VARCHAR(10);
    DECLARE v_count INT;
    SELECT team_code INTO v_team_id FROM CONTRACTS WHERE contract_id = NEW.contract_id;
    SELECT COUNT(*) INTO v_count FROM RACE_ENTRIES re JOIN CONTRACTS c ON re.contract_id = c.contract_id
    WHERE re.race_code = NEW.race_code AND c.team_code = v_team_id;
    IF v_count >= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Mỗi đội chỉ được tối đa 2 tay đua tham gia mỗi chặng!';
    END IF;
END //
DELIMITER ;

-- Trigger B: Ràng buộc tính hợp lệ của thời gian (end_time > start_time)
DELIMITER //
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
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi CSDL: Thời gian kết thúc phải LỚN HƠN thời gian bắt đầu chặng!';
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
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi CSDL: Thời gian kết thúc phải LỚN HƠN thời gian bắt đầu chặng!';
        END IF;
    END IF;
END //
DELIMITER ;
-- 4. NẠP DỮ LIỆU MẪU (Sample Data)
INSERT INTO CHAMPIONSHIPS VALUES ('F1-2026', 'Formula 1 2026', 'The 2026 season');
INSERT INTO TEAMS VALUES ('RBR', 'Red Bull Racing', 'Red Bull', 'Christian Horner', 'Top Team');
INSERT INTO TEAMS VALUES ('FER', 'Scuderia Ferrari', 'Ferrari', 'Fred Vasseur', 'Iconic Team');
INSERT INTO TEAMS VALUES ('MER', 'Mercedes-AMG', 'Mercedes', 'Toto Wolff', 'Silver Arrows');
INSERT INTO TEAMS VALUES ('MCL', 'McLaren', 'McLaren', 'Zak Brown', 'Papaya Team');

INSERT INTO DRIVERS VALUES ('VER', 'Max Verstappen', '1997-09-30', 'Dutch', '');
INSERT INTO DRIVERS VALUES ('PER', 'Sergio Perez', '1990-01-26', 'Mexican', '');
INSERT INTO DRIVERS VALUES ('LAW', 'Liam Lawson', '2002-02-11', 'New Zealander', '');
INSERT INTO DRIVERS VALUES ('LEC', 'Charles Leclerc', '1997-10-16', 'Monegasque', '');
INSERT INTO DRIVERS VALUES ('SAI', 'Carlos Sainz', '1994-09-01', 'Spanish', '');
INSERT INTO DRIVERS VALUES ('BEA', 'Oliver Bearman', '2005-05-08', 'British', '');
INSERT INTO DRIVERS VALUES ('HAM', 'Lewis Hamilton', '1985-01-07', 'British', '');
INSERT INTO DRIVERS VALUES ('RUS', 'George Russell', '1998-02-15', 'British', '');
INSERT INTO DRIVERS VALUES ('ANT', 'Andrea Kimi Antonelli', '2006-08-25', 'Italian', '');
INSERT INTO DRIVERS VALUES ('NOR', 'Lando Norris', '1999-11-13', 'British', '');
INSERT INTO DRIVERS VALUES ('PIA', 'Oscar Piastri', '2001-04-06', 'Australian', '');
INSERT INTO DRIVERS VALUES ('OWA', 'Pato O Ward', '1999-05-06', 'Mexican', '');

INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('VER', 'RBR'), ('PER', 'RBR'), ('LAW', 'RBR');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('LEC', 'FER'), ('SAI', 'FER'), ('BEA', 'FER');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('HAM', 'MER'), ('RUS', 'MER'), ('ANT', 'MER');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('NOR', 'MCL'), ('PIA', 'MCL'), ('OWA', 'MCL');

INSERT INTO RACES VALUES ('BHR26', 'Bahrain GP', 57, 'Sakhir', '2026-03-05 15:00:00.000', 'F1-2026', 'Season Opener');
INSERT INTO RACES VALUES ('JED26', 'Saudi Arabian GP', 50, 'Jeddah', '2026-03-19 17:00:00.000', 'F1-2026', 'Night Race');
INSERT INTO RACES VALUES ('MONACO26', 'Monaco GP', 78, 'Monte Carlo', '2026-05-24 15:00:00.000', 'F1-2026', 'Jewel of the Crown');

-- ==============================================
-- (Bạn có thể truy cập UI và tự tay Đăng ký tay đua cho các chặng BHR26, JED26, MONACO26)

-- 5. CÀI ĐẶT STORED PROCEDURE LÕI (Tính điểm theo rank đua kèm TRANSACTION bảo hiểm)
DELIMITER //
CREATE PROCEDURE sp_calculate_points(IN p_race_code VARCHAR(10))
BEGIN
    -- Khai báo Handler: Gặp lỗi sẽ tự động ROLLBACK
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        RESIGNAL; -- Ném lỗi ra ngoài cho Backend nhận biết
    END;

    START TRANSACTION;
    
    -- Bước 1: Trả toàn bộ điểm của chặng này về 0 để tính lại từ đầu
    UPDATE RESULTS res
    JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
    SET res.points = 0
    WHERE re.race_code = p_race_code;
    
    -- Bước 2 & 3: Xếp hạng thời gian và UPDATE điểm vật lý ngược lại vào bảng RESULTS
    UPDATE RESULTS target
    JOIN (
        SELECT res.entry_id,
        RANK() OVER (ORDER BY TIMESTAMPDIFF(MICROSECOND, r.start_time, res.end_time) ASC) as pos
        FROM RESULTS res
        JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
        JOIN RACES r ON re.race_code = r.race_code
        WHERE re.race_code = p_race_code AND res.status = 'Finished'
    ) rnk ON target.entry_id = rnk.entry_id
    SET target.points = CASE 
        WHEN rnk.pos = 1 THEN 25 WHEN rnk.pos = 2 THEN 18
        WHEN rnk.pos = 3 THEN 15 WHEN rnk.pos = 4 THEN 12
        WHEN rnk.pos = 5 THEN 10 WHEN rnk.pos = 6 THEN 8
        WHEN rnk.pos = 7 THEN 6  WHEN rnk.pos = 8 THEN 4
        WHEN rnk.pos = 9 THEN 2  WHEN rnk.pos = 10 THEN 1
        ELSE 0 END;
        
    COMMIT;
END //
DELIMITER ;

-- 6. TẠO VIEW TỔNG HỢP (Views cho Bảng Xếp Hạng)
CREATE VIEW v_race_performance AS
SELECT re.race_code, c.driver_code, c.team_code, res.status, res.laps_completed, res.points,
TIMESTAMPDIFF(MICROSECOND, r.start_time, res.end_time) / 1000000 AS finish_time_seconds,
r.start_time AS race_start_time
FROM RESULTS res 
JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id 
JOIN RACES r ON re.race_code = r.race_code 
JOIN CONTRACTS c ON re.contract_id = c.contract_id;

-- Bảng ảo cộng dồn xếp hạng Driver (cung cấp data mỳ ăn liền không cần qua Backend tính)
CREATE VIEW v_driver_standings AS
SELECT 
    d.driver_code, d.name, d.nationality, t.name as team_name,
    SUM(v.points) AS total_score,
    SUM(CASE WHEN v.status = 'Finished' THEN v.finish_time_seconds ELSE 0 END) AS total_season_time
FROM DRIVERS d
JOIN CONTRACTS c ON d.driver_code = c.driver_code AND c.is_active = 1
JOIN TEAMS t ON c.team_code = t.team_code
JOIN v_race_performance v ON v.driver_code = d.driver_code AND v.team_code = t.team_code
GROUP BY d.driver_code, d.name, d.nationality, t.name
ORDER BY total_score DESC, total_season_time ASC;
-- Bảng ảo cộng dồn xếp hạng Đội Đua
CREATE VIEW v_team_standings AS
SELECT 
    t.team_code, t.name as team_name, t.brand,
    SUM(v.points) AS team_total_score,
    SUM(CASE WHEN v.status = 'Finished' THEN v.finish_time_seconds ELSE 0 END) AS team_total_time
FROM TEAMS t
JOIN CONTRACTS c ON t.team_code = c.team_code AND c.is_active = 1
JOIN v_race_performance v ON v.team_code = t.team_code AND v.driver_code = c.driver_code
GROUP BY t.team_code, t.name, t.brand
ORDER BY team_total_score DESC, team_total_time ASC;

-- 7. TẠO CHỈ MỤC (INDEXING) - Tăng tốc truy vấn Bảng Xếp Hạng do dữ liệu RESULTS lớn
CREATE INDEX idx_race_code ON RACE_ENTRIES(race_code);
CREATE INDEX idx_team_code_contracts ON CONTRACTS(team_code, driver_code);
CREATE INDEX idx_results_status_time ON RESULTS(status, end_time);
CREATE INDEX idx_races_start_time ON RACES(start_time);
