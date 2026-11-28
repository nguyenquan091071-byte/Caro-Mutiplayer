-- =====================================================================
-- CSDL Caro Multiplayer cho SQLite 3 (bản tương đương file MySQL, 23 bảng, 4 view, 2 trigger)
-- Chạy:  sqlite3 caro.db < caro_schema.sql
-- Bắt buộc bật khóa ngoại cho MỖI kết nối:  PRAGMA foreign_keys = ON;
-- Thời gian lưu dạng UTC (YYYY-MM-DD HH:MM:SS).
-- =====================================================================
PRAGMA foreign_keys = ON;
-- =============== NHÓM 1: CẤU HÌNH VÀ THAM SỐ ===============
CREATE TABLE bac_rank (
  bac TEXT NOT NULL, -- E, D, C, B, A
  diem_toi_thieu INTEGER NOT NULL,
  diem_thang INTEGER NOT NULL,
  diem_thua INTEGER NOT NULL, -- lưu số dương, khi tính thì trừ đi
  PRIMARY KEY (bac),
  CONSTRAINT kt_bac_rank_ma   CHECK (bac IN ('E','D','C','B','A')),
  CONSTRAINT kt_bac_rank_diem CHECK (diem_toi_thieu >= 0 AND diem_thang >= 0 AND diem_thua >= 0)
);


CREATE TABLE cap_do (
  cap_do INTEGER NOT NULL, -- 1 đến 10
  xp_toi_thieu INTEGER NOT NULL, -- mốc điểm kinh nghiệm để đạt cấp
  mo_khoa_dau_giai INTEGER NOT NULL DEFAULT 0, -- 1 = được đấu giải (từ cấp 5)
  PRIMARY KEY (cap_do),
  CONSTRAINT dn_cap_do_1 UNIQUE (xp_toi_thieu),
  CONSTRAINT kt_cap_do_1 CHECK (cap_do BETWEEN 1 AND 10),
  CONSTRAINT kt_cap_do_2 CHECK (xp_toi_thieu >= 0),
  CONSTRAINT kt_cap_do_3 CHECK (mo_khoa_dau_giai IN (0,1))
);


CREATE TABLE cau_hinh_thuong_giai (
  bac TEXT NOT NULL,
  diem_moi_tran_thang INTEGER NOT NULL, -- điểm cộng cho mỗi trận thắng trong giải
  diem_ban_ket INTEGER NOT NULL,
  diem_a_quan INTEGER NOT NULL,
  diem_vo_dich INTEGER NOT NULL, -- 0 khi vô địch được thăng bậc thay cho điểm
  thang_bac_khi_vo_dich INTEGER NOT NULL DEFAULT 0, -- 1 = vô địch thì thăng lên bậc kế tiếp
  PRIMARY KEY (bac),
  CONSTRAINT kn_cau_hinh_thuong_giai_bac FOREIGN KEY (bac) REFERENCES bac_rank (bac),
  CONSTRAINT kt_cau_hinh_thuong_giai_1 CHECK (diem_moi_tran_thang >= 0 AND diem_ban_ket >= 0 AND diem_a_quan >= 0 AND diem_vo_dich >= 0),
  CONSTRAINT kt_cau_hinh_thuong_giai_2 CHECK (thang_bac_khi_vo_dich IN (0,1)),
  CONSTRAINT kt_cau_hinh_thuong_giai_3 CHECK (thang_bac_khi_vo_dich = 0 OR diem_vo_dich = 0)
);


CREATE TABLE cau_hinh_bot (
  ma_bot INTEGER PRIMARY KEY AUTOINCREMENT,
  ten_do_kho TEXT NOT NULL, -- Dễ, Trung bình, Khó
  cap_do_kho INTEGER NOT NULL, -- 1 đến 3
  mo_ta TEXT NULL,
  CONSTRAINT dn_cau_hinh_bot_1 UNIQUE (ten_do_kho),
  CONSTRAINT kt_cau_hinh_bot_1 CHECK (cap_do_kho BETWEEN 1 AND 3)
);


CREATE TABLE tham_so_he_thong (
  ten_tham_so TEXT NOT NULL,
  gia_tri INTEGER NOT NULL,
  don_vi TEXT NOT NULL,
  mo_ta TEXT NULL,
  PRIMARY KEY (ten_tham_so)
);


-- =============== NHÓM 2: NGƯỜI CHƠI, PHIÊN, PHẠT, THÔNG BÁO ===============
CREATE TABLE nguoi_choi (
  ma_nguoi_choi TEXT NOT NULL, -- UUID do máy chủ sinh
  ten_hien_thi TEXT NOT NULL,
  bac_xep_hang TEXT NOT NULL DEFAULT 'E',
  diem_xep_hang INTEGER NOT NULL DEFAULT 0,
  diem_kinh_nghiem INTEGER NOT NULL DEFAULT 0,
  cap_do INTEGER NOT NULL DEFAULT 1, -- tự nâng khi kinh nghiệm tăng, không giảm
  so_tran_thang INTEGER NOT NULL DEFAULT 0,
  so_tran_thua INTEGER NOT NULL DEFAULT 0,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lan_cuoi_hoat_dong TEXT NULL,
  PRIMARY KEY (ma_nguoi_choi),
  CONSTRAINT kn_nguoi_choi_bac_xep_hang FOREIGN KEY (bac_xep_hang) REFERENCES bac_rank (bac),
  CONSTRAINT kn_nguoi_choi_cap_do       FOREIGN KEY (cap_do)       REFERENCES cap_do (cap_do),
  CONSTRAINT kt_nguoi_choi_1 CHECK (length(TRIM(ten_hien_thi)) BETWEEN 1 AND 20),
  CONSTRAINT kt_nguoi_choi_2 CHECK (diem_xep_hang >= 0 AND diem_kinh_nghiem >= 0 AND so_tran_thang >= 0 AND so_tran_thua >= 0)
);
CREATE INDEX cm_nguoi_choi_1 ON nguoi_choi (diem_xep_hang);


CREATE TABLE phien_dang_nhap (
  ma_phien TEXT NOT NULL,
  ma_nguoi_choi TEXT NOT NULL,
  ma_bam_khoa_phien TEXT NOT NULL, -- chỉ lưu bản băm của khóa phiên
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  het_han_luc TEXT NOT NULL,
  PRIMARY KEY (ma_phien),
  CONSTRAINT dn_phien_dang_nhap_1 UNIQUE (ma_bam_khoa_phien),
  CONSTRAINT kn_phien_dang_nhap_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi) ON DELETE CASCADE
);
CREATE INDEX cm_phien_dang_nhap_1 ON phien_dang_nhap (ma_nguoi_choi);


-- =============== NHÓM 3: PHÒNG CHƠI, GHÉP TRẬN, KHÁN GIẢ ===============
CREATE TABLE phong_choi (
  ma_phong TEXT NOT NULL,
  ma_chu_phong TEXT NOT NULL,
  trang_thai TEXT NOT NULL DEFAULT 'cho' CHECK (trang_thai IS NULL OR trang_thai IN ('cho','dang_choi','dong')),
  che_do_thoi_gian TEXT NOT NULL DEFAULT 'tu_do' CHECK (che_do_thoi_gian IS NULL OR che_do_thoi_gian IN ('tu_do','tuy_chinh')),
  thoi_luong_giay INTEGER NULL, -- chỉ có khi tùy chỉnh, tối đa 900 giây
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dong_luc TEXT NULL,
  PRIMARY KEY (ma_phong),
  CONSTRAINT kn_phong_choi_ma_chu_phong FOREIGN KEY (ma_chu_phong) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_phong_choi_1 CHECK (thoi_luong_giay IS NULL OR thoi_luong_giay BETWEEN 1 AND 900),
  CONSTRAINT kt_phong_choi_2 CHECK ((che_do_thoi_gian = 'tuy_chinh') = (thoi_luong_giay IS NOT NULL))
);
CREATE INDEX cm_phong_choi_1 ON phong_choi (ma_chu_phong);


CREATE TABLE phong_choi_thanh_vien (
  ma_phong TEXT NOT NULL,
  ma_nguoi_choi TEXT NOT NULL,
  phe_quan TEXT NULL CHECK (phe_quan IS NULL OR phe_quan IN ('X','O')), -- chọn quân (ván thường)
  da_san_sang INTEGER NOT NULL DEFAULT 0,
  muon_choi_lai INTEGER NOT NULL DEFAULT 0,
  vao_luc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ma_phong, ma_nguoi_choi),
  CONSTRAINT dn_phong_choi_thanh_vien_1 UNIQUE (ma_nguoi_choi), -- một người chỉ ở một phòng
  CONSTRAINT dn_phong_choi_thanh_vien_2 UNIQUE (ma_phong, phe_quan), -- hai người không trùng quân
  CONSTRAINT kn_phong_choi_thanh_vien_ma_phong      FOREIGN KEY (ma_phong)      REFERENCES phong_choi (ma_phong) ON DELETE CASCADE,
  CONSTRAINT kn_phong_choi_thanh_vien_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_phong_choi_thanh_vien_1 CHECK (da_san_sang IN (0,1) AND muon_choi_lai IN (0,1))
);


CREATE TABLE tran_dau (
  ma_tran TEXT NOT NULL,
  ma_xem TEXT NOT NULL, -- mã xem đấu, khác mã phòng
  che_do TEXT NOT NULL CHECK (che_do IS NULL OR che_do IN ('xep_hang','thuong','may','giai')),
  ma_phong TEXT NULL, -- chỉ ván thường có phòng
  ma_bot INTEGER NULL, -- độ khó khi chơi với máy
  nguoi_choi_x TEXT NOT NULL,
  nguoi_choi_o TEXT NULL, -- NULL khi chơi với máy
  bac_x TEXT NULL, -- hạng chốt lúc bắt đầu trận
  bac_o TEXT NULL,
  che_do_thoi_gian TEXT NOT NULL DEFAULT 'nhanh_7_phut' CHECK (che_do_thoi_gian IS NULL OR che_do_thoi_gian IN ('nhanh_7_phut','tu_do','tuy_chinh')),
  thoi_luong_giay INTEGER NULL, -- tối đa 900 giây; NULL = tự do
  thoi_gian_da_dung_x_ms INTEGER NOT NULL DEFAULT 0,
  thoi_gian_da_dung_o_ms INTEGER NOT NULL DEFAULT 0,
  trang_thai TEXT NOT NULL DEFAULT 'dang_choi' CHECK (trang_thai IS NULL OR trang_thai IN ('dang_choi','tam_dung','ket_thuc','da_huy')), -- tam_dung: chờ kết nối lại 60 giây
  ket_qua TEXT NULL CHECK (ket_qua IS NULL OR ket_qua IN ('X_THANG','O_THANG','HOA')),
  ly_do_ket_thuc TEXT NULL CHECK (ly_do_ket_thuc IS NULL OR ly_do_ket_thuc IN ('nam_quan','day_ban','het_gio','so_sanh_thoi_gian','mat_ket_noi','roi_tran','bo_cuoc','da_huy')),
  ma_nguoi_thang TEXT NULL,
  phien_ban INTEGER NOT NULL DEFAULT 0,
  bat_dau_luc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ket_thuc_luc TEXT NULL,
  PRIMARY KEY (ma_tran),
  CONSTRAINT dn_tran_dau_1 UNIQUE (ma_xem),
  CONSTRAINT kn_tran_dau_ma_phong       FOREIGN KEY (ma_phong)       REFERENCES phong_choi (ma_phong),
  CONSTRAINT kn_tran_dau_ma_bot         FOREIGN KEY (ma_bot)         REFERENCES cau_hinh_bot (ma_bot),
  CONSTRAINT kn_tran_dau_nguoi_choi_x   FOREIGN KEY (nguoi_choi_x)   REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_tran_dau_nguoi_choi_o   FOREIGN KEY (nguoi_choi_o)   REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_tran_dau_bac_x          FOREIGN KEY (bac_x)          REFERENCES bac_rank (bac),
  CONSTRAINT kn_tran_dau_bac_o          FOREIGN KEY (bac_o)          REFERENCES bac_rank (bac),
  CONSTRAINT kn_tran_dau_ma_nguoi_thang FOREIGN KEY (ma_nguoi_thang) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_tran_dau_1 CHECK (thoi_luong_giay IS NULL OR thoi_luong_giay BETWEEN 1 AND 900),
  CONSTRAINT kt_tran_dau_2 CHECK (nguoi_choi_o IS NULL OR nguoi_choi_x <> nguoi_choi_o),
  CONSTRAINT kt_tran_dau_3 CHECK ((che_do = 'may') = (nguoi_choi_o IS NULL)),
  CONSTRAINT kt_tran_dau_4 CHECK ((che_do = 'may') = (ma_bot IS NOT NULL)),
  CONSTRAINT kt_tran_dau_5 CHECK (ket_qua IS NULL OR ket_qua <> 'HOA' OR che_do = 'thuong'),
  CONSTRAINT kt_tran_dau_6 CHECK (che_do NOT IN ('xep_hang','giai') OR (che_do_thoi_gian = 'nhanh_7_phut' AND thoi_luong_giay = 420)),
  CONSTRAINT kt_tran_dau_7 CHECK (trang_thai <> 'ket_thuc' OR (ket_qua IS NOT NULL AND ket_thuc_luc IS NOT NULL)),
  CONSTRAINT kt_tran_dau_8 CHECK ((ket_qua IS NULL AND ma_nguoi_thang IS NULL) OR (ket_qua = 'HOA' AND ma_nguoi_thang IS NULL) OR (ket_qua = 'X_THANG' AND ma_nguoi_thang IS nguoi_choi_x) OR (ket_qua = 'O_THANG' AND ma_nguoi_thang IS nguoi_choi_o))
);
CREATE INDEX cm_tran_dau_1 ON tran_dau (nguoi_choi_x);
CREATE INDEX cm_tran_dau_2 ON tran_dau (nguoi_choi_o);
CREATE INDEX cm_tran_dau_3 ON tran_dau (che_do, trang_thai);
CREATE INDEX cm_tran_dau_4 ON tran_dau (ket_thuc_luc);


CREATE TABLE hang_doi_ghep_tran (
  ma_hang_doi INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_nguoi_choi TEXT NOT NULL,
  loai_hang_doi TEXT NOT NULL CHECK (loai_hang_doi IS NULL OR loai_hang_doi IN ('thuong','xep_hang')),
  bac_xep_hang TEXT NULL, -- hạng lúc xếp hàng (bắt buộc với hàng đợi xếp hạng)
  vao_luc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, -- vào trước ra trước
  CONSTRAINT dn_hang_doi_ghep_tran_1 UNIQUE (ma_nguoi_choi), -- mỗi người chỉ xếp hàng một lần
  CONSTRAINT kn_hang_doi_ghep_tran_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi) ON DELETE CASCADE,
  CONSTRAINT kn_hang_doi_ghep_tran_bac_xep_hang  FOREIGN KEY (bac_xep_hang)  REFERENCES bac_rank (bac),
  CONSTRAINT kt_hang_doi_ghep_tran_1 CHECK (loai_hang_doi = 'thuong' OR bac_xep_hang IS NOT NULL)
);
CREATE INDEX cm_hang_doi_ghep_tran_1 ON hang_doi_ghep_tran (loai_hang_doi, bac_xep_hang, vao_luc);


CREATE TABLE khan_gia_xem_dau (
  ma_xem_dau INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_tran TEXT NOT NULL,
  ma_nguoi_choi TEXT NOT NULL,
  vao_luc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT dn_khan_gia_xem_dau_1 UNIQUE (ma_nguoi_choi), -- mỗi người chỉ xem một trận
  CONSTRAINT kn_khan_gia_xem_dau_ma_tran       FOREIGN KEY (ma_tran)       REFERENCES tran_dau (ma_tran) ON DELETE CASCADE,
  CONSTRAINT kn_khan_gia_xem_dau_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi)
);
CREATE INDEX cm_khan_gia_xem_dau_1 ON khan_gia_xem_dau (ma_tran);


