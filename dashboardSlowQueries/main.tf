terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  for_each = toset(var.db_name)
  dashboard_name = "${each.key}_SlowQuery"
  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 24,
          "y" : 0,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '/aws/rds/instance/${each.key}/slowquery' | #fields  @message\n parse  @message \"# Time: * User@Host: * Id: * Query_time: * Lock_time: * Rows_sent: * Rows_examined: * timestamp=*;*\" \n as Time, User, Id, Query_time,Lock_time,Rows_sent,Rows_examined,timestamp,query\n | sort Time asc\n \n",
            "region" : "${var.region}",
            "title" : "Slow queries with detailed info",
            "view" : "table"
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 6,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '/aws/rds/instance/${each.key}/slowquery' | parse  @message \"# Time: * User@Host: * Id: * Query_time: * Lock_time: * Rows_sent: * Rows_examined: * timestamp=*;*\" \nas Time, User, Id, Query_time,Lock_time,Rows_sent,Rows_examined,timestamp,Query \n| display Time, Query_time, Query\n| sort Query_time desc\n \n\n",
            "region" : "${var.region}",
            "title" : "Top Slow Queries sorted by Query Time",
            "view" : "table"
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 18,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "ConnectionAttempts", "DBInstanceIdentifier", "${each.key}", { "visible" : false }],
              [".", "RowLockTime", ".", "."],
              [".", "DMLLatency", ".", "."],
              [".", "InsertLatency", ".", "."],
              [".", "InsertThroughput", ".", ".", { "visible" : false }],
              [".", "Deadlocks", ".", "."]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "period" : 60,
            "stat" : "Average"
          }
        },
        {
          "height" : 9,
          "width" : 24,
          "y" : 24,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "ConnectionAttempts", "DBInstanceIdentifier", "${each.key}", { "visible" : false }],
              [".", "DatabaseConnections", ".", ".", { "stat" : "Maximum" }],
              [".", "AbortedClients", ".", ".", { "visible" : false }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "period" : 60,
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 33,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${each.key}"]
            ],
            "region" : "${var.region}",
            "title" : "DB CPUUtilization",
            "period" : 60
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 39,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "DMLThroughput", "DBInstanceIdentifier", "${each.key}"],
              [".", "DeleteThroughput", ".", "."],
              [".", "InsertThroughput", ".", "."],
              [".", "UpdateThroughput", ".", "."],
              [".", "SelectThroughput", ".", "."],
              [".", "CommitThroughput", ".", "."]
            ],
            "region" : "${var.region}",
            "title" : "DB workLoad - CommitThroughput, DMLThroughput, DeleteThroughput, InsertThroughput, SelectThroughput, UpdateThroughput"
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 12,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '/aws/rds/instance/${each.key}/error' | fields @message\n| sort @timestamp desc\n| limit 200",
            "region" : "${var.region}",
            "title" : "Top 200 lines of Error Log",
            "view" : "table"
          }
        }
      ]
  })
}
