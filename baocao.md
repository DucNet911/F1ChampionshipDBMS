# BÁO CÁO HỌC PHẦN
# DATABASE MANAGEMENT SYSTEMS (DBMS)

---

**Đề tài:** F1 Championship Management System  
**Hệ DBMS sử dụng:** MySQL 8.0 / MariaDB 10.6  
**Công nghệ:** Node.js · Express · React · mysql2  
**Học phần:** Hệ Quản Trị Cơ Sở Dữ Liệu  

---

## MỤC LỤC

1. Giới thiệu
2. Cơ sở lý thuyết
3. Mô tả bài toán và phân tích yêu cầu
4. Nghiệp vụ logic (Business Logic)
5. Thiết kế cơ sở dữ liệu
6. Triển khai
7. Đánh giá và thảo luận
8. Kết luận

---

## CHƯƠNG 1 — GIỚI THIỆU

### 1.1 Tổng quan về DBMS

Hệ Quản Trị Cơ Sở Dữ Liệu (Database Management System — DBMS) là phần mềm trung gian đứng giữa người dùng/ứng dụng và dữ liệu được lưu trữ vật lý, cung cấp các cơ chế để định nghĩa, tạo lập, duy trì và kiểm soát truy cập đến cơ sở dữ liệu. Thay vì mỗi ứng dụng tự quản lý file riêng lẻ — dẫn đến trùng lặp dữ liệu, không nhất quán và khó bảo trì — DBMS cung cấp một kho dữ liệu tập trung, nhất quán và có thể truy cập đồng thời bởi nhiều người dùng.

Các DBMS hiện đại như MySQL, PostgreSQL, Oracle, SQL Server đều xây dựng trên nền tảng mô hình quan hệ (Relational Model) được Edgar F. Codd đề xuất năm 1970. Trong mô hình này, dữ liệu được tổ chức thành các bảng (table) gồm nhiều hàng (row) và cột (column), các bảng liên kết với nhau qua khóa ngoại (foreign key), và ngôn ngữ SQL (Structured Query Language) được dùng để thao tác dữ liệu một cách khai báo (declarative) — nghĩa là chỉ cần nói *muốn lấy gì* mà không cần nói *lấy như thế nào*.

### 1.2 Vai trò của DBMS trong hệ thống thông tin

Trong kiến trúc hệ thống thông tin hiện đại, DBMS đóng vai trò là lớp nền tảng không thể thiếu:

- **Tính toàn vẹn dữ liệu (Data Integrity):** DBMS tự động kiểm tra và đảm bảo dữ liệu luôn hợp lệ thông qua các ràng buộc (constraints), trigger và transaction — không phụ thuộc vào việc ứng dụng nào truy cập.
- **Tính nhất quán (Consistency):** Nhiều người dùng truy cập đồng thời nhưng mỗi người đều nhìn thấy trạng thái nhất quán của dữ liệu, nhờ cơ chế ACID transaction và MVCC (Multi-Version Concurrency Control).
- **Tính bảo mật (Security):** DBMS cung cấp hệ thống phân quyền chi tiết — mỗi user chỉ truy cập được những gì được cho phép.
- **Tính hiệu năng (Performance):** Index, query optimizer và caching giúp truy xuất dữ liệu nhanh ngay cả khi bảng có hàng triệu dòng.
- **Tính bền vững (Durability):** Dữ liệu được đảm bảo không bị mất sau khi commit, kể cả khi server gặp sự cố đột ngột.

### 1.3 Giới thiệu bài toán — F1 Championship Management System

Formula 1 (F1) là giải đua xe thể thức một hàng đầu thế giới, với hàng chục đội đua, hơn 20 tay đua chuyên nghiệp và lịch thi đấu kéo dài gần một năm. Mỗi mùa giải gồm nhiều chặng đua (Grand Prix) tại các quốc gia khác nhau. Kết quả mỗi chặng được tổng hợp theo hệ thống tính điểm chuẩn quốc tế để xếp hạng tay đua và đội đua vào cuối mùa.

**F1 Championship Management System** là hệ thống phần mềm quản lý toàn bộ vòng đời dữ liệu của một mùa giải F1:

- Quản lý thông tin đội đua, tay đua, hợp đồng ký kết
- Quản lý lịch thi đấu và các chặng đua
- Cho phép đăng ký tay đua vào từng chặng đua
- Ghi nhận kết quả thi đấu sau mỗi chặng
- Tự động tính điểm theo hệ thống tính điểm F1 quốc tế
- Cung cấp bảng xếp hạng tay đua và đội đua theo thời gian thực

Hệ thống là ứng dụng web full-stack gồm: Frontend React.js (giao diện người dùng), Backend Node.js/Express (API), và MySQL/MariaDB (cơ sở dữ liệu).

### 1.4 Mục tiêu báo cáo

Báo cáo này nhằm:

1. Trình bày quá trình phân tích, thiết kế và triển khai cơ sở dữ liệu cho hệ thống F1 Championship Management
2. Minh họa cách áp dụng các khái niệm DBMS học thuật (chuẩn hóa, ràng buộc toàn vẹn, transaction ACID, index, view, stored procedure, trigger) vào bài toán thực tế
3. Phân tích chi tiết nghiệp vụ logic và cách cơ sở dữ liệu hỗ trợ các quy trình nghiệp vụ đó
4. Đánh giá các quyết định thiết kế và gợi ý hướng cải thiện

---

## CHƯƠNG 2 — CƠ SỞ LÝ THUYẾT

### 2.1 Khái niệm DBMS

**Định nghĩa:** DBMS là tập hợp các chương trình cho phép người dùng tạo lập, duy trì và truy xuất cơ sở dữ liệu. DBMS cung cấp giao diện giữa người dùng và cơ sở dữ liệu, đồng thời quản lý tất cả truy cập vào dữ liệu.

**Các thành phần chính của DBMS:**
- **DDL (Data Definition Language):** Ngôn ngữ định nghĩa cấu trúc — `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`
- **DML (Data Manipulation Language):** Ngôn ngữ thao tác dữ liệu — `SELECT`, `INSERT`, `UPDATE`, `DELETE`
- **DCL (Data Control Language):** Ngôn ngữ kiểm soát truy cập — `GRANT`, `REVOKE`
- **TCL (Transaction Control Language):** Ngôn ngữ kiểm soát giao dịch — `BEGIN`, `COMMIT`, `ROLLBACK`

### 2.2 Các mô hình dữ liệu

**Mô hình quan hệ (Relational Model)** — được sử dụng trong dự án này:
Dữ liệu được tổ chức thành các quan hệ (relation), biểu diễn dưới dạng bảng 2 chiều. Mỗi hàng (tuple) đại diện cho một thực thể, mỗi cột (attribute) đại diện cho một thuộc tính. Mối quan hệ giữa các bảng được thiết lập qua Khóa ngoại (Foreign Key). Đây là mô hình phổ biến nhất hiện nay.

**Mô hình phi quan hệ (NoSQL):**
Gồm nhiều dạng: Document Store (MongoDB), Key-Value Store (Redis), Column Family (Cassandra), Graph Database (Neo4j). Phù hợp cho dữ liệu phi cấu trúc hoặc yêu cầu mở rộng ngang cực lớn.

