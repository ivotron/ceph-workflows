workflow "test action" {
  on = "push"
  resolves = "build"
}

action "build" {
  uses = "./cbt"
  runs = ["ls"]
}
