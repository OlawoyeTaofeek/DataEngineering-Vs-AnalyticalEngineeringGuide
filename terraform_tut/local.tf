resource "local_file" "pet" {
  filename = "C:/Users/user/Desktop/snowflake_lesson/pets.txt"
  content  = "I love my pet"
  file_permission = "0700"
}