-- =============== NHÓM 4: TRẬN ĐẤU, NƯỚC ĐI, TIN NHẮN, NGẮT KẾT NỐI ===============
CREATE TABLE nuoc_di (
  ma_nuoc_di INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_tran TEXT NOT NULL,
  so_thu_tu INTEGER NOT NULL,
  ma_nguoi_choi TEXT NULL, -- NULL = nước đi của máy
  so_dong INTEGER NOT NULL, -- 0 đến 18 (bàn 19x19)
  so_cot INTEGER NOT NULL,
  ma_yeu_cau TEXT NULL,
  thoi_gian_ms INTEGER NULL,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT dn_nuoc_di_1 UNIQUE (ma_tran, so_thu_tu),
  CONSTRAINT dn_nuoc_di_2 UNIQUE (ma_tran, so_dong, so_cot),
  CONSTRAINT dn_nuoc_di_3 UNIQUE (ma_tran, ma_yeu_cau),
  CONSTRAINT kn_nuoc_di_ma_tran       FOREIGN KEY (ma_tran)       REFERENCES tran_dau (ma_tran) ON DELETE CASCADE,
  CONSTRAINT kn_nuoc_di_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_nuoc_di_1 CHECK (so_thu_tu >= 1 AND so_dong <= 18 AND so_cot <= 18)
);


CREATE TABLE tin_nhan (
  ma_tin_nhan INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_tran TEXT NULL, -- rỗng khi nhắn ở phòng chờ
  ma_phong TEXT NULL,
  ma_nguoi_gui TEXT NOT NULL,
  noi_dung TEXT NOT NULL,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT kn_tin_nhan_ma_tran      FOREIGN KEY (ma_tran)      REFERENCES tran_dau (ma_tran),
  CONSTRAINT kn_tin_nhan_ma_phong     FOREIGN KEY (ma_phong)     REFERENCES phong_choi (ma_phong),
  CONSTRAINT kn_tin_nhan_ma_nguoi_gui FOREIGN KEY (ma_nguoi_gui) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_tin_nhan_1 CHECK (ma_tran IS NOT NULL OR ma_phong IS NOT NULL),
  CONSTRAINT kt_tin_nhan_2 CHECK (length(noi_dung) >= 1)
);
CREATE INDEX cm_tin_nhan_1 ON tin_nhan (ma_tran, ngay_tao);
CREATE INDEX cm_tin_nhan_2 ON tin_nhan (ma_phong, ngay_tao);


CREATE TABLE su_kien_ngat_ket_noi (
  ma_su_kien INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_tran TEXT NOT NULL,
  ma_nguoi_choi TEXT NOT NULL,
  mat_ket_noi_luc TEXT NOT NULL,
  han_cho_luc TEXT NOT NULL, -- mất kết nối lúc + 60 giây
  ket_qua TEXT NOT NULL DEFAULT 'dang_cho' CHECK (ket_qua IS NULL OR ket_qua IN ('dang_cho','khoi_phuc','xu_thua')),
  khoi_phuc_luc TEXT NULL,
  CONSTRAINT kn_su_kien_ngat_ket_noi_ma_tran       FOREIGN KEY (ma_tran)       REFERENCES tran_dau (ma_tran),
  CONSTRAINT kn_su_kien_ngat_ket_noi_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_su_kien_ngat_ket_noi_1 CHECK (han_cho_luc >= mat_ket_noi_luc),
  CONSTRAINT kt_su_kien_ngat_ket_noi_2 CHECK (ket_qua <> 'khoi_phuc' OR khoi_phuc_luc IS NOT NULL)
);
CREATE INDEX cm_su_kien_ngat_ket_noi_1 ON su_kien_ngat_ket_noi (ma_tran, ket_qua);


-- =============== NHÓM 2 (tiếp): HÌNH PHẠT, THÔNG BÁO ===============
CREATE TABLE hinh_phat (
  ma_hinh_phat TEXT NOT NULL,
  ma_nguoi_choi TEXT NOT NULL,
  ma_tran TEXT NULL,
  cam_den_luc TEXT NOT NULL, -- cấm xếp hạng đến thời điểm này (30 giây)
  bat_buoc_dau_thuong INTEGER NOT NULL DEFAULT 1, -- bắt buộc chơi 1 trận thường
  go_luc TEXT NULL, -- có giá trị khi đã chơi xong trận thường
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ma_hinh_phat),
  CONSTRAINT kn_hinh_phat_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi) ON DELETE CASCADE,
  CONSTRAINT kn_hinh_phat_ma_tran       FOREIGN KEY (ma_tran)       REFERENCES tran_dau (ma_tran),
  CONSTRAINT kt_hinh_phat_1 CHECK (bat_buoc_dau_thuong IN (0,1))
);
CREATE INDEX cm_hinh_phat_1 ON hinh_phat (ma_nguoi_choi, cam_den_luc);