**So sánh cho bài toán F1:**
Mô hình quan hệ phù hợp hơn cho hệ thống F1 vì: dữ liệu có cấu trúc rõ ràng, có nhiều mối quan hệ phức tạp giữa các thực thể (tay đua — đội — hợp đồng — chặng — kết quả), và yêu cầu ràng buộc toàn vẹn chặt chẽ.

### 2.3 Kiến trúc 3 mức (Three-Level Architecture)

Kiến trúc ANSI/SPARC định nghĩa 3 mức nhìn vào cơ sở dữ liệu:

```
┌─────────────────────────────────────────┐
│  MỨC NGOÀI (External Level)             │
│  View của từng nhóm người dùng          │
│  v_driver_standings, v_team_standings   │
├─────────────────────────────────────────┤
│  MỨC KHÁI NIỆM (Conceptual Level)       │
│  Schema logic toàn bộ hệ thống          │
│  7 bảng, FK, Constraints, Trigger       │
├─────────────────────────────────────────┤
│  MỨC VẬT LÝ (Physical Level)           │
│  Cách dữ liệu lưu trên đĩa             │
│  B-Tree index, InnoDB tablespace        │
└─────────────────────────────────────────┘
```

- **Mức Ngoài:** Mỗi nhóm người dùng nhìn thấy một "view" khác nhau của dữ liệu. Trong dự án F1, Staff xem Module Đăng ký chỉ thấy thông tin liên quan đến đăng ký; trang BXH chỉ thấy điểm và xếp hạng.
- **Mức Khái niệm:** Toàn bộ schema — 7 bảng với các mối quan hệ, ràng buộc, trigger, stored procedure. Đây là tầng DBA làm việc.
- **Mức Vật lý:** InnoDB engine tổ chức dữ liệu thực sự trên đĩa theo B+ Tree, quản lý buffer pool, redo log, undo log.

### 2.4 Các khái niệm cơ bản

**Bảng (Table/Relation):** Tập hợp dữ liệu có cấu trúc, gồm các hàng và cột.

**Khóa chính (Primary Key — PK):** Cột hoặc tập cột xác định duy nhất mỗi hàng trong bảng. Ví dụ: `driver_code` trong bảng DRIVERS.

**Khóa ngoại (Foreign Key — FK):** Cột tham chiếu đến PK của bảng khác, thiết lập mối quan hệ giữa 2 bảng và đảm bảo toàn vẹn tham chiếu. Ví dụ: `RESULTS.entry_id` tham chiếu đến `RACE_ENTRIES.entry_id`.

**Khóa dự tuyển (Candidate Key):** Bất kỳ tập thuộc tính nào có thể xác định duy nhất một hàng. Ví dụ: trong RACE_ENTRIES, cặp `(race_code, contract_id)` là candidate key.

**Ràng buộc toàn vẹn (Integrity Constraint):**
- **Domain Constraint:** Giới hạn miền giá trị của cột (NOT NULL, CHECK, ENUM)
- **Entity Integrity:** PK không được NULL
- **Referential Integrity:** FK phải tham chiếu đến giá trị PK tồn tại
- **Semantic Integrity:** Ràng buộc nghiệp vụ tùy chỉnh (Trigger)

---

## CHƯƠNG 3 — MÔ TẢ BÀI TOÁN VÀ PHÂN TÍCH YÊU CẦU

### 3.1 Mô tả hệ thống

F1 Championship Management System là hệ thống quản lý toàn diện các dữ liệu liên quan đến một mùa giải đua xe Formula 1. Hệ thống gồm 4 module chức năng chính tương ứng với 4 giai đoạn trong vòng đời một chặng đua:

| Module | Tên | Vai trò |
|--------|-----|---------|
| Module 1 | Register Racing | Đăng ký tay đua tham gia chặng đua |
| Module 2 | Update Results | Nhập kết quả thi đấu sau chặng |
| Module 3 | Driver Standings | Xem bảng xếp hạng tay đua |
| Module 4 | Team Standings | Xem bảng xếp hạng đội đua |

### 3.2 Stakeholders (Người dùng hệ thống)

**Ban tổ chức / Staff nhập liệu:**
- Đăng ký tay đua vào từng chặng đua (Module 1)
- Nhập kết quả sau khi chặng kết thúc (Module 2)
- Xem bảng xếp hạng để kiểm tra và công bố kết quả (Module 3, 4)

**Quản trị viên hệ thống (DBA):**
- Khởi tạo và bảo trì cơ sở dữ liệu
- Thêm mùa giải, chặng đua, đội đua, tay đua mới
- Theo dõi hiệu năng và backup định kỳ

**Người xem / Khán giả (Read-only):**
- Xem bảng xếp hạng (Module 3, 4)
- Không có quyền ghi dữ liệu

### 3.3 Yêu cầu chức năng (Functional Requirements)

**FR-01:** Hệ thống quản lý thông tin các mùa giải F1 (thêm, sửa, xem).

**FR-02:** Hệ thống quản lý danh sách đội đua và tay đua, bao gồm thông tin cá nhân và lịch sử hợp đồng.

**FR-03:** Hệ thống cho phép đăng ký tay đua vào từng chặng đua, với ràng buộc mỗi đội tối đa 2 tay đua/chặng.

**FR-04:** Hệ thống cho phép nhập kết quả thi đấu (thời gian kết thúc, số vòng hoàn thành, trạng thái) cho từng tay đua.

**FR-05:** Hệ thống tự động tính điểm theo hệ thống tính điểm F1 quốc tế (P1=25, P2=18, P3=15, ..., P10=1) ngay sau khi kết quả được lưu.

**FR-06:** Hệ thống cung cấp bảng xếp hạng tay đua và đội đua theo thời gian thực, hỗ trợ lọc theo từng chặng cụ thể.

**FR-07:** Hệ thống cho phép xem lịch sử kết quả chi tiết của từng tay đua và từng đội qua các chặng.

**FR-08:** Hệ thống hỗ trợ sửa lại kết quả đã nhập (trong trường hợp có điều chỉnh sau khi xem xét lại).

### 3.4 Yêu cầu phi chức năng (Non-Functional Requirements)

**Hiệu năng:**
- Bảng xếp hạng tải trong < 2 giây với dữ liệu một mùa giải (20+ chặng, 20+ tay đua)
- Module nhập kết quả phản hồi trong < 3 giây kể cả bước tính điểm tự động

**Tính toàn vẹn dữ liệu:**
- Dữ liệu phải nhất quán tại mọi thời điểm — không có kết quả "nửa vời"
- Không thể nhập kết quả vi phạm nghiệp vụ (thời gian kết thúc trước khi chặng bắt đầu, số vòng âm)

**Bảo mật:**
- Thông tin đăng nhập DB không được hardcode trong source code
- Mọi truy vấn phải dùng Prepared Statements để chống SQL Injection

**Khả dụng:**
- Hệ thống hỗ trợ nhiều người dùng đồng thời xem và nhập dữ liệu mà không block nhau

