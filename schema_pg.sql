-- Lenzio schema for PostgreSQL (Supabase)
-- 5 main entities: camera, lens, users, recipe, review
-- 2 junction tables: camera_lens (Camera M:N Lens), favorite (Users M:N Camera)

DROP TABLE IF EXISTS favorite;
DROP TABLE IF EXISTS camera_lens;
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS recipe;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS lens;
DROP TABLE IF EXISTS camera;

CREATE TABLE camera (
  camera_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  model_name    VARCHAR(100) NOT NULL UNIQUE,
  brand         VARCHAR(30)  NOT NULL,
  sensor_format VARCHAR(30),
  megapixels    DECIMAL(4,1),
  video_spec    VARCHAR(30),
  iso_min       INT,
  iso_max       INT,
  mount         VARCHAR(20),
  release_year  INT,
  price_thb     DECIMAL(10,2),
  image_url     VARCHAR(255),
  CONSTRAINT chk_camera_brand CHECK (brand IN ('Sony','Fujifilm','Canon','Nikon','Panasonic'))
);

CREATE TABLE lens (
  lens_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  lens_name     VARCHAR(100) NOT NULL UNIQUE,
  brand         VARCHAR(30)  NOT NULL,
  mount         VARCHAR(20)  NOT NULL,
  focal_min_mm  INT,
  focal_max_mm  INT,
  max_aperture  DECIMAL(3,1),
  weight_g      INT,
  release_year  INT,
  price_thb     DECIMAL(10,2),
  image_url     VARCHAR(255),
  CONSTRAINT chk_lens_brand CHECK (brand IN ('Sony','Fujifilm','Canon','Nikon','Panasonic'))
);

CREATE TABLE users (
  user_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  display_name  VARCHAR(100) NOT NULL,
  avatar_url    VARCHAR(255)
);

CREATE TABLE recipe (
  recipe_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title           VARCHAR(100) NOT NULL,
  category        VARCHAR(30)  NOT NULL,
  camera_id       INT NOT NULL,
  lens_id         INT NOT NULL,
  aperture        VARCHAR(10),
  shutter_speed   VARCHAR(10),
  iso             INT,
  description     TEXT,
  cover_image_url VARCHAR(255),
  CONSTRAINT fk_recipe_camera FOREIGN KEY (camera_id) REFERENCES camera(camera_id),
  CONSTRAINT fk_recipe_lens   FOREIGN KEY (lens_id)   REFERENCES lens(lens_id),
  CONSTRAINT chk_recipe_category CHECK (category IN ('ภาพบุคคล','วิวทิวทัศน์','อาหาร','กลางคืน'))
);

CREATE TABLE review (
  review_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     INT NOT NULL,
  camera_id   INT NULL,
  lens_id     INT NULL,
  recipe_id   INT NULL,
  rating      INT NOT NULL,
  comment     TEXT,
  like_count  INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_review_user   FOREIGN KEY (user_id)   REFERENCES users(user_id),
  CONSTRAINT fk_review_camera FOREIGN KEY (camera_id) REFERENCES camera(camera_id),
  CONSTRAINT fk_review_lens   FOREIGN KEY (lens_id)   REFERENCES lens(lens_id),
  CONSTRAINT fk_review_recipe FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id),
  CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
  -- a review targets exactly one of camera / lens / recipe
  CONSTRAINT chk_review_one_target CHECK (num_nonnulls(camera_id, lens_id, recipe_id) = 1)
);

CREATE TABLE camera_lens (
  camera_id INT NOT NULL,
  lens_id   INT NOT NULL,
  PRIMARY KEY (camera_id, lens_id),
  CONSTRAINT fk_cl_camera FOREIGN KEY (camera_id) REFERENCES camera(camera_id),
  CONSTRAINT fk_cl_lens   FOREIGN KEY (lens_id)   REFERENCES lens(lens_id)
);

CREATE TABLE favorite (
  user_id   INT NOT NULL,
  camera_id INT NOT NULL,
  PRIMARY KEY (user_id, camera_id),
  CONSTRAINT fk_fav_user   FOREIGN KEY (user_id)   REFERENCES users(user_id),
  CONSTRAINT fk_fav_camera FOREIGN KEY (camera_id) REFERENCES camera(camera_id)
);