-- =============== NHÓM 6: GIẢI ĐẤU ===============
CREATE TABLE giai_dau (
  ma_giai_dau TEXT NOT NULL,
  ten_giai TEXT NOT NULL,
  bac_xep_hang TEXT NOT NULL,
  trang_thai TEXT NOT NULL DEFAULT 'dang_ky' CHECK (trang_thai IS NULL OR trang_thai IN ('dang_ky','vong_bang','loai_truc_tiep','ket_thuc')),
  so_nguoi_toi_da INTEGER NOT NULL DEFAULT 8,
  ma_nguoi_vo_dich TEXT NULL,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  bat_dau_luc TEXT NULL,
  ket_thuc_luc TEXT NULL,
  PRIMARY KEY (ma_giai_dau),
  CONSTRAINT kn_giai_dau_bac_xep_hang    FOREIGN KEY (bac_xep_hang)    REFERENCES bac_rank (bac),
  CONSTRAINT kn_giai_dau_ma_nguoi_vo_dich FOREIGN KEY (ma_nguoi_vo_dich) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_giai_dau_1 CHECK (so_nguoi_toi_da = 8),
  CONSTRAINT kt_giai_dau_2 CHECK (length(TRIM(ten_giai)) >= 1)
);
CREATE INDEX cm_giai_dau_1 ON giai_dau (bac_xep_hang, trang_thai);


CREATE TABLE giai_dau_bang (
  ma_bang INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_giai_dau TEXT NOT NULL,
  ten_bang TEXT NOT NULL CHECK (ten_bang IS NULL OR ten_bang IN ('A','B')),
  CONSTRAINT dn_giai_dau_bang_1 UNIQUE (ma_giai_dau, ten_bang),
  CONSTRAINT dn_giai_dau_bang_2 UNIQUE (ma_giai_dau, ma_bang), -- để các bảng con nối khóa ngoại tổ hợp
  CONSTRAINT kn_giai_dau_bang_ma_giai_dau FOREIGN KEY (ma_giai_dau) REFERENCES giai_dau (ma_giai_dau)
);


CREATE TABLE giai_dau_nguoi_choi (
  ma_giai_dau TEXT NOT NULL,
  ma_nguoi_choi TEXT NOT NULL,
  ma_bang INTEGER NULL, -- gán khi giải bắt đầu chia bảng
  diem_bang INTEGER NOT NULL DEFAULT 0, -- thắng 3, thua 0
  so_tran_thang INTEGER NOT NULL DEFAULT 0,
  so_tran_thua INTEGER NOT NULL DEFAULT 0,
  thoi_gian_da_dung_ms INTEGER NOT NULL DEFAULT 0, -- tiêu chí phụ xếp hạng bảng
  hang_trong_bang INTEGER NULL,
  thu_hang_cuoi TEXT NULL CHECK (thu_hang_cuoi IS NULL OR thu_hang_cuoi IN ('vo_dich','a_quan','ban_ket','bi_loai_vong_bang')),
  bo_giai INTEGER NOT NULL DEFAULT 0, -- 1 = bỏ giải (thua các trận còn lại)
  dang_ky_luc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ma_giai_dau, ma_nguoi_choi),
  CONSTRAINT kn_giai_dau_nguoi_choi_ma_giai_dau   FOREIGN KEY (ma_giai_dau)   REFERENCES giai_dau (ma_giai_dau),
  CONSTRAINT kn_giai_dau_nguoi_choi_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_giai_dau_nguoi_choi_ma_bang       FOREIGN KEY (ma_giai_dau, ma_bang) REFERENCES giai_dau_bang (ma_giai_dau, ma_bang),
  CONSTRAINT kt_giai_dau_nguoi_choi_1 CHECK (diem_bang >= 0 AND so_tran_thang >= 0 AND so_tran_thua >= 0),
  CONSTRAINT kt_giai_dau_nguoi_choi_2 CHECK (hang_trong_bang IS NULL OR hang_trong_bang BETWEEN 1 AND 4),
  CONSTRAINT kt_giai_dau_nguoi_choi_3 CHECK (bo_giai IN (0,1))
);
CREATE INDEX cm_giai_dau_nguoi_choi_1 ON giai_dau_nguoi_choi (ma_nguoi_choi);