**Khả năng phục hồi:**
- Có chiến lược backup có thể phục hồi dữ liệu đến thời điểm bất kỳ

---

## CHƯƠNG 4 — NGHIỆP VỤ LOGIC (BUSINESS LOGIC)

### 4.1 Quy trình nghiệp vụ tổng thể

Một chặng đua F1 đi qua vòng đời sau trong hệ thống:

```
[1. Admin tạo chặng đua mới trong DB]
              ↓
[2. Staff Module 1: Đăng ký tay đua từng đội]
              ↓
[3. Chặng đua diễn ra trong thực tế]
              ↓
[4. Staff Module 2: Nhập kết quả từng tay đua]
              ↓
[5. Hệ thống tự động gọi sp_calculate_points]
              ↓
[6. Điểm được ghi vào RESULTS.points]
              ↓
[7. Module 3 & 4: Đọc BXH từ Views]
```

### 4.2 Business Rules (Quy tắc nghiệp vụ)

**BR-01 — Giới hạn tay đua mỗi đội:**
Mỗi đội đua chỉ được đăng ký tối đa 2 tay đua cho mỗi chặng. Đây là quy định của FIA (Liên đoàn Ô tô Quốc tế). Ràng buộc này được thực thi bằng **Trigger** ở tầng Database.

**BR-02 — Hệ thống tính điểm F1:**
Điểm được gán theo thứ hạng thời gian của các tay đua hoàn thành chặng (status = 'Finished'):

| Hạng | Điểm | Hạng | Điểm |
|------|------|------|------|
| P1   | 25   | P6   | 8    |
| P2   | 18   | P7   | 6    |
| P3   | 15   | P8   | 4    |
| P4   | 12   | P9   | 2    |
| P5   | 10   | P10  | 1    |
| Từ P11 | 0  | DNF/Accident | 0 |

**BR-03 — Tính hợp lệ của thời gian:**
Thời gian kết thúc (end_time) của tay đua phải lớn hơn thời gian bắt đầu chặng (start_time). Được thực thi bằng **Trigger** bảo vệ cả INSERT và UPDATE.

**BR-04 — Xếp hạng bằng điểm:**
Thứ tự BXH ưu tiên: (1) Tổng điểm giảm dần; (2) Nếu bằng điểm → tổng thời gian tăng dần.

**BR-05 — Điểm đội = Tổng điểm tay đua:**
Điểm của đội tại mỗi chặng bằng tổng điểm của TẤT CẢ tay đua của đội đó tại chặng đó (không lấy trung bình).

**BR-06 — Lịch sử hợp đồng:**
Tay đua có thể chuyển đội giữa các mùa giải. Lịch sử hợp đồng phải được lưu đầy đủ. Hợp đồng cũ set is_active = 0, hợp đồng mới INSERT với is_active = 1.

### 4.3 Trigger — Ràng buộc nghiệp vụ tại tầng Database

#### Trigger 1: trg_limit_2_riders

**Mục đích:** Chặn đăng ký tay đua thứ 3 của cùng một đội vào cùng một chặng.

**Thời điểm kích hoạt:** BEFORE INSERT trên bảng RACE_ENTRIES

**Luồng xử lý:**

```
[Nhận INSERT vào RACE_ENTRIES]
          ↓
[Lấy team_code từ CONTRACTS dựa trên NEW.contract_id]
          ↓
[Đếm số tay đua cùng đội đã đăng ký chặng NEW.race_code]
          ↓
    count >= 2?
   /            \
 Có              Không
  ↓                ↓
[SIGNAL lỗi]   [INSERT tiếp tục]
[Hủy INSERT]
```

**SQL Implementation:**

```sql
DELIMITER //
CREATE TRIGGER trg_limit_2_riders
BEFORE INSERT ON RACE_ENTRIES
FOR EACH ROW
BEGIN
    DECLARE v_team_id VARCHAR(10);
    DECLARE v_count INT;
    -- Lấy team_code của tay đua sắp đăng ký
    SELECT team_code INTO v_team_id 
    FROM CONTRACTS WHERE contract_id = NEW.contract_id;
    -- Đếm tay đua cùng đội đã đăng ký chặng này
    SELECT COUNT(*) INTO v_count 
    FROM RACE_ENTRIES re 
    JOIN CONTRACTS c ON re.contract_id = c.contract_id
    WHERE re.race_code = NEW.race_code AND c.team_code = v_team_id;
    -- Nếu đã đủ 2 → từ chối
    IF v_count >= 2 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Lỗi: Mỗi đội chỉ được tối đa 2 tay đua tham gia mỗi chặng!';
    END IF;
END //
DELIMITER ;
```

**Lý do đặt ở tầng DB:** Nếu chỉ kiểm tra ở Frontend hay Backend, người dùng có thể bypass bằng cách gọi API trực tiếp hoặc kết nối DB qua Workbench. Trigger đảm bảo ràng buộc được áp dụng tại MỌI ĐIỂM TRUY CẬP.

#### Trigger 2 & 3: trg_check_time_insert / trg_check_time_update

**Mục đích:** Đảm bảo end_time > start_time của chặng tương ứng.

**Thời điểm kích hoạt:** BEFORE INSERT và BEFORE UPDATE trên bảng RESULTS

**SQL Implementation:**

```sql
DELIMITER //
CREATE TRIGGER trg_check_time_insert
BEFORE INSERT ON RESULTS
FOR EACH ROW
BEGIN
    DECLARE v_start_time DATETIME(3);
    IF NEW.status = 'Finished' AND NEW.end_time IS NOT NULL THEN
        SELECT r.start_time INTO v_start_time 
        FROM RACE_ENTRIES re 
        JOIN RACES r ON re.race_code = r.race_code 
        WHERE re.entry_id = NEW.entry_id;
        
        IF NEW.end_time <= v_start_time THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Lỗi: Thời gian kết thúc phải lớn hơn thời gian bắt đầu chặng!';
        END IF;
    END IF;
END //
DELIMITER ;
```

*Trigger trg_check_time_update có cấu trúc tương tự, áp dụng cho thao tác UPDATE.*

### 4.4 Transaction — Đảm bảo tính nguyên tử

#### Transaction Module 2 — Bulk Upsert kết quả + Tính điểm

Đây là nghiệp vụ phức tạp nhất, cần Transaction để đảm bảo tính ACID:

```
[staff nhấn "Save All Results"]
              ↓
  [BEGIN TRANSACTION — Node.js]
              ↓
  [Vòng lặp: INSERT/UPDATE RESULTS cho từng tay đua]
   - Dùng ON DUPLICATE KEY UPDATE
   - Nếu bất kỳ dòng nào lỗi → ROLLBACK toàn bộ
              ↓
  [Gọi sp_calculate_points(race_code)]
   - SP có EXIT HANDLER FOR SQLEXCEPTION → ROLLBACK nội bộ
   - Nếu SP lỗi → ROLLBACK toàn bộ
              ↓
  [COMMIT — Dữ liệu được ghi vĩnh viễn]
```

