provider "google" {
credentials = "$(file("reto4-385020-e79a74a0964b.json")}"
project = "reto4"
region = "us-central1"
zone = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
name = "reto4-network"
}
resource "google_compute_autoscaler" "foobar" {
name = "reto4-autoscaler"
project = "reto4"
zone = "us-central1-c"
target = google_compute_instance_group_manager.foobar.self_link

autoscaling_policy {
max_replicas = 5
min_replicas = 2
cooldown_period = 60

cpu_utilization {
target = 0.5
}
}
}

resource "google_compute_instance_template" "foobar" {
name = "reto4-instance-template"
machine_type = "n1-standard-1"
can_ip_forward = false
project = "reto4"
tags = ["foo", "bar", "allow-lb-service"]

disk {
source_image = data.google_compute_image.centos_7.self_link
}

network_interface {
network = google_compute_network.vpc_network.name
}

metadata = {
foo = "bar"
}

service_account {
scopes = ["userinfo-email", "compute-ro", "storage-ro"]
}
}

resource "google_compute_target_pool" "foobar" {
name = "reto4-target-pool"
project = "reto4"
region = "us-central1"
}

resource "google_compute_instance_group_manager" "foobar" {
name = "reto4-igm"
zone = "us-central1-c"
project = "reto4"
version {
instance_template = google_compute_instance_template.foobar.self_link
name = "primary"
}

target_pools = [google_compute_target_pool.foobar.self_link]
base_instance_name = "terraform"
}

data "google_compute_image" "bitnami/moodle" {
name = "bitnami/moodle"
project = "centos-cloud"
}

module "lb" {
source = "GoogleCloudPlatform/lb/google"
version = "2.2.0"
region = "us-central1"
name = "load-balancer"
service_port = 80
target_tags = ["my-target-pool"]
network = google_compute_network.vpc_network.name
}