CREATE TABLE giai_dau_tran (
  ma_tran_giai TEXT NOT NULL,
  ma_giai_dau TEXT NOT NULL,
  vong TEXT NOT NULL CHECK (vong IS NULL OR vong IN ('vong_bang','ban_ket','chung_ket')),
  ma_bang INTEGER NULL, -- chỉ có ở vòng bảng
  so_luot INTEGER NOT NULL DEFAULT 1, -- lượt trong vòng
  ma_nguoi_choi_1 TEXT NOT NULL,
  ma_nguoi_choi_2 TEXT NOT NULL,
  ma_tran TEXT NULL,
  ma_nguoi_thang TEXT NULL,
  ket_qua TEXT NULL CHECK (ket_qua IS NULL OR ket_qua IN ('nguoi_1_thang','nguoi_2_thang','ca_hai_bo_cuoc')), -- ca_hai_bo_cuoc: cả hai quá 60 giây không vào trận
  han_vao_tran TEXT NULL, -- giờ hẹn + 60 giây
  san_sang_1_luc TEXT NULL,
  san_sang_2_luc TEXT NULL,
  trang_thai TEXT NOT NULL DEFAULT 'cho' CHECK (trang_thai IS NULL OR trang_thai IN ('cho','san_sang','dang_choi','xong')),
  PRIMARY KEY (ma_tran_giai),
  CONSTRAINT dn_giai_dau_tran_1 UNIQUE (ma_tran),
  CONSTRAINT kn_giai_dau_tran_ma_giai_dau     FOREIGN KEY (ma_giai_dau)     REFERENCES giai_dau (ma_giai_dau),
  CONSTRAINT kn_giai_dau_tran_ma_bang         FOREIGN KEY (ma_giai_dau, ma_bang) REFERENCES giai_dau_bang (ma_giai_dau, ma_bang),
  CONSTRAINT kn_giai_dau_tran_ma_nguoi_choi_1 FOREIGN KEY (ma_nguoi_choi_1) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_giai_dau_tran_ma_nguoi_choi_2 FOREIGN KEY (ma_nguoi_choi_2) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_giai_dau_tran_ma_tran         FOREIGN KEY (ma_tran)         REFERENCES tran_dau (ma_tran),
  CONSTRAINT kn_giai_dau_tran_ma_nguoi_thang  FOREIGN KEY (ma_nguoi_thang)  REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kt_giai_dau_tran_1 CHECK (ma_nguoi_choi_1 <> ma_nguoi_choi_2),
  CONSTRAINT kt_giai_dau_tran_2 CHECK ((vong = 'vong_bang') = (ma_bang IS NOT NULL)),
  CONSTRAINT kt_giai_dau_tran_3 CHECK (so_luot >= 1),
  CONSTRAINT kt_giai_dau_tran_4 CHECK ((ket_qua IS NULL AND ma_nguoi_thang IS NULL) OR (ket_qua = 'nguoi_1_thang' AND ma_nguoi_thang = ma_nguoi_choi_1) OR (ket_qua = 'nguoi_2_thang' AND ma_nguoi_thang = ma_nguoi_choi_2) OR (ket_qua = 'ca_hai_bo_cuoc' AND ma_nguoi_thang IS NULL))
);
CREATE INDEX cm_giai_dau_tran_1 ON giai_dau_tran (ma_giai_dau, vong);


CREATE TABLE thong_bao (
  ma_thong_bao INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_nguoi_choi TEXT NOT NULL,
  loai TEXT NOT NULL CHECK (loai IS NULL OR loai IN ('goi_vao_tran_giai','bi_phat','len_cap','thang_hang')),
  noi_dung TEXT NOT NULL,
  ma_tran_giai TEXT NULL, -- chỉ có khi gọi vào trận giải
  han_luc TEXT NULL, -- hạn 60 giây để vào trận giải
  da_doc INTEGER NOT NULL DEFAULT 0,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT kn_thong_bao_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi) ON DELETE CASCADE,
  CONSTRAINT kn_thong_bao_ma_tran_giai  FOREIGN KEY (ma_tran_giai)  REFERENCES giai_dau_tran (ma_tran_giai),
  CONSTRAINT kt_thong_bao_1 CHECK (loai <> 'goi_vao_tran_giai' OR (ma_tran_giai IS NOT NULL AND han_luc IS NOT NULL)),
  CONSTRAINT kt_thong_bao_2 CHECK (da_doc IN (0,1))
);
CREATE INDEX cm_thong_bao_1 ON thong_bao (ma_nguoi_choi, da_doc, ngay_tao);


-- =============== NHÓM 5: LỊCH SỬ ĐIỂM VÀ KINH NGHIỆM ===============
CREATE TABLE lich_su_diem_rank (
  ma_thay_doi INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_nguoi_choi TEXT NOT NULL,
  ma_tran TEXT NULL,
  ma_giai_dau TEXT NULL,
  ly_do TEXT NOT NULL CHECK (ly_do IS NULL OR ly_do IN ('thang','thua','thang_do_doi_thu_mat_ket_noi','thua_do_mat_ket_noi','thang_tran_giai','thuong_giai','thang_hang_do_vo_dich')),
  chenh_lech INTEGER NOT NULL,
  diem_truoc INTEGER NOT NULL,
  diem_sau INTEGER NOT NULL,
  bac_truoc TEXT NOT NULL,
  bac_sau TEXT NOT NULL,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Cột sinh tự động: bằng 1 khi dòng là phần thưởng thứ hạng cuối giải, ngược lại NULL
  co_thuong INTEGER GENERATED ALWAYS AS (IIF(ly_do IN ('thuong_giai','thang_hang_do_vo_dich'), 1, NULL)) STORED,
  CONSTRAINT dn_lich_su_diem_rank_1 UNIQUE (ma_tran, ma_nguoi_choi), -- mỗi trận tính điểm một lần
  CONSTRAINT dn_lich_su_diem_rank_2 UNIQUE (ma_giai_dau, ma_nguoi_choi, co_thuong), -- mỗi người 1 phần thưởng thứ hạng mỗi giải
  CONSTRAINT kn_lich_su_diem_rank_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_lich_su_diem_rank_ma_tran       FOREIGN KEY (ma_tran)       REFERENCES tran_dau (ma_tran),
  CONSTRAINT kn_lich_su_diem_rank_ma_giai_dau   FOREIGN KEY (ma_giai_dau)   REFERENCES giai_dau (ma_giai_dau),
  CONSTRAINT kn_lich_su_diem_rank_bac_truoc     FOREIGN KEY (bac_truoc)     REFERENCES bac_rank (bac),
  CONSTRAINT kn_lich_su_diem_rank_bac_sau       FOREIGN KEY (bac_sau)       REFERENCES bac_rank (bac),
  CONSTRAINT kt_lich_su_diem_rank_1 CHECK (diem_truoc >= 0 AND diem_sau >= 0 AND diem_sau = diem_truoc + chenh_lech),
  CONSTRAINT kt_lich_su_diem_rank_2 CHECK ((ly_do IN ('thang','thua','thang_do_doi_thu_mat_ket_noi','thua_do_mat_ket_noi') AND ma_tran IS NOT NULL AND ma_giai_dau IS NULL) OR (ly_do = 'thang_tran_giai' AND ma_tran IS NOT NULL AND ma_giai_dau IS NOT NULL) OR (ly_do IN ('thuong_giai','thang_hang_do_vo_dich') AND ma_giai_dau IS NOT NULL AND ma_tran IS NULL))
);
CREATE INDEX cm_lich_su_diem_rank_1 ON lich_su_diem_rank (ma_nguoi_choi, ngay_tao);


