locals {
  # Every resource name in the estate is prefixed. Two environments in one
  # account that both want a bucket called "cumulus-documents" is the failure
  # this prevents.
  name_prefix = "${var.namespacePrefix}cumulus"
}
