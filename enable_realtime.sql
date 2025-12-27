-- Force enable Realtime for the table by adding it to the publication
-- This is necessary for the app to receive specific table updates
ALTER PUBLICATION supabase_realtime ADD TABLE custom_notifications;
