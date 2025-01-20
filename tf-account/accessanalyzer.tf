resource "aws_accessanalyzer_analyzer" "analyzer" {
  analyzer_name = "${var.customer}-${var.env_aws_profile}-${var.aws_region}-analyzer"
}

resource "null_resource" "add_accessanalyzer_archieve_rules" {
  provisioner "local-exec" {
    command = "sh ../scripts/bin/create_archive_rules.sh ${var.customer}-${var.env_aws_profile}-${var.aws_region}-analyzer ${var.env_aws_profile} ${var.sst_account_id} ${var.master_account_id} ${var.dd_account_id}"
  }
}

