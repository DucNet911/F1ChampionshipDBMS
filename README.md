# 🏎️ F1 Championship Management System

Hệ thống quản lý giải đua Formula 1 — ứng dụng web full-stack cho phép theo dõi, nhập liệu và xem bảng xếp hạng tay đua và đội đua theo thời gian thực.

---

## 📋 Mục lục

- [Tổng quan](#-tổng-quan)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Yêu cầu cài đặt](#-yêu-cầu-cài-đặt)
- [Hướng dẫn chạy dự án](#-hướng-dẫn-chạy-dự-án)
- [Các tính năng chính](#-các-tính-năng-chính)
- [Cấu trúc Database](#-cấu-trúc-database)

---

## 🌐 Tổng quan

Dự án gồm 2 phần:

| Phần | Công nghệ | Cổng mặc định |
|------|-----------|--------------|
| **Frontend** | React + Vite | `http://localhost:5173` |
| **Backend** | Node.js + Express | `http://localhost:5000` |
| **Database** | MySQL / MariaDB | `3306` |

Luồng hoạt động:
```
Người dùng (Trình duyệt)
        ↓
  Frontend (React)          ← http://localhost:5173
        ↓  Gọi REST API
  Backend (Node.js)         ← http://localhost:5000
        ↓  Truy vấn SQL
  Database (MySQL)          ← localhost:3306
```

---

## 🛠️ Công nghệ sử dụng

### Frontend
- **React 18** — Thư viện xây dựng giao diện
- **Vite** — Build tool và dev server (khởi động nhanh, hỗ trợ HMR)
- **React Router** — Điều hướng giữa các trang
- **Lucide React** — Bộ icon hiện đại

### Backend
- **Node.js** — Môi trường chạy JavaScript phía server
- **Express 5** — Framework xây dựng REST API
- **mysql2** — Driver kết nối MySQL/MariaDB (hỗ trợ Prepared Statements)
- **dotenv** — Quản lý biến môi trường từ file `.env`
- **cors** — Cho phép Frontend gọi API từ cổng khác

### Database
- **MySQL 8.0 / MariaDB 10.6+**
- Gồm: 7 bảng, 3 View, 1 Stored Procedure, 3 Trigger, 4 Index
- Hỗ trợ đa mùa giải (Multi-season), cấu trúc linh hoạt theo `champ_code`

---

## 📁 Cấu trúc dự án

```
f1-championship/
│
├── 📂 frontend/                  ← Giao diện người dùng (React + Vite)
│   ├── src/
│   │   ├── pages/
│   │   │   ├── RegisterRacing.jsx     ← Module 1: Đăng ký tay đua vào chặng
│   │   │   ├── UpdateResults.jsx      ← Module 2: Nhập kết quả thi đấu
│   │   │   ├── DriverStandings.jsx    ← Module 3: Bảng xếp hạng tay đua
│   │   │   └── TeamStandings.jsx      ← Module 4: Bảng xếp hạng đội đua
│   │   ├── components/               ← Các component dùng chung
│   │   ├── services/
│   │   │   └── api.js                ← Hàm gọi API tới Backend
│   │   ├── App.jsx                   ← Cấu hình route chính
│   │   ├── main.jsx                  ← Điểm khởi động React
│   │   └── index.css                 ← CSS toàn cục (glassmorphism, theme)
│   ├── package.json
│   └── vite.config.js
│
├── 📂 backend/                   ← REST API (Node.js + Express)
│   ├── controllers/
│   │   ├── masterController.js        ← CRUD đội đua, tay đua, chặng
│   │   └── raceController.js          ← Logic đăng ký, kết quả, BXH
│   ├── routes/
│   │   └── api.js                     ← Định nghĩa tất cả các route
│   ├── db.js                          ← Kết nối MySQL (Connection Pool)
│   ├── server.js                      ← Điểm khởi động server
│   ├── .env                           ← Biến môi trường (không commit lên Git)
│   └── package.json
│
└── schema.sql                    ← Script khởi tạo toàn bộ Database
```

---

## ✅ Yêu cầu cài đặt

Trước khi chạy, đảm bảo máy đã có:

- [Node.js](https://nodejs.org/) phiên bản **18+**
- [MySQL](https://dev.mysql.com/downloads/) hoặc [MariaDB](https://mariadb.org/download/) phiên bản **8.0 / 10.6+**
- npm (đi kèm với Node.js)

---

## 🚀 Hướng dẫn chạy dự án

### Bước 1 — Khởi tạo Database

Mở MySQL Workbench (hoặc MySQL CLI) và chạy file `schema.sql`:

```sql
-- Trong MySQL Workbench: File → Open SQL Script → chọn schema.sql → Run
-- Hoặc dùng CLI:
mysql -u root -p < schema.sql
```

File này sẽ tự động tạo:
- Database `F1_Championship_Management`
- 7 bảng dữ liệu với đầy đủ ràng buộc
- 3 Trigger kiểm soát nghiệp vụ (chặn vượt quá 2 tay đua/đội, kiểm tra thời gian hợp lệ)
- 1 Stored Procedure tính điểm F1
- 3 View tổng hợp bảng xếp hạng
- 4 Index tối ưu hiệu năng
- Dữ liệu hoàn chỉnh mùa **2025** (Championship, Teams, Drivers, Contracts, Races, Entries, Results)
- Dữ liệu khởi tạo mùa **2026** (được để trống kết quả phục vụ mục đích demo trực tiếp trên lớp)

---

### Bước 2 — Cấu hình Backend

Vào thư mục `backend/`, tạo hoặc kiểm tra file `.env`:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=F1_Championship_Management
DB_PORT=3306
PORT=5000
```

> ⚠️ Thay `your_password_here` bằng mật khẩu MySQL thực của bạn.

Cài đặt dependencies và khởi động Backend:

```bash
cd backend
npm install
npm run start
```

Nếu thành công, terminal sẽ hiển thị:
```
Server is running on port 5000
```

---

### Bước 3 — Khởi động Frontend

Mở terminal mới (giữ nguyên terminal Backend), chạy:

```bash
cd frontend
npm install
npm run dev
```

Nếu thành công, Vite sẽ hiển thị:
```
VITE v6.x.x  ready in xxx ms
➜  Local:   http://localhost:5173/
```

Mở trình duyệt và truy cập: **http://localhost:5173**

---

## 🎯 Các tính năng chính

### 🌟 Tính năng Đa mùa giải (Multi-Season) — *MỚI*
- Tích hợp thanh chọn Season (VD: 2025 / 2026) ở sidebar.
- Chuyển đổi mùa giải sẽ tự động tải lại toàn bộ thông tin về các cuộc đua, danh sách đăng ký, và bảng xếp hạng tương ứng cho mùa giải đó.

### Module 1 — Đăng ký tay đua (`/register`)
- Chọn chặng đua và đội đua thuộc mùa giải hiện tại.
- Tick chọn tay đua muốn tham gia (DB thiết kế mỗi đội có **3 tay đua**, nhưng chỉ được chọn 2 người thi đấu chính thức).
- Ràng buộc: mỗi đội **tối đa 2 tay đua** mỗi chặng (được kiểm tra chặt chẽ bởi Trigger ở DB).
- Nhấn **Sync** để đồng bộ danh sách đăng ký.

### Module 2 — Nhập kết quả (`/results`)
- Chọn chặng đua cần nhập kết quả.
- Nhập thời gian kết thúc, số vòng hoàn thành, trạng thái cho từng tay đua.
- Thanh tiến trình hiển thị tỷ lệ hoàn thành (số tay đua đã có kết quả).
- Validation: `end_time` phải lớn hơn `start_time` của chặng (bắt ở tầng DB Trigger).
- Nhấn **Save All** → hệ thống gọi Stored Procedure tính điểm hạng tự động.

| Trạng thái | Ý nghĩa | Điểm | Rank |
|-----------|---------|------|------|
| Finished  | Hoàn thành chặng | Theo hạng (25→1) | 1, 2, 3... |
| DNF       | Bỏ cuộc (lỗi kỹ thuật)| 0 | `-` (NULL) |
| Accident  | Tai nạn | 0 | `-` (NULL) |

### Module 3 — BXH tay đua (`/driver-standings`)
- Xem bảng xếp hạng toàn mùa giải (nhóm theo Season).
- Hỗ trợ lọc theo từng vòng đấu để xem biến động điểm số lịch sử.
- **Tính năng mở rộng:** Click vào từng tay đua sẽ hiển thị Popup chi tiết (Race History) lịch sử thành tích, trạng thái của họ tại mọi chặng.

### Module 4 — BXH đội đua (`/team-standings`)
- Tương tự Module 3 nhưng điểm tổng của đội = tổng điểm của mọi tay đua thuộc đội đó ở mỗi chặng thi đấu.
- Click vào tên đội bóng để xem lịch sử tích lũy điểm qua từng vòng. 

---

## 🗄️ Cấu trúc Database

```
CHAMPIONSHIPS ──── RACES ──── RACE_ENTRIES ──── RESULTS
                                   │
              DRIVERS ── CONTRACTS ┘
                              │
                           TEAMS
```

| Bảng | Mô tả |
|------|-------|
| `CHAMPIONSHIPS` | Mùa giải F1 |
| `TEAMS` | Đội đua |
| `DRIVERS` | Tay đua |
| `CONTRACTS` | Hợp đồng tay đua ↔ đội (lưu lịch sử) |
| `RACES` | Chặng đua |
| `RACE_ENTRIES` | Đăng ký tay đua vào chặng |
| `RESULTS` | Kết quả thi đấu + điểm F1 |

---

## ⚙️ API Endpoints chính

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| `GET`  | `/api/championships`        | Lấy bảng danh sách mùa giải |
| `GET`  | `/api/teams`                | Lấy danh sách đội đua |
| `GET`  | `/api/teams/:team/drivers`  | Lấy danh sách tay đua của đội hiện tại |
| `GET`  | `/api/races`                | Lấy danh sách chặng đua (có lọc theo champ_code) |
| `GET`  | `/api/.../entries`          | Đọc/lưu đăng ký đua |
| `POST` | `/api/races/results`        | Lưu trữ danh sách kết quả hàng loạt |
| `GET`  | `/api/standings/drivers`    | Bảng xếp hạng tay đua (cho từng vòng / toàn bộ mùa giải) |
| `GET`  | `/api/standings/teams`      | BXH cho đội đua |
| `GET`  | `/api/drivers/:id/results`  | Cung cấp lịch sử chi tiết 1 tay đua (dễ dàng dùng pop-up) |

---

## 🔒 Bảo mật

- Thông tin kết nối Database lưu trong `.env`, **không commit lên Git**
- Toàn bộ truy vấn dùng **Prepared Statements** — chống SQL Injection
- Ràng buộc nghiệp vụ đặt ở tầng Database (Trigger) — không thể bypass từ bên ngoài

---

*Dự án thuộc học phần Hệ Quản Trị Cơ Sở Dữ Liệu — Nhóm 6 — PTIT*
