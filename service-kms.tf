# ──────────────────────────────────────────────
# KMS service account
# ──────────────────────────────────────────────
resource "yandex_kms_symmetric_key_iam_binding" "bucket_key_encrypter" {
  symmetric_key_id = yandex_kms_symmetric_key.bucket_key.id
  role = "kms.keys.encrypterDecrypter"

    members = [
        "serviceAccount:${var.service_account_id}"
    ]
}