//Load configuration from YAML file
locals {
  alert_config = yamldecode(file("${path.module}/alert_config.yaml"))
}

//browser alerts

# Page Load Time Alert - Warning
resource "newrelic_nrql_alert_condition" "page_load_time_warning" {
  policy_id                      = newrelic_alert_policy.browser_performance_policy.id
  name                           = "Page Load Time - Warning"
  description                    = "Alerts when page load time exceeds 5 seconds"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "static"
  fill_value                     = 0.0
  aggregation_window             = local.alert_config.browser.page_load_time_warning.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.browser.page_load_time_warning.aggregation_delay

  nrql {
    query = "FROM PageView SELECT average(duration)"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.browser.page_load_time_warning.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.browser.page_load_time_warning.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# Page Load Time Alert - Critical (95th percentile)
resource "newrelic_nrql_alert_condition" "page_load_time_95th_critical" {
  policy_id                      = newrelic_alert_policy.browser_performance_policy.id
  name                           = "Page Load Time 95th Percentile - Critical"
  description                    = "Alerts when 95th percentile page load time exceeds 8 seconds"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "static"
  fill_value                     = 0.0
  aggregation_window             = local.alert_config.browser.page_load_time_95th.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.browser.page_load_time_95th.aggregation_delay

  nrql {
    query = "FROM PageView SELECT percentile(duration, 95)"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.browser.page_load_time_95th.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.browser.page_load_time_95th.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}


//api alerts

# 1. Performance Alert - Average Response Time > 1s
resource "newrelic_nrql_alert_condition" "api_performance_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "API Performance Degradation"
  description                    = "Alert when API response time exceeds 1 second"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM Transaction SELECT average(duration) WHERE transactionType = 'Web' AND httpResponseCode LIKE '2%' FACET name"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.api.performance.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.api.performance.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# 2. Error Rate Alert - Error Rate > 5%
resource "newrelic_nrql_alert_condition" "api_error_rate_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "High API Error Rate"
  description                    = "Alert when API error rate exceeds 5%"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM Transaction SELECT percentage(count(*), WHERE error IS TRUE) AS 'Error Rate' WHERE transactionType = 'Web' FACET appName"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.api.error_rate.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.api.error_rate.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# 3. Latency Alert - 95th Percentile Latency > 2s
resource "newrelic_nrql_alert_condition" "api_latency_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "High API Latency"
  description                    = "Alert when 95th percentile API latency exceeds 2 seconds"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM Transaction SELECT percentile(duration, 95) WHERE transactionType = 'Web'"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.api.latency.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.api.latency.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# 4. Uptime Alert - Availability < 99.9%
resource "newrelic_nrql_alert_condition" "api_uptime_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "API Availability Issue"
  description                    = "Alert when API availability drops below 99.9%"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM SyntheticCheck SELECT percentage(count(*), WHERE result = 'SUCCESS') AS 'Uptime' FACET monitorName"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "below"
    threshold             = local.alert_config.api.uptime.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "below"
    threshold             = local.alert_config.api.uptime.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# 5. API Response Time Alert - Avg Response Time > 800ms
resource "newrelic_nrql_alert_condition" "api_response_time_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "Slow API Response Time"
  description                    = "Alert when average API response time exceeds 800ms"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM Transaction SELECT average(duration) WHERE transactionType = 'Web' FACET name"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.api.response_time.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.api.response_time.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# 6. Throttling Alert - Rate > 100 requests per minute
resource "newrelic_nrql_alert_condition" "api_throttling_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "API Throttling Risk"
  description                    = "Alert when API request rate exceeds 100 requests per minute"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM Transaction SELECT rate(count(*), 1 minute) WHERE transactionType = 'Web'"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.api.throttling.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.api.throttling.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# 7. Rate Limiting Alert - 429 Responses > 10 in 5 minutes
resource "newrelic_nrql_alert_condition" "api_rate_limiting_alert" {
  policy_id                      = newrelic_alert_policy.api_alerts.id
  name                           = "API Rate Limiting Detected"
  description                    = "Alert when API returns too many 429 (Too Many Requests) responses"
  type                           = "static"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query             = "FROM Transaction SELECT count(*) WHERE httpResponseCode = '429' AND transactionType = 'Web'"
    evaluation_offset = local.alert_config.api.evaluation_offset
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.api.rate_limiting.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.api.rate_limiting.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

//application monitoring alerts

# 1. Application Availability Alert
resource "newrelic_nrql_alert_condition" "availability_alert" {
  account_id                     = data.newrelic_account.this.id
  policy_id                      = newrelic_alert_policy.application_monitoring_policy.id
  type                           = "static"
  name                           = "Application Availability Alert"
  description                    = "Alerts when application availability drops below threshold"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query = "FROM SyntheticCheck SELECT percentage(count(*), WHERE result = 'SUCCESS') FACET monitorName"
  }
  
  critical {
    operator              = "below"
    threshold             = local.alert_config.application.availability.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
  
  warning {
    operator              = "below"
    threshold             = local.alert_config.application.availability.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# 3. Latency Alert
resource "newrelic_nrql_alert_condition" "latency_alert" {
  account_id                     = data.newrelic_account.this.id
  policy_id                      = newrelic_alert_policy.application_monitoring_policy.id
  type                           = "static"
  name                           = "Application Latency Alert"
  description                    = "Alerts when application response time exceeds threshold"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query = "FROM Transaction SELECT average(duration) FACET appName"
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.application.latency.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.application.latency.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# 4. CPU Usage Alert
resource "newrelic_nrql_alert_condition" "cpu_alert" {
  account_id                     = data.newrelic_account.this.id
  policy_id                      = newrelic_alert_policy.application_monitoring_policy.id
  type                           = "static"
  name                           = "Application Server CPU Usage Alert"
  description                    = "Alerts when server CPU usage exceeds threshold"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query = "FROM Metric SELECT average(host.cpuPercent) FACET entity.name"
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.application.cpu.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.application.cpu.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# 5. Memory Usage Alert
resource "newrelic_nrql_alert_condition" "memory_alert" {
  account_id                     = data.newrelic_account.this.id
  policy_id                      = newrelic_alert_policy.application_monitoring_policy.id
  type                           = "static"
  name                           = "Application Server Memory Usage Alert"
  description                    = "Alerts when server memory usage exceeds threshold"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query = "FROM Metric SELECT average(host.memoryUsedPercent) FACET entity.name"
  }
  
  critical {
    operator              = "above"
    threshold             = local.alert_config.application.memory.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
  
  warning {
    operator              = "above"
    threshold             = local.alert_config.application.memory.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# 6. Response Rate Alert
resource "newrelic_nrql_alert_condition" "response_rate_alert" {
  account_id                     = data.newrelic_account.this.id
  policy_id                      = newrelic_alert_policy.application_monitoring_policy.id
  type                           = "static"
  name                           = "Response Rate Alert"
  description                    = "Alerts when response rate falls below threshold"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query = "FROM Transaction SELECT rate(count(*), 1 minute) FACET appName"
  }
  
  critical {
    operator              = "below"
    threshold             = local.alert_config.application.response_rate.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
  
  warning {
    operator              = "below"
    threshold             = local.alert_config.application.response_rate.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# 7. User Satisfaction Score Alert
resource "newrelic_nrql_alert_condition" "apdex_alert" {
  account_id                     = data.newrelic_account.this.id
  policy_id                      = newrelic_alert_policy.application_monitoring_policy.id
  type                           = "static"
  name                           = "User Satisfaction Score Alert"
  description                    = "Alerts when user satisfaction (fast page loads) falls below threshold"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  
  nrql {
    query = "FROM PageView SELECT percentage(count(*), WHERE duration < 3) AS 'Satisfied'"
  }
  
  critical {
    operator              = "below"
    threshold             = local.alert_config.application.apdex.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
  
  warning {
    operator              = "below"
    threshold             = local.alert_config.application.apdex.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "ALL"
  }
}


// db alerts

# Database Availability Alert
resource "newrelic_nrql_alert_condition" "db_availability_alert" {
  account_id                     = data.newrelic_account.account.id
  policy_id                      = newrelic_alert_policy.database_alert_policy.id
  type                           = "static"
  name                           = "Database Availability"
  description                    = "Alerts when database connection status indicates downtime"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "static"
  fill_value                     = 0
  aggregation_window             = local.alert_config.database.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.database.aggregation_delay

  nrql {
    query = "FROM Metric SELECT latest(provider.dbConnectionStatus) FACET entity.name"
  }

  critical {
    operator              = "below"
    threshold             = local.alert_config.database.availability.critical.threshold
    threshold_duration    = local.alert_config.database.availability.critical.threshold_duration
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "below"
    threshold             = local.alert_config.database.availability.warning.threshold
    threshold_duration    = local.alert_config.database.availability.warning.threshold_duration
    threshold_occurrences = "ALL"
  }
}

# Query Response Time Alert
resource "newrelic_nrql_alert_condition" "query_response_time_alert" {
  account_id                     = data.newrelic_account.account.id
  policy_id                      = newrelic_alert_policy.database_alert_policy.id
  type                           = "static"
  name                           = "Query Response Time"
  description                    = "Alerts when database query duration exceeds thresholds"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "none"
  aggregation_window             = local.alert_config.database.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.database.aggregation_delay

  nrql {
    query = "FROM Metric SELECT average(database.queryDuration) FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.database.query_response_time.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.database.query_response_time.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

# CPU Utilization Alert
resource "newrelic_nrql_alert_condition" "cpu_utilization_alert" {
  account_id                     = data.newrelic_account.account.id
  policy_id                      = newrelic_alert_policy.database_alert_policy.id
  type                           = "static"
  name                           = "Database CPU Utilization"
  description                    = "Alerts when database CPU utilization is too high"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "none"
  aggregation_window             = local.alert_config.database.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.database.aggregation_delay

  nrql {
    query = "FROM Metric SELECT average(host.cpuPercent) WHERE entityType = 'DATABASE' FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.database.cpu.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.database.cpu.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

# Memory Utilization Alert
resource "newrelic_nrql_alert_condition" "memory_utilization_alert" {
  account_id                     = data.newrelic_account.account.id
  policy_id                      = newrelic_alert_policy.database_alert_policy.id
  type                           = "static"
  name                           = "Database Memory Utilization"
  description                    = "Alerts when database memory utilization is too high"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "none"
  aggregation_window             = local.alert_config.database.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.database.aggregation_delay

  nrql {
    query = "FROM Metric SELECT average(host.memoryUsedPercent) WHERE entityType = 'DATABASE' FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.database.memory.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.database.memory.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

# Connection Pool Usage Alert
resource "newrelic_nrql_alert_condition" "connection_pool_alert" {
  account_id                     = data.newrelic_account.account.id
  policy_id                      = newrelic_alert_policy.database_alert_policy.id
  type                           = "static"
  name                           = "Database Connection Pool Usage"
  description                    = "Alerts when database connection pool usage is high"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds
  fill_option                    = "none"
  aggregation_window             = local.alert_config.database.aggregation_window
  aggregation_method             = "event_flow"
  aggregation_delay              = local.alert_config.database.aggregation_delay

  nrql {
    query = "FROM Metric SELECT latest(database.connectionsUsed) / latest(database.connectionsMax) * 100 AS 'Connection Pool Usage %' FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.database.connection_pool.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.database.connection_pool.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}


//infrastructure alerts

# CPU Utilization Alert Condition (Warning at 70%, Critical at 85%)
resource "newrelic_nrql_alert_condition" "cpu_utilization" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "High CPU Utilization"
  description                    = "Alert when CPU utilization is high"
  runbook_url                    = "https://example.com/runbooks/high-cpu"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    query = "FROM Metric SELECT average(host.cpuPercent) FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.cpu.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.cpu.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# Memory Usage Alert Condition (Warning at 75%, Critical at 90%)
resource "newrelic_nrql_alert_condition" "memory_usage" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "High Memory Usage"
  description                    = "Alert when memory usage is high"
  runbook_url                    = "https://example.com/runbooks/high-memory"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    query = "FROM Metric SELECT average(host.memoryUsedPercent) FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.memory.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.memory.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# Network Throughput Alert Condition (Warning at 80% of capacity, Critical at 95%)
resource "newrelic_nrql_alert_condition" "network_throughput" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "High Network Throughput"
  description                    = "Alert when network throughput is high"
  runbook_url                    = "https://example.com/runbooks/high-network-throughput"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    # Assuming a baseline of what's considered high throughput (e.g., 100MB/s)
    # Adjust the thresholds based on your network capacity
    query = "FROM Metric SELECT sum(net.receive.bytesPerSecond) + sum(net.transmit.bytesPerSecond) as 'Total Throughput' FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.network_throughput.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.network_throughput.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# Network Latency Alert Condition (Warning at 150ms, Critical at 300ms)
resource "newrelic_nrql_alert_condition" "network_latency" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "High Network Latency"
  description                    = "Alert when network latency is high"
  runbook_url                    = "https://example.com/runbooks/high-network-latency"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    query = "FROM SyntheticRequest SELECT average(duration) WHERE monitorType IN ('SIMPLE', 'BROWSER')"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.network_latency.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.network_latency.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# Disk I/O Alert Condition (Warning at 70%, Critical at 85% of capacity)
resource "newrelic_nrql_alert_condition" "disk_io" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "High Disk I/O"
  description                    = "Alert when disk I/O is high"
  runbook_url                    = "https://example.com/runbooks/high-disk-io"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    query = "FROM Metric SELECT sum(host.diskReadBytesPerSecond) + sum(host.diskWriteBytesPerSecond) as 'Disk I/O' FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.disk_io.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.disk_io.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# Storage Utilization Alert Condition (Warning at 75%, Critical at 90%)
resource "newrelic_nrql_alert_condition" "storage_utilization" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "High Storage Utilization"
  description                    = "Alert when storage utilization is high"
  runbook_url                    = "https://example.com/runbooks/high-storage"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    query = "FROM Metric SELECT average(host.diskUtilizationPercent) FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.storage.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.storage.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}

# Network Errors Alert Condition (Warning at 10 errors/min, Critical at 30 errors/min)
resource "newrelic_nrql_alert_condition" "network_errors" {
  policy_id                      = newrelic_alert_policy.infrastructure_policy.id
  name                           = "Network Errors Detected"
  description                    = "Alert when network errors are detected"
  runbook_url                    = "https://example.com/runbooks/network-errors"
  enabled                        = true
  violation_time_limit_seconds   = local.alert_config.common.violation_time_limit_seconds

  nrql {
    query = "FROM Metric SELECT sum(net.receive.errors) + sum(net.transmit.errors) as 'Network Errors' FACET entity.name"
  }

  critical {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.network_errors.critical.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.alert_config.infrastructure.network_errors.warning.threshold
    threshold_duration    = local.alert_config.common.threshold_duration
    threshold_occurrences = "all"
  }
}