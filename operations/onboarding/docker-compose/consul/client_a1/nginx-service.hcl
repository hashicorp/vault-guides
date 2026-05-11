# Copyright IBM Corp. 2017, 2026

service {
  name = "webapp",
  port = 80,
  check {
    http = "http://demo-webapp",
    interval = "5s"
  }
}
