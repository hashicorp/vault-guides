service {
  name = "haproxy",
  port = 80,
  check {
    http = "http://demo-haproxy",
    interval = "5s"
  }
}