CREATE TABLE lich_su_xp (
  ma_thay_doi INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_nguoi_choi TEXT NOT NULL,
  ma_tran TEXT NOT NULL,
  chenh_lech INTEGER NOT NULL, -- thắng +20, thua +10
  kinh_nghiem_sau INTEGER NOT NULL,
  cap_do_sau INTEGER NOT NULL,
  ngay_tao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT dn_lich_su_xp_1 UNIQUE (ma_tran, ma_nguoi_choi), -- mỗi trận cộng kinh nghiệm một lần
  CONSTRAINT kn_lich_su_xp_ma_nguoi_choi FOREIGN KEY (ma_nguoi_choi) REFERENCES nguoi_choi (ma_nguoi_choi),
  CONSTRAINT kn_lich_su_xp_ma_tran       FOREIGN KEY (ma_tran)       REFERENCES tran_dau (ma_tran),
  CONSTRAINT kn_lich_su_xp_cap_do_sau    FOREIGN KEY (cap_do_sau)    REFERENCES cap_do (cap_do),
  CONSTRAINT kt_lich_su_xp_1 CHECK (chenh_lech IN (10, 20)),
  CONSTRAINT kt_lich_su_xp_2 CHECK (kinh_nghiem_sau >= 0)
);
CREATE INDEX cm_lich_su_xp_1 ON lich_su_xp (ma_nguoi_choi, ngay_tao);


-- =============== DỮ LIỆU CẤU HÌNH MẶC ĐỊNH ===============
INSERT INTO bac_rank (bac, diem_toi_thieu, diem_thang, diem_thua) VALUES
  ('E',    0,  5,  0),
  ('D',  250, 10,  5),
  ('C',  500, 15,  7),
  ('B',  750, 20, 10),
  ('A', 1000, 30, 15);

INSERT INTO cap_do (cap_do, xp_toi_thieu, mo_khoa_dau_giai) VALUES
  (1, 0, 0), (2, 100, 0), (3, 200, 0), (4, 300, 0), (5, 400, 1),
  (6, 500, 1), (7, 600, 1), (8, 700, 1), (9, 800, 1), (10, 900, 1);

INSERT INTO cau_hinh_thuong_giai (bac, diem_moi_tran_thang, diem_ban_ket, diem_a_quan, diem_vo_dich, thang_bac_khi_vo_dich) VALUES
  ('E',  5, 10,  20,   0, 1),
  ('D', 10, 20,  40,   0, 1),
  ('C', 15, 30,  60,   0, 1),
  ('B', 20, 40,  80,   0, 1),
  ('A', 30, 60, 120, 240, 0);

INSERT INTO cau_hinh_bot (ten_do_kho, cap_do_kho, mo_ta) VALUES
  ('Dễ', 1, 'Đánh ngẫu nhiên gần các quân đã có'),
  ('Trung bình', 2, 'Chấm điểm ô theo mẫu quân, biết chặn hai đầu'),
  ('Khó', 3, 'Chấm điểm sâu hơn, ưu tiên tạo thế đôi');

INSERT INTO tham_so_he_thong (ten_tham_so, gia_tri, don_vi, mo_ta) VALUES
  ('thoi_gian_cho_nuoc_di_ms', 2500, 'ms', 'Hai nước đi liên tiếp của một người cách nhau tối thiểu'),
  ('thoi_gian_cho_tro_chuyen_giay', 5, 'giay', 'Mỗi người gửi tối đa 1 tin mỗi khoảng này'),
  ('thoi_gian_cho_mat_ket_noi_giay', 60, 'giay', 'Thời gian chờ kết nối lại trước khi xử thua'),
  ('thoi_gian_cam_xep_hang_giay', 30, 'giay', 'Cấm đấu xếp hạng sau khi cố tình rời phòng'),
  ('gioi_han_van_moi_cap_24h', 3, 'van', 'Số ván xếp hạng và kinh nghiệm tối đa mỗi cặp trong 24 giờ'),
  ('so_nguoi_toi_da_giai', 8, 'nguoi', 'Số người của một giải đấu'),
  ('thoi_gian_vao_tran_giai_giay', 60, 'giay', 'Hạn bấm Vào trận khi đến lượt thi đấu giải'),
  ('thoi_luong_xep_hang_giay', 420, 'giay', 'Ván xếp hạng và ván giải: 7 phút'),
  ('thoi_luong_tuy_chinh_toi_da_giay', 900, 'giay', 'Ván thường tùy chỉnh tối đa 15 phút'),
  ('xp_thang', 20, 'xp', 'Kinh nghiệm cộng khi thắng người thật'),
  ('xp_thua', 10, 'xp', 'Kinh nghiệm cộng khi thua người thật'),
  ('thang_do_doi_thu_mat_ket_noi_phan_tram', 50, '%', 'Bên thắng chỉ nhận phần trăm điểm thắng'),
  ('thua_do_mat_ket_noi_phan_tram', 100, '%', 'Bên thua bị trừ phần trăm điểm thua');

