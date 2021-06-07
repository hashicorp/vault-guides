server = false
data_dir = "/consul/data"
encrypt = "YZqGRaEajsh8M1w4e1z/Jg=="
datacenter = "dc1"
client_addr = "0.0.0.0"
log_level = "INFO"
retry_join = ["consul_s1"]
ui = true
enable_script_checks = true
bootstrap_expect = 0

performance {
    raft_multiplier = 1
}

telemetry {
    prometheus_retention_time = "30s",
    disable_hostname = true    
}

### Old configuration
#acl_enforce_version_8 = false