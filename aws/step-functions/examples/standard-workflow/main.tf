module "workflow" {
  source = "../.."
  name   = var.name
  definition = jsonencode({
    Comment = "Valida un pedido y lo marca como aceptado"
    StartAt = "Validate"
    States = {
      Validate = {
        Type    = "Choice"
        Choices = [{ Variable = "$.amount", NumericGreaterThan = 0, Next = "Accept" }]
        Default = "Reject"
      }
      Accept = { Type = "Pass", Result = { status = "accepted" }, ResultPath = "$.result", End = true }
      Reject = { Type = "Fail", Error = "InvalidOrder", Cause = "El importe debe ser positivo" }
    }
  })
  tags = var.tags
}

output "state_machine_arn" {
  value = module.workflow.state_machine_arn
}