-- =============== VIEW ===============
CREATE VIEW v_bang_xep_hang AS
SELECT RANK() OVER (ORDER BY diem_xep_hang DESC) AS thu_hang,
       ma_nguoi_choi, ten_hien_thi, cap_do, bac_xep_hang, diem_xep_hang, so_tran_thang, so_tran_thua
FROM nguoi_choi;

CREATE VIEW v_cap_dau_rank_24h AS
SELECT MIN(nguoi_choi_x, nguoi_choi_o) AS nguoi_choi_a,
       MAX(nguoi_choi_x, nguoi_choi_o) AS nguoi_choi_b,
       COUNT(*)                        AS so_van_24h,
       MIN(ket_thuc_luc)               AS van_cu_nhat_luc
FROM tran_dau
WHERE che_do = 'xep_hang' AND trang_thai = 'ket_thuc'
  AND ket_thuc_luc >= datetime('now', '-24 hours')
GROUP BY MIN(nguoi_choi_x, nguoi_choi_o), MAX(nguoi_choi_x, nguoi_choi_o);

CREATE VIEW v_bi_cam_rank AS
SELECT ma_nguoi_choi,
       MAX(cam_den_luc) AS cam_den_luc,
       MAX(CASE WHEN bat_buoc_dau_thuong = 1 AND go_luc IS NULL THEN 1 ELSE 0 END) AS phai_dau_thuong
FROM hinh_phat
GROUP BY ma_nguoi_choi;

CREATE VIEW v_phong_dang_dau AS
SELECT t.ma_xem,
       t.che_do,
       (t.che_do = 'may')       AS la_van_may,
       b.ten_do_kho,
       px.ten_hien_thi          AS ten_nguoi_choi_x,
       po.ten_hien_thi          AS ten_nguoi_choi_o,
       t.bac_x, t.bac_o,
       t.trang_thai,
       t.bat_dau_luc,
       (SELECT COUNT(*) FROM khan_gia_xem_dau k WHERE k.ma_tran = t.ma_tran) AS so_khan_gia
FROM tran_dau t
JOIN nguoi_choi px ON px.ma_nguoi_choi = t.nguoi_choi_x
LEFT JOIN nguoi_choi po ON po.ma_nguoi_choi = t.nguoi_choi_o
LEFT JOIN cau_hinh_bot b ON b.ma_bot = t.ma_bot
WHERE t.trang_thai IN ('dang_choi','tam_dung');

-- =============== TRIGGER ===============
-- Tự nâng cấp độ khi kinh nghiệm tăng; cấp độ không bao giờ giảm
CREATE TRIGGER trg_cap_nhat_cap_do_xp
AFTER UPDATE OF diem_kinh_nghiem ON nguoi_choi
FOR EACH ROW
BEGIN
  UPDATE nguoi_choi
     SET cap_do = MAX(OLD.cap_do, IFNULL((SELECT MAX(c.cap_do) FROM cap_do c WHERE c.xp_toi_thieu <= NEW.diem_kinh_nghiem), 1))
   WHERE ma_nguoi_choi = NEW.ma_nguoi_choi;
END;

-- Điều kiện đăng ký giải (N06.1)
CREATE TRIGGER trg_dang_ky_giai
BEFORE INSERT ON giai_dau_nguoi_choi
BEGIN
  SELECT RAISE(ABORT, 'Chua du cap do de dau giai (can cap 5 tro len)')
   WHERE (SELECT cap_do FROM nguoi_choi WHERE ma_nguoi_choi = NEW.ma_nguoi_choi)
       < (SELECT MIN(cap_do) FROM cap_do WHERE mo_khoa_dau_giai = 1);
  SELECT RAISE(ABORT, 'Khac bac rank cua giai')
   WHERE (SELECT bac_xep_hang FROM nguoi_choi WHERE ma_nguoi_choi = NEW.ma_nguoi_choi)
      <> (SELECT bac_xep_hang FROM giai_dau WHERE ma_giai_dau = NEW.ma_giai_dau);
  SELECT RAISE(ABORT, 'Dang bi cam dau xep hang')
   WHERE EXISTS (SELECT 1 FROM hinh_phat WHERE ma_nguoi_choi = NEW.ma_nguoi_choi AND cam_den_luc > datetime('now'));
  SELECT RAISE(ABORT, 'Giai da dong dang ky')
   WHERE (SELECT trang_thai FROM giai_dau WHERE ma_giai_dau = NEW.ma_giai_dau) <> 'dang_ky';
  SELECT RAISE(ABORT, 'Giai da du nguoi')
   WHERE (SELECT COUNT(*) FROM giai_dau_nguoi_choi WHERE ma_giai_dau = NEW.ma_giai_dau)
      >= (SELECT so_nguoi_toi_da FROM giai_dau WHERE ma_giai_dau = NEW.ma_giai_dau);
END;
