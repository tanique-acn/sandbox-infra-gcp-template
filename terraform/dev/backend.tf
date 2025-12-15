# Example backend configuration for GCS (environment-specific prefix)
#
# Note: backend configuration cannot reference variables. The workflows use -backend-config parameters
# to pass bucket and prefix at init time. Example local usage:
#
# terraform init -backend-config="bucket=MY_BUCKET" -backend-config="prefix=terraform/state/dev"
#
# Example static backend block (not recommended to commit with real names):
#
terraform {
  backend "gcs" {
    bucket = "sandbox-dev-480919-tf-state-5d0ea63e"
    prefix = "terraform/state"
  }
}
#
# In CI workflows we pass:
# -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
# -backend-config="prefix=${{ secrets.TF_STATE_PREFIX }}/${{ env }}" 