output "load_balancer_ip" {
  value = "${data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip}"
}