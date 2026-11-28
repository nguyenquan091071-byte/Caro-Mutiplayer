# Caro Multiplayer

Website chơi cờ Caro trực tuyến cho hai người theo mô hình máy khách – máy chủ (đồ án lập trình mạng).
Bàn cờ 19 × 19, 5 quân liên tiếp thắng. Có chơi với máy, đấu thường, đấu xếp hạng (hạng E–A), cấp độ 1–10, giải đấu 8 người, xem đấu và trò chuyện.

> Trạng thái: đang ở giai đoạn thiết kế. Thư mục `docs/` và `database/` đã hoàn thiện; mã nguồn `server/` và `client/` sẽ bổ sung.

## Công nghệ dự kiến

- Máy chủ: Node.js, Express, Socket.IO
- Giao diện: HTML, CSS, JavaScript
- Cơ sở dữ liệu: MySQL 8.0.16 trở lên (có bản SQLite để thử nhanh)

## Cấu trúc thư mục

```
caro-multiplayer/
├── README.md
├── .gitignore
├── .env.example            Mẫu cấu hình (sao chép thành .env)
├── docs/
│   ├── index.html          Trang mục lục các tài liệu
│   ├── CaroMultiplayer_TongQuan_V4.docx   Tài liệu tổng quan
│   ├── so-do/              Sơ đồ chức năng, sơ đồ khối, luồng dữ liệu
│   └── co-so-du-lieu/      Schema, ERD, workflow, bảng tính
├── database/
│   ├── mysql/caro_schema_mysql.sql   Tạo CSDL cho MySQL Workbench
│   └── sqlite/caro_schema.sql        Bản SQLite tương đương
├── server/                 Mã nguồn máy chủ (sẽ bổ sung)
└── client/                 Mã nguồn giao diện (sẽ bổ sung)
```

## Tạo cơ sở dữ liệu (MySQL)

1. Mở MySQL Workbench và kết nối vào máy chủ MySQL.
2. Chọn File > Open SQL Script, mở `database/mysql/caro_schema_mysql.sql`.
3. Bấm biểu tượng tia sét (Execute). Script tạo database `caro_multiplayer` gồm 23 bảng, 4 view, 2 trigger và nạp sẵn dữ liệu cấu hình.

## Chạy dự án (sẽ cập nhật khi có mã nguồn)

```
cp .env.example .env     (điền thông tin kết nối MySQL)
npm install
npm start
```

## Tài liệu

Mở `docs/index.html` để xem toàn bộ sơ đồ và lược đồ. Nếu bật GitHub Pages cho thư mục `docs`, các trang này xem được trực tiếp trên web.
