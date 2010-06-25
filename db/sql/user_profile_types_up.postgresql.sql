CREATE TABLE user_profile_types (
  id          serial PRIMARY KEY,
  name        varchar(50) NOT NULL UNIQUE CHECK(length(name) > 1),
  data_type   varchar(100) NOT NULL CHECK(data_type IN ('text_field', 'text_area', 'hidden', 'checkbox')),
  visible     boolean NOT NULL DEFAULT true,
  editable    boolean NOT NULL DEFAULT true,
  required    boolean NOT NULL DEFAULT false
);