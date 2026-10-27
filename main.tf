terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6.0"
    }
  }
}

# Configure the Docker provider to connect to your local Docker daemon
provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

# Pull the NGINX image
resource "docker_image" "nginx_img" {
  name         = "nginx:latest"
  keep_locally = false
}

# Create and start the NGINX container
resource "docker_container" "nginx_container" {
  image = docker_image.nginx_img.image_id
  name  = "${var.environment}-web-server"

  ports {
    internal = 80
    external = 8000
  }
}