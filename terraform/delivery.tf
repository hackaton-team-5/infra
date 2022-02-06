# resource "helm_release" "argocd" {
#   depends_on = [
#     kubernetes_namespace.delivery
#   ]
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argocd"
#   namespace  = "hackathon-delivery"

#   values = ["../helm_values/argocd.yaml"]
# }