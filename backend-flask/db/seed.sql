-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Andrew Brown','andrewbrown@exampro.co' , 'andrewbrown' ,'401a3fa1-0bd7-4d77-bf4c-d8fde2521edb'),
  ('Andrew Bayko','bayko@exampro.co' , 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )