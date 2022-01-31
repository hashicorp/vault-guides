locals {
  vault_data_volume_name = "vault"
  vault_data_mount = {
    sourceVolume  = local.vault_data_volume_name
    containerPath = "/config"
    readOnly      = true
  }
  vault_data_mount_read_write = merge(
    local.vault_data_mount,
    { readOnly = false },
  )

  vault_address = [{
    name  = "VAULT_ADDR"
    value = var.vault_address
  }]
  vault_connection = var.vault_namespace == null ? local.vault_address : concat(local.vault_address, [{
    name  = "VAULT_NAMESPACE"
    value = var.vault_namespace
  }])

  service_name = var.name != "" ? var.name : var.family

  container_defs_with_depends_on = [for def in var.container_definitions :
    merge(
      def,
      {
        dependsOn = flatten(
          concat(
            lookup(def, "dependsOn", []),
            [
              {
                containerName = "vault-agent"
                condition     = var.vault_agent_exit_after_auth ? "SUCCESS" : "HEALTHY"
              }
            ]
        ))
      },
      {
        mountPoints = flatten(
          concat(
            lookup(def, "mountPoints", []),
            [local.vault_data_mount],
          )
        )
      }
    )
  ]
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.family
  requires_compatibilities = var.requires_compatibilities
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role.arn
  task_role_arn            = var.task_role.arn

  volume {
    name = local.vault_data_volume_name

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        iam             = "ENABLED"
        access_point_id = var.efs_access_point_id
      }
    }
  }

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value["name"]
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = contains(keys(volume.value), "docker_volume_configuration") ? [
          volume.value["docker_volume_configuration"]
        ] : []
        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = contains(keys(volume.value), "efs_volume_configuration") ? [
          volume.value["efs_volume_configuration"]
        ] : []
        content {
          file_system_id          = efs_volume_configuration.value["file_system_id"]
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          dynamic "authorization_config" {
            for_each = contains(keys(efs_volume_configuration.value), "authorization_config") ? [
              efs_volume_configuration.value["authorization_config"]
            ] : []
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }

      dynamic "fsx_windows_file_server_volume_configuration" {
        for_each = contains(keys(volume.value), "fsx_windows_file_server_volume_configuration") ? [
          volume.value["fsx_windows_file_server_volume_configuration"]
        ] : []

        content {
          // All fields required.
          file_system_id = fsx_windows_file_server_volume_configuration.value["file_system_id"]
          root_directory = fsx_windows_file_server_volume_configuration.value["root_directory"]
          dynamic "authorization_config" {
            for_each = contains(keys(fsx_windows_file_server_volume_configuration.value), "authorization_config") ? [
              fsx_windows_file_server_volume_configuration.value["authorization_config"]
            ] : []
            content {
              // All fields required.
              credentials_parameter = authorization_config.value["credentials_parameter"]
              domain                = authorization_config.value["domain"]
            }
          }
        }
      }
    }
  }

  tags = local.tags

  container_definitions = jsonencode(
    flatten(
      concat(
        local.container_defs_with_depends_on,
        [
          {
            name             = "vault-agent"
            image            = var.vault_ecs_image
            essential        = false
            logConfiguration = var.log_configuration
            mountPoints = [
              local.vault_data_mount_read_write
            ]
            cpu         = 0
            volumesFrom = [],
            healthCheck = {
              "command" : [
                "CMD-SHELL",
                "vault agent --help"
              ],
              "interval" : 5,
              "timeout" : 2,
              "retries" : 3
            },
            environment = concat(local.vault_connection, [
              {
                name  = "VAULT_ROLE"
                value = var.task_role.id
              },
              {
                name  = "TARGET_FILE_NAME"
                value = var.vault_agent_template_file_name
              },
              {
                name  = "VAULT_AGENT_TEMPLATE"
                value = var.vault_agent_template
              },
              {
                name  = "VAULT_AGENT_EXIT_AFTER_AUTH"
                value = tostring(var.vault_agent_exit_after_auth)
              }
            ])
          }
        ]
      )
    )
  )
}