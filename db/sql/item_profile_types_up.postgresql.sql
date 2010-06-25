-- same mechanism as user_profile_types & user_profiles. Again, in retrospect, it's clear that these tables could've been named better
CREATE TABLE item_profile_types (
  id          serial PRIMARY KEY,
  name        varchar(50) UNIQUE NOT NULL CHECK(length(name) > 1),
  data_type   varchar(50) NOT NULL CHECK(data_type IN ('text_field', 'text_area', 'hidden', 'checkbox')),
  visible     boolean NOT NULL DEFAULT true,
  editable    boolean NOT NULL DEFAULT true,
  required    boolean NOT NULL DEFAULT false
);