**Kịch bản lỗi được xử lý:**
- Dòng thứ 3 của 4 tay đua bị Trigger từ chối (end_time sai) → toàn bộ 4 dòng rollback
- SP tính điểm gặp lỗi runtime → toàn bộ kết quả rollback — không có trạng thái "có kết quả nhưng chưa có điểm"

### 4.5 Stored Procedure — sp_calculate_points

Stored Procedure là trung tâm của nghiệp vụ tính điểm. Nó được gọi tự động sau mỗi lần lưu kết quả và thực hiện toàn bộ logic xếp hạng + phân điểm bên trong Database.

**Luồng xử lý chi tiết:**

```
[CALL sp_calculate_points('MONACO26')]
              ↓
  [START TRANSACTION + khai báo EXIT HANDLER]
              ↓
  [Bước 1: Reset điểm chặng về 0]
  UPDATE RESULTS SET points = 0
  WHERE race_code = 'MONACO26'
              ↓
  [Bước 2: Xếp hạng thời gian bằng RANK()]
  RANK() OVER (ORDER BY TIMESTAMPDIFF(MICROSECOND, start, end) ASC)
  Chỉ xếp tay đua có status = 'Finished'
              ↓
  [Bước 3: Gán điểm theo hạng]
  UPDATE RESULTS SET points = CASE
    WHEN rank=1 THEN 25
    WHEN rank=2 THEN 18
    ...
  END
              ↓
  [COMMIT]
```

**SQL Implementation:**

```sql
DELIMITER //
CREATE PROCEDURE sp_calculate_points(IN p_race_code VARCHAR(10))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Bước 1: Reset điểm về 0
    UPDATE RESULTS res
    JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
    SET res.points = 0
    WHERE re.race_code = p_race_code;
    
    -- Bước 2 & 3: Xếp hạng và gán điểm
    UPDATE RESULTS target
    JOIN (
        SELECT res.entry_id,
        RANK() OVER (
            ORDER BY TIMESTAMPDIFF(MICROSECOND, r.start_time, res.end_time) ASC
        ) AS pos
        FROM RESULTS res
        JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id
        JOIN RACES r ON re.race_code = r.race_code
        WHERE re.race_code = p_race_code AND res.status = 'Finished'
    ) rnk ON target.entry_id = rnk.entry_id
    SET target.points = CASE 
        WHEN rnk.pos = 1  THEN 25 WHEN rnk.pos = 2  THEN 18
        WHEN rnk.pos = 3  THEN 15 WHEN rnk.pos = 4  THEN 12
        WHEN rnk.pos = 5  THEN 10 WHEN rnk.pos = 6  THEN 8
        WHEN rnk.pos = 7  THEN 6  WHEN rnk.pos = 8  THEN 4
        WHEN rnk.pos = 9  THEN 2  WHEN rnk.pos = 10 THEN 1
        ELSE 0 
    END;
        
    COMMIT;
END //
DELIMITER ;
```

**Tại sao dùng Subquery thay vì CTE:**
Ban đầu thiết kế dùng `WITH ... AS (...)` (CTE) nhưng MariaDB/MySQL có hạn chế tương thích khi dùng CTE bên trong UPDATE statement. Giải pháp: chuyển sang Derived Table (Subquery trong FROM của UPDATE) — kết quả tương đương, tương thích tốt hơn.

### 4.6 Views — Bảng ảo tổng hợp BXH

Thay vì để Frontend/Backend phải viết câu JOIN phức tạp mỗi lần xem BXH, 3 View được tạo để đóng gói logic truy vấn.

#### View 1: v_race_performance

**Mục đích:** Tổng hợp kết quả từng tay đua tại từng chặng — là nguồn dữ liệu cho 2 View còn lại.

```sql
CREATE VIEW v_race_performance AS
SELECT 
    re.race_code, 
    c.driver_code, 
    c.team_code, 
    res.status, 
    res.laps_completed, 
    res.points,
    TIMESTAMPDIFF(MICROSECOND, r.start_time, res.end_time) / 1000000 
        AS finish_time_seconds,
    r.start_time AS race_start_time
FROM RESULTS res 
JOIN RACE_ENTRIES re ON res.entry_id = re.entry_id 
JOIN RACES r ON re.race_code = r.race_code 
JOIN CONTRACTS c ON re.contract_id = c.contract_id;
```

#### View 2: v_driver_standings

**Mục đích:** BXH tay đua toàn mùa giải — API chỉ cần `SELECT * FROM v_driver_standings`.

```sql
CREATE VIEW v_driver_standings AS
SELECT 
    d.driver_code, d.name, d.nationality, t.name AS team_name,
    SUM(v.points) AS total_score,
    SUM(CASE WHEN v.status = 'Finished' 
        THEN v.finish_time_seconds ELSE 0 END) AS total_season_time
FROM DRIVERS d
JOIN CONTRACTS c ON d.driver_code = c.driver_code AND c.is_active = 1
JOIN TEAMS t ON c.team_code = t.team_code
JOIN v_race_performance v ON v.driver_code = d.driver_code 
    AND v.team_code = t.team_code
GROUP BY d.driver_code, d.name, d.nationality, t.name
ORDER BY total_score DESC, total_season_time ASC;
```

#### View 3: v_team_standings

**Mục đích:** BXH đội đua toàn mùa giải.

```sql
CREATE VIEW v_team_standings AS
SELECT 
    t.team_code, t.name AS team_name, t.brand,
    SUM(v.points) AS team_total_score,
    SUM(CASE WHEN v.status = 'Finished' 
        THEN v.finish_time_seconds ELSE 0 END) AS team_total_time
FROM TEAMS t
JOIN CONTRACTS c ON t.team_code = c.team_code AND c.is_active = 1
JOIN v_race_performance v ON v.team_code = t.team_code 
    AND v.driver_code = c.driver_code
GROUP BY t.team_code, t.name, t.brand
ORDER BY team_total_score DESC, team_total_time ASC;
```

---

## CHƯƠNG 5 — THIẾT KẾ CƠ SỞ DỮ LIỆU

### 5.1 Entity-Relationship Diagram (ERD)

```
CHAMPIONSHIPS (1) ──────────── (N) RACES
    champ_code PK                  race_code PK
    name                           name
    description                    num_laps
                                   location
                                   start_time
                                   champ_code FK

DRIVERS (1) ──── (N) CONTRACTS (N) ──── (1) TEAMS
driver_code PK    contract_id PK         team_code PK
name              driver_code FK         name
date_of_birth     team_code FK           brand
nationality       is_active              owner
biography                                description

CONTRACTS (1) ──── (N) RACE_ENTRIES (1) ──── (1) RESULTS
                       entry_id PK             entry_id PK (FK)
RACES (1) ─────────── race_code FK            end_time
                       contract_id FK          laps_completed
                                               status
                                               points
```

**Ghi chú mối quan hệ:**
- CHAMPIONSHIPS — RACES: 1 mùa giải có nhiều chặng đua
- DRIVERS — CONTRACTS — TEAMS: Quan hệ N-N qua bảng CONTRACTS (có thuộc tính is_active)
- RACES — RACE_ENTRIES — CONTRACTS: Tay đua đăng ký chặng đua thông qua hợp đồng
- RACE_ENTRIES — RESULTS: Quan hệ 1-1, mỗi entry có tối đa một kết quả

