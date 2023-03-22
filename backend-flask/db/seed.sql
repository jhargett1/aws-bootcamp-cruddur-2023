-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Josh Hargett','joshhargett.jh@gmail.com' , 'joshhargett' ,'MOCK'),
  ('Andrew Brown','andrewbrown@exampro.co','andrewbrown','MOCK'),
  ('Andrew Bayko','bayko@exampro.co','bayko','MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'joshhargett' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )