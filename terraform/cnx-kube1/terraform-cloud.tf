terraform {
  cloud {
    organization = "zephyrproject-rtos"
    workspaces {
      name = "cnx-kube1"
    }
  }
}