### 5.2 Mô tả chi tiết các thực thể và thuộc tính

#### CHAMPIONSHIPS — Mùa giải

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| champ_code | VARCHAR(10) | PK | Mã mùa giải. VD: 'F1-2026' |
| name | VARCHAR(255) | NOT NULL | Tên đầy đủ mùa giải |
| description | TEXT | NULL | Mô tả ngắn về mùa giải |

#### TEAMS — Đội đua

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| team_code | VARCHAR(10) | PK | Mã đội. VD: 'MCL', 'RBR' |
| name | VARCHAR(100) | NOT NULL | Tên đội đua |
| brand | VARCHAR(100) | NULL | Thương hiệu xe |
| owner | VARCHAR(100) | NULL | Tên chủ đội/Team Principal |
| description | TEXT | NULL | Giới thiệu đội |

#### DRIVERS — Tay đua

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| driver_code | VARCHAR(10) | PK | Mã tay đua. VD: 'NOR', 'VER' |
| name | VARCHAR(100) | NOT NULL | Tên tay đua |
| date_of_birth | DATE | NULL | Ngày sinh |
| nationality | VARCHAR(50) | NULL | Quốc tịch |
| biography | TEXT | NULL | Tiểu sử |

#### CONTRACTS — Hợp đồng tay đua — đội

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| contract_id | INT | PK AUTO_INCREMENT | ID hợp đồng |
| driver_code | VARCHAR(10) | FK → DRIVERS | Tay đua |
| team_code | VARCHAR(10) | FK → TEAMS | Đội đua |
| is_active | TINYINT | DEFAULT 1 | 1=đang hiệu lực, 0=đã kết thúc |

#### RACES — Chặng đua

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| race_code | VARCHAR(10) | PK | Mã chặng. VD: 'MONACO26' |
| name | VARCHAR(100) | NOT NULL | Tên chặng đua |
| num_laps | INT | NOT NULL | Số vòng quy định |
| location | VARCHAR(255) | NULL | Địa điểm tổ chức |
| start_time | DATETIME(3) | NULL | Thời điểm xuất phát (ms precision) |
| champ_code | VARCHAR(10) | FK → CHAMPIONSHIPS | Thuộc mùa giải nào |
| description | TEXT | NULL | Mô tả |

#### RACE_ENTRIES — Đăng ký tham gia chặng

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| entry_id | INT | PK AUTO_INCREMENT | ID đăng ký |
| race_code | VARCHAR(10) | FK → RACES | Chặng đua nào |
| contract_id | INT | FK → CONTRACTS | Tay đua (qua hợp đồng) |
| (composite) | — | UNIQUE(race_code, contract_id) | Không đăng ký trùng |

#### RESULTS — Kết quả thi đấu

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|-----|-------------|-----------|-------|
| entry_id | INT | PK, FK → RACE_ENTRIES | Tham chiếu 1-1 |
| end_time | DATETIME(3) | NULL | Thời điểm về đích |
| laps_completed | INT | CHECK >=0 | Số vòng hoàn thành |
| status | ENUM | DEFAULT 'Finished' | Trạng thái kết thúc |
| points | INT | DEFAULT 0, CHECK >=0 | Điểm F1 — do SP cập nhật |

### 5.3 Chuyển sang mô hình quan hệ

Từ ERD, chuyển thành các schema bảng quan hệ:

```
CHAMPIONSHIPS(champ_code, name, description)
TEAMS(team_code, name, brand, owner, description)
DRIVERS(driver_code, name, date_of_birth, nationality, biography)
CONTRACTS(contract_id, driver_code*, team_code*, is_active)
RACES(race_code, name, num_laps, location, start_time, champ_code*, description)
RACE_ENTRIES(entry_id, race_code*, contract_id*)
RESULTS(entry_id*, end_time, laps_completed, status, points)
```
*Dấu * biểu thị khóa ngoại*

### 5.4 Chuẩn hóa (Normalization)

#### 1NF — First Normal Form

**Yêu cầu:** Mỗi cột chứa giá trị nguyên tử, không có nhóm lặp, có PK.

**Đánh giá:** Tất cả 7 bảng đạt 1NF:
- Không có cột nào chứa mảng hay danh sách (mỗi tay đua của đội là một dòng riêng trong CONTRACTS, không phải chuỗi "VER,NOR,PIA")
- Mỗi bảng có PK xác định duy nhất từng dòng
- Mọi cột chứa giá trị đơn, không thể chia nhỏ hơn

#### 2NF — Second Normal Form

**Yêu cầu:** Đạt 1NF + không có phụ thuộc hàm bộ phận (cột không-khóa chỉ phụ thuộc vào MỘT PHẦN của khóa ghép).

**Đánh giá:** Tất cả bảng đạt 2NF:
- Các bảng có PK đơn (1 cột) không thể có phụ thuộc bộ phận
- RACE_ENTRIES dùng surrogate key `entry_id` thay vì khóa ghép `(race_code, contract_id)` — loại bỏ khả năng vi phạm 2NF nếu thêm thuộc tính mới

**Ví dụ vi phạm đã tránh được:** Nếu RACE_ENTRIES có PK = (race_code, contract_id) và thêm cột `race_location`, thì `race_location` chỉ phụ thuộc vào `race_code` (một phần PK) → vi phạm 2NF → đã tách sang bảng RACES.

#### 3NF — Third Normal Form

**Yêu cầu:** Đạt 2NF + không có phụ thuộc hàm bắc cầu.

**Đánh giá:** Schema đạt 3NF:

**Ví dụ phụ thuộc bắc cầu đã được loại bỏ:**
Nếu để `team_name` trong RACE_ENTRIES:
- `entry_id → contract_id → team_code → team_name`
- `team_name` phụ thuộc bắc cầu vào `entry_id` qua `contract_id → team_code`
- Giải pháp: loại bỏ `team_name` khỏi RACE_ENTRIES, JOIN qua CONTRACTS → TEAMS khi cần.

#### BCNF — Boyce-Codd Normal Form

**Yêu cầu:** Mọi phụ thuộc hàm X → Y đều có X là superkey.

**Đánh giá:** Không có vi phạm BCNF trong schema hiện tại:
- Trong CONTRACTS: `contract_id → (driver_code, team_code, is_active)` — contract_id là PK (superkey) ✓
- Trong RESULTS: `entry_id → (end_time, laps_completed, status, points)` — entry_id là PK ✓

**Kết luận:** Schema đạt BCNF, cân bằng tốt giữa tính chuẩn hóa và hiệu năng thực tế.

---

## CHƯƠNG 6 — TRIỂN KHAI

### 6.1 Môi trường và công nghệ

| Thành phần | Công nghệ | Phiên bản |
|-----------|-----------|-----------|
| DBMS | MySQL / MariaDB | 8.0 / 10.6+ |
| Backend | Node.js + Express | 18+ |
| DB Driver | mysql2/promise | 3.x |
| Frontend | React.js | 18+ |
| Quản trị DB | MySQL Workbench | 8.x |

