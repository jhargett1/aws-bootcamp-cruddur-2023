-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Josh Hargett','joshhargett.jh@gmail.com' , 'scubasteve' ,'MOCK'),
  ('Kim Hargett','kim.hargett@yahoo.com' , 'khargett' ,'MOCK'),
  ('Londo Mollari','lmollario@centari.com','londo','MOCK'),
  ('Andrew Bayko','bayko@exampro.co','bayko','MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'scubasteve' LIMIT 1),
    'I love my wife!',
    current_timestamp
  ),
  (
    (SELECT uuid from public.users WHERE users.handle = 'scubasteve' LIMIT 1),
    'I love my wife!',
    current_timestamp + interval '12 HOURS'
  ),
  (
    (SELECT uuid from public.users WHERE users.handle = 'khargett' LIMIT 1),
    'I am the wife!',    
    current_timestamp + interval '1 day'
  );