### 6.2 Schema — Tạo cấu trúc bảng (DDL)

```sql
-- 1. Tạo database
DROP DATABASE IF EXISTS F1_Championship_Management;
CREATE DATABASE F1_Championship_Management;
USE F1_Championship_Management;

-- 2. Tạo bảng CHAMPIONSHIPS
CREATE TABLE CHAMPIONSHIPS (
    champ_code  VARCHAR(10)  PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT
);

-- 3. Tạo bảng TEAMS
CREATE TABLE TEAMS (
    team_code   VARCHAR(10)  PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    brand       VARCHAR(100),
    owner       VARCHAR(100),
    description TEXT
);

-- 4. Tạo bảng DRIVERS
CREATE TABLE DRIVERS (
    driver_code  VARCHAR(10)  PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    nationality  VARCHAR(50),
    biography    TEXT
);

-- 5. Tạo bảng CONTRACTS
CREATE TABLE CONTRACTS (
    contract_id INT          AUTO_INCREMENT PRIMARY KEY,
    driver_code VARCHAR(10),
    team_code   VARCHAR(10),
    is_active   TINYINT      DEFAULT 1,
    FOREIGN KEY (driver_code) REFERENCES DRIVERS(driver_code),
    FOREIGN KEY (team_code)   REFERENCES TEAMS(team_code)
);

-- 6. Tạo bảng RACES
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

-- 7. Tạo bảng RACE_ENTRIES
CREATE TABLE RACE_ENTRIES (
    entry_id    INT    AUTO_INCREMENT PRIMARY KEY,
    race_code   VARCHAR(10),
    contract_id INT,
    FOREIGN KEY (race_code)   REFERENCES RACES(race_code),
    FOREIGN KEY (contract_id) REFERENCES CONTRACTS(contract_id),
    UNIQUE(race_code, contract_id)
);

-- 8. Tạo bảng RESULTS với CHECK constraints
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
```

### 6.3 Nạp dữ liệu mẫu (DML — INSERT)

```sql
-- Mùa giải
INSERT INTO CHAMPIONSHIPS VALUES ('F1-2026', 'Formula 1 2026', 'The 2026 season');

-- Đội đua
INSERT INTO TEAMS VALUES ('RBR', 'Red Bull Racing', 'Red Bull',  'Christian Horner', 'Top Team');
INSERT INTO TEAMS VALUES ('FER', 'Scuderia Ferrari', 'Ferrari',  'Fred Vasseur',     'Iconic Team');
INSERT INTO TEAMS VALUES ('MER', 'Mercedes-AMG',    'Mercedes', 'Toto Wolff',        'Silver Arrows');
INSERT INTO TEAMS VALUES ('MCL', 'McLaren',          'McLaren',  'Zak Brown',         'Papaya Team');

-- Tay đua
INSERT INTO DRIVERS VALUES ('VER', 'Max Verstappen',       '1997-09-30', 'Dutch',       '');
INSERT INTO DRIVERS VALUES ('NOR', 'Lando Norris',         '1999-11-13', 'British',     '');
INSERT INTO DRIVERS VALUES ('PIA', 'Oscar Piastri',        '2001-04-06', 'Australian',  '');
INSERT INTO DRIVERS VALUES ('LEC', 'Charles Leclerc',      '1997-10-16', 'Monegasque',  '');
INSERT INTO DRIVERS VALUES ('HAM', 'Lewis Hamilton',       '1985-01-07', 'British',     '');

-- Hợp đồng
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('VER', 'RBR');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('NOR', 'MCL');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('PIA', 'MCL');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('LEC', 'FER');
INSERT INTO CONTRACTS (driver_code, team_code) VALUES ('HAM', 'MER');

-- Chặng đua
INSERT INTO RACES VALUES 
    ('BHR26', 'Bahrain GP',     57, 'Sakhir',      '2026-03-05 15:00:00.000', 'F1-2026', 'Season Opener'),
    ('JED26', 'Saudi Arabian GP', 50, 'Jeddah',    '2026-03-19 17:00:00.000', 'F1-2026', 'Night Race'),
    ('MONACO26', 'Monaco GP',   78, 'Monte Carlo', '2026-05-24 15:00:00.000', 'F1-2026', 'Jewel of Crown');
```

### 6.4 Các câu truy vấn SQL quan trọng

#### 6.4.1 SELECT với JOIN — Lấy danh sách đăng ký của một chặng

```sql
-- Lấy tất cả tay đua đã đăng ký chặng Monaco GP
SELECT 
    re.entry_id,
    d.name          AS driver_name,
    t.name          AS team_name,
    d.nationality,
    re.race_code
FROM RACE_ENTRIES re
JOIN CONTRACTS c ON re.contract_id = c.contract_id
JOIN DRIVERS   d ON c.driver_code  = d.driver_code
JOIN TEAMS     t ON c.team_code    = t.team_code
WHERE re.race_code = 'MONACO26'
ORDER BY t.name ASC, d.name ASC;
```

#### 6.4.2 SELECT với GROUP BY — Tổng hợp điểm tay đua

```sql
-- Bảng xếp hạng tay đua toàn mùa giải F1-2026
SELECT
    d.driver_code,
    d.name,
    d.nationality,
    t.name                                                    AS team_name,
    SUM(vp.points)                                            AS total_score,
    SUM(CASE WHEN vp.status = 'Finished' 
              THEN vp.finish_time_seconds ELSE 0 END)         AS total_time
FROM DRIVERS d
JOIN CONTRACTS c ON d.driver_code = c.driver_code AND c.is_active = 1
JOIN TEAMS t      ON c.team_code  = t.team_code
JOIN v_race_performance vp ON vp.driver_code = d.driver_code 
                           AND vp.team_code  = t.team_code
GROUP BY d.driver_code, d.name, d.nationality, t.name
ORDER BY total_score DESC, total_time ASC;
```

#### 6.4.3 SELECT với HAVING — Đội có tổng điểm > 50

```sql
-- Lọc đội có tổng điểm trên 50
SELECT 
    t.team_code,
    t.name AS team_name,
    SUM(vp.points) AS team_score
FROM TEAMS t
JOIN CONTRACTS c ON t.team_code = c.team_code AND c.is_active = 1
JOIN v_race_performance vp ON vp.team_code = t.team_code
GROUP BY t.team_code, t.name
HAVING SUM(vp.points) > 50
ORDER BY team_score DESC;
```

#### 6.4.4 INSERT với ON DUPLICATE KEY UPDATE — Upsert kết quả

```sql
-- Nhập hoặc cập nhật kết quả tay đua (entry_id = 5)
INSERT INTO RESULTS (entry_id, end_time, laps_completed, status)
VALUES (5, '2026-05-24 17:26:15.483', 78, 'Finished')
ON DUPLICATE KEY UPDATE
    end_time       = VALUES(end_time),
    laps_completed = VALUES(laps_completed),
    status         = VALUES(status);
-- points sẽ được cập nhật tự động bởi sp_calculate_points
```

#### 6.4.5 UPDATE — Sửa thông tin

```sql
-- Cập nhật thông tin chủ đội McLaren
UPDATE TEAMS 
SET owner = 'Zak Brown', brand = 'McLaren Racing'
WHERE team_code = 'MCL';
```

#### 6.4.6 DELETE — Xóa kết quả (Clear result)

```sql
-- Xóa kết quả một tay đua (để nhập lại)
DELETE FROM RESULTS WHERE entry_id = 5;
-- Sau khi xóa, gọi lại sp_calculate_points để tính lại điểm chặng
```

#### 6.4.7 Subquery — BXH tay đua tính đến một chặng cụ thể

```sql
-- BXH tay đua tính điểm từ đầu mùa đến hết Saudi Arabian GP
SELECT 
    d.driver_code, d.name, t.name AS team_name,
    SUM(vp.points) AS total_score,
    SUM(CASE WHEN vp.status = 'Finished' 
              THEN vp.finish_time_seconds ELSE 0 END) AS total_time
FROM DRIVERS d
JOIN CONTRACTS c ON d.driver_code = c.driver_code AND c.is_active = 1
JOIN TEAMS t ON c.team_code = t.team_code
JOIN v_race_performance vp ON vp.driver_code = d.driver_code 
                           AND vp.team_code  = t.team_code
JOIN RACES r ON vp.race_code = r.race_code
WHERE r.start_time <= (
    SELECT start_time FROM RACES WHERE race_code = 'JED26'
)
GROUP BY d.driver_code, d.name, t.name
ORDER BY total_score DESC, total_time ASC;
```

### 6.5 Index — Tối ưu hóa hiệu năng

```sql
-- Index tăng tốc truy vấn Module 2 và Views BXH
CREATE INDEX idx_race_code ON RACE_ENTRIES(race_code);

-- Covering Index cho Join theo đội
CREATE INDEX idx_team_code_contracts ON CONTRACTS(team_code, driver_code);

-- Index tăng tốc WHERE status = 'Finished' + ORDER BY end_time
CREATE INDEX idx_results_status_time ON RESULTS(status, end_time);

-- Index tăng tốc lọc BXH theo mốc thời gian chặng
CREATE INDEX idx_races_start_time ON RACES(start_time);
```

**Giải thích chiến lược index:**

| Index | Cột | Phục vụ truy vấn |
|-------|-----|-----------------|
| idx_race_code | RACE_ENTRIES(race_code) | WHERE race_code = ? — dùng nhiều nhất |
| idx_team_code_contracts | CONTRACTS(team_code, driver_code) | JOIN + Trigger đếm tay đua |
| idx_results_status_time | RESULTS(status, end_time) | RANK() ORDER BY trong SP |
| idx_races_start_time | RACES(start_time) | BXH đến stage cụ thể |

### 6.6 Phòng chống SQL Injection

Toàn bộ truy vấn trong Backend sử dụng Prepared Statements — SQL template và tham số được gửi riêng biệt đến MySQL:

```javascript
// ✅ ĐÚNG — Prepared Statement với ? placeholder
const [rows] = await db.query(
    'SELECT * FROM TEAMS WHERE team_code = ?',
    [req.params.team_code]
);

// ❌ SAI — Nối chuỗi trực tiếp — dễ bị SQL Injection
const [rows] = await db.query(
    'SELECT * FROM TEAMS WHERE team_code = ' + req.params.team_code
);
```

---

## CHƯƠNG 7 — ĐÁNH GIÁ VÀ THẢO LUẬN

### 7.1 Đánh giá thiết kế cơ sở dữ liệu

#### Điểm mạnh

**Chuẩn hóa đạt BCNF:**
Schema đạt chuẩn BCNF với thiết kế tách bạch rõ ràng giữa các thực thể. Không có dữ liệu dư thừa — thông tin đội chỉ lưu trong TEAMS, thông tin tay đua chỉ trong DRIVERS, không bị sao chép ở bảng khác.

**Mô hình hóa đúng thực tế nghiệp vụ:**
Bảng CONTRACTS phản ánh đúng bản chất của mối quan hệ tay đua — đội trong F1: lịch sử chuyển đội được lưu đầy đủ nhờ is_active. Bảng RACE_ENTRIES tách biệt với RESULTS phản ánh đúng hai sự kiện có thời điểm khác nhau trong thực tế.

**Phân tầng ràng buộc rõ ràng:**
- Tầng DB: NOT NULL, UNIQUE, FK, CHECK, TRIGGER — không bỏ qua được
- Tầng Backend: Validation server-side, Prepared Statements
- Tầng Frontend: UX gợi ý và validation trước khi gửi form

**Hiệu năng được tính toán:**
- 4 index bổ sung đúng vị trí
- Điểm được lưu vật lý (không tính lại mỗi lần xem BXH)
- Views đóng gói truy vấn phức tạp — Backend chỉ cần `SELECT * FROM v_driver_standings`

**Sử dụng đầy đủ các đối tượng DBMS:**

| Đối tượng | Số lượng | Mục đích |
|-----------|---------|---------|
| Table | 7 | Lưu trữ dữ liệu căn bản |
| View | 3 | Đóng gói truy vấn BXH |
| Stored Procedure | 1 | Logic tính điểm F1 |
| Trigger | 3 | Ràng buộc nghiệp vụ |
| Index | 4 | Tối ưu hiệu năng |
| Transaction | Nhiều | Đảm bảo tính ACID |

### 7.2 Độ phù hợp với nghiệp vụ

Hệ thống phản ánh chính xác nghiệp vụ thực tế của giải F1:

- **Hệ thống tính điểm F1 chuẩn:** SP sử dụng đúng bảng điểm 25-18-15-12-10-8-6-4-2-1
- **Quy định 2 tay đua/đội:** Trigger thực thi đúng quy định FIA
- **Xếp hạng tiebreak:** Khi bằng điểm, tổng thời gian quyết định — đúng với thực tế F1
- **RANK() xử lý đồng hạng:** Hai tay đua về cùng millisecond nhận cùng hạng

### 7.3 Hạn chế hiện tại

**H1 — Không lưu ngày bắt đầu/kết thúc hợp đồng:**
CONTRACTS chỉ có `is_active` (0/1), không có `start_date` và `end_date`. Không thể biết tay đua chuyển đội vào ngày cụ thể nào — hạn chế đối với phân tích lịch sử.

**H2 — Race Condition tại Trigger:**
Nếu 2 nhân viên đồng thời đăng ký tay đua thứ 2 của cùng đội vào cùng chặng, cả 2 transaction đều đọc count = 1 và đều pass trigger. Kết quả: đội có 3 tay đua đăng ký. Cần `SELECT ... FOR UPDATE` để giải quyết triệt để.

**H3 — Chưa có tính năng phân quyền người dùng:**
Hệ thống hiện tại không có Authentication (đăng nhập) và Authorization (phân quyền). Mọi người đều có thể nhập kết quả. Cần thêm JWT Authentication và role-based access control.

**H4 — Chưa có Audit Log:**
Không ghi lại lịch sử ai đã thay đổi dữ liệu vào lúc nào. Trong thực tế F1, mọi thay đổi kết quả phải có nhật ký kiểm toán.

**H5 — sp_calculate_points reset và tính lại toàn bộ mỗi lần:**
Mỗi khi lưu kết quả, SP chạy lại toàn bộ RANK() cho chặng đó. Với dữ liệu lớn (nhiều mùa, nhiều chặng), điều này dẫn đến tính toán không cần thiết.

### 7.4 Khả năng mở rộng

**Mở rộng tính năng Race Condition — Solve:**
```sql
-- Thêm vào Transaction của Module 1:
SELECT COUNT(*) FROM RACE_ENTRIES re
JOIN CONTRACTS c ON re.contract_id = c.contract_id
WHERE re.race_code = ? AND c.team_code = ?
FOR UPDATE; -- Lock dòng, chặn race condition
```

**Mở rộng lưu lịch sử hợp đồng:**
```sql
ALTER TABLE CONTRACTS 
ADD COLUMN start_date DATE,
ADD COLUMN end_date DATE;
```

**Mở rộng thêm Audit Log:**
```sql
CREATE TABLE AUDIT_LOG (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    table_name   VARCHAR(50),
    action       ENUM('INSERT','UPDATE','DELETE'),
    old_data     JSON,
    new_data     JSON,
    changed_at   DATETIME DEFAULT NOW(),
    changed_by   VARCHAR(50)
);
```

**Mở rộng hỗ trợ nhiều loại điểm:**
Bảng điểm F1 thay đổi theo từng era (thời kỳ). Có thể tạo bảng `SCORING_SYSTEMS` và truyền vào SP để hỗ trợ nhiều hệ thống tính điểm lịch sử.

---

## CHƯƠNG 8 — KẾT LUẬN

### 8.1 Tóm tắt kết quả

Báo cáo này trình bày quá trình phân tích, thiết kế và triển khai hệ thống F1 Championship Management với MySQL/MariaDB làm nền tảng DBMS. Các kết quả đạt được:

**Về thiết kế CSDL:**
- Schema 7 bảng đạt chuẩn BCNF, không dư thừa, phản ánh đúng thực tế nghiệp vụ F1
- 6 Foreign Key đảm bảo toàn vẹn tham chiếu hoàn chỉnh trong chuỗi dữ liệu
- 2 CHECK Constraint ngăn dữ liệu nghiệp vụ không hợp lệ (laps âm, điểm âm)

**Về đối tượng DBMS:**
- 3 Trigger thực thi ràng buộc nghiệp vụ tại tầng DB (giới hạn 2 tay đua/đội, thời gian hợp lệ)
- 1 Stored Procedure với Transaction ACID để tính điểm F1 tự động và nhất quán
- 3 View đóng gói logic truy vấn phức tạp, giúp API đơn giản hóa xuống 1 câu SELECT
- 4 Index bổ sung tối ưu hiệu năng cho các truy vấn quan trọng nhất

**Về tính toàn vẹn và bảo mật:**
- Mô hình "defense in depth" 3 tầng: Frontend → Backend → Database
- Prepared Statements toàn bộ API chống SQL Injection
- Transaction bảo vệ toàn bộ nghiệp vụ nhạy cảm

### 8.2 Bài học rút ra

**1. Database là nguồn sự thật cuối cùng (Single Source of Truth):**
Mọi ràng buộc quan trọng phải được đặt ở tầng Database. Frontend và Backend chỉ là lớp tiện ích — chúng có thể bị bypass. Trigger và Constraint ở DB không thể bị bỏ qua từ bất kỳ hướng nào.

**2. Thiết kế chuẩn hóa tốt ngay từ đầu:**
Việc tách RESULTS khỏi RACE_ENTRIES, dùng CONTRACTS thay vì gắn team_code vào DRIVERS — những quyết định này thoạt đầu có vẻ phức tạp nhưng tránh được hàng loạt vấn đề về nhất quán dữ liệu về sau.

**3. Transaction cho mọi nghiệp vụ đa bước:**
Bất kỳ nghiệp vụ nào liên quan đến nhiều bảng hoặc nhiều câu SQL tuần tự đều cần Transaction. Đây là bảo hiểm quan trọng nhất chống lại sự cố phần cứng và runtime error.

**4. Window Function là công cụ mạnh:**
RANK() OVER (...) giải quyết bài toán xếp hạng một cách thanh lịch và hiệu quả (O(n log n)) so với cách đếm thủ công bằng subquery (O(n²)).

**5. Index cần chọn lọc, không thừa:**
Index tăng tốc đọc nhưng làm chậm ghi và tốn disk. Chỉ tạo index trên các cột thực sự xuất hiện trong WHERE, JOIN, ORDER BY của truy vấn quan trọng.

**6. Hiểu kiến trúc Storage Engine ảnh hưởng đến quyết định thiết kế:**
Việc chọn InnoDB (thay vì MyISAM) là bắt buộc vì dự án này cần Foreign Key thực sự, Transaction ACID, Row-level Locking và MVCC. Hiểu sâu Storage Engine giúp đưa ra quyết định đúng ngay từ đầu.

### 8.3 Hướng phát triển

**Ngắn hạn:**
- Thêm Authentication (JWT) và phân quyền role-based
- Giải quyết Race Condition trong Module 1 bằng `SELECT ... FOR UPDATE`
- Thêm `start_date`/`end_date` vào CONTRACTS
- Thêm Audit Log Table + Trigger ghi lại mọi thay đổi kết quả

**Dài hạn:**
- Hỗ trợ nhiều mùa giải và lọc BXH theo mùa giải
- Thêm bảng `SCORING_SYSTEMS` để hỗ trợ nhiều hệ thống tính điểm lịch sử
- Export BXH ra PDF/Excel
- Tích hợp Read Replica (MySQL Replication) để tách tải đọc và ghi khi số người dùng tăng lớn
- Cân nhắc thêm Redis Cache cho BXH toàn mùa giải nếu traffic cao

---

## TÀI LIỆU THAM KHẢO

1. Ramakrishnan, R., & Gehrke, J. (2003). *Database Management Systems* (3rd ed.). McGraw-Hill.
2. Elmasri, R., & Navathe, S. B. (2015). *Fundamentals of Database Systems* (7th ed.). Pearson.
3. MySQL Documentation. (2024). *MySQL 8.0 Reference Manual*. Oracle Corporation. https://dev.mysql.com/doc/refman/8.0/en/
4. MariaDB Documentation. (2024). *MariaDB Server Documentation*. MariaDB Foundation. https://mariadb.com/kb/en/documentation/
5. Codd, E. F. (1970). A relational model of data for large shared data banks. *Communications of the ACM*, 13(6), 377–387.
6. Formula 1. (2024). *Sporting Regulations*. Fédération Internationale de l'Automobile (FIA). https://www.formula1.com/

---

*Báo cáo được thực hiện theo hướng dẫn học phần Database Management Systems.*  
*Toàn bộ code SQL và logic nghiệp vụ được lấy từ hệ thống thực tế đã triển khai